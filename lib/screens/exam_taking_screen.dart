import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../models/olympiad_exam.dart';
import '../models/exam_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExamTakingScreen extends StatefulWidget {
  final File examFile;

  const ExamTakingScreen({
    super.key,
    required this.examFile,
  });

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen> {
  late OlympiadExam _exam;
  late PageController _pageController;
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  List<int?> _userAnswers = [];
  List<Question> _questions = [];
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _showConstants = false;
  bool _isExamComplete = false;
  bool _isCountdownVisible = true;
  bool _isLastFiveMinutes = false;
  final List<int> _timeWarnings = [30, 15, 5]; // Minutes at which to show warnings
  final Set<int> _shownWarnings = {}; // Track which warnings have been shown

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadExam();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadExam() async {
    try {
      final jsonString = await widget.examFile.readAsString();
      setState(() {
        _exam = OlympiadExam.fromFile(jsonString);
        _userAnswers = List.filled(_exam.numberOfQuestions, null);
        _remainingSeconds = _exam.duration * 60;
        _questions = _exam.questions;
        for (var question in _questions) {
          question.isMarkedForReview = false;
        };
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading exam: $e')),
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          
          // Check for time warnings
          final currentMinutes = _remainingSeconds ~/ 60;
          for (final warningMinute in _timeWarnings) {
            if (currentMinutes == warningMinute && !_shownWarnings.contains(warningMinute)) {
              _showTimeWarning(warningMinute);
              _shownWarnings.add(warningMinute);
              
              // Special handling for 5-minute warning
              if (warningMinute == 5) {
                _isLastFiveMinutes = true;
                _isCountdownVisible = true;
              }
            }
          }
        } else {
          _submitExam();
        }
      });
    });
  }

  void _showTimeWarning(int minutes) {
    final message = minutes == 5 
        ? '⚠️ 5 minutes remaining!'
        : '⏰ $minutes minutes remaining!';
    
    final backgroundColor = minutes == 5 
        ? Colors.orange
        : Colors.blue;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submitExam() {
    _timer?.cancel();
    setState(() {
      _isExamComplete = true;
    });
    _saveExamHistory();
  }

  Future<void> _saveExamHistory() async {
    try {
      if (mounted) {
        _showResultDialog(_calculateScore());
      }
    } catch (e) {
      print('Error saving exam history: $e');
    }
  }

  void _showQuestionOverview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Question Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProgressStat(
                          icon: Icons.check_circle,
                          color: Colors.green[700]!,
                          label: 'Answered',
                          value: _userAnswers.where((a) => a != null).length,
                        ),
                        _buildProgressStat(
                          icon: Icons.flag,
                          color: Colors.orange[700]!,
                          label: 'Marked',
                          value: _questions.where((q) => q.isMarkedForReview).length,
                        ),
                        _buildProgressStat(
                          icon: Icons.remove_circle,
                          color: Colors.grey[700]!,
                          label: 'Unanswered',
                          value: _userAnswers.where((a) => a == null).length,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _exam.numberOfQuestions,
                  itemBuilder: (context, index) {
                    final isAnswered = _userAnswers[index] != null;
                    final isCurrentQuestion = _currentQuestionIndex == index;
                    
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentQuestionIndex = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isCurrentQuestion
                                ? Colors.blue
                                : (_questions[index].isMarkedForReview
                                    ? Colors.orange
                                    : (isAnswered
                                        ? Colors.green[700]!
                                        : Colors.grey[300]!)),
                            width: isCurrentQuestion ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isCurrentQuestion
                              ? Colors.blue.withOpacity(0.1)
                              : (_questions[index].isMarkedForReview
                                  ? Colors.orange.withOpacity(0.1)
                                  : (isAnswered
                                      ? Colors.green[50]
                                      : Colors.white)),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrentQuestion
                                  ? Colors.blue[700]
                                  : (isAnswered
                                      ? Colors.green[700]
                                      : Colors.grey[700]),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStat({
    required IconData icon,
    required Color color,
    required String label,
    required int value,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  int _calculateScore() {
    int correctAnswers = 0;
    for (int i = 0; i < _exam.questions.length; i++) {
      if (_userAnswers[i] == _exam.questions[i].correctOptionIndex) {
        correctAnswers++;
      }
    }
    return correctAnswers;
  }

  void _showResultDialog(int score) {
    final percentage = (score / _exam.numberOfQuestions * 100);
    final attempted = _userAnswers.where((a) => a != null).length;
    final skipped = _exam.numberOfQuestions - attempted;
    final incorrect = attempted - score;

    String performanceMessage;
    Color performanceColor;

    if (percentage >= 90) {
      performanceMessage = 'Excellent! Outstanding performance! 🌟';
      performanceColor = Colors.green[700]!;
    } else if (percentage >= 75) {
      performanceMessage = 'Great job! Very good performance! 👏';
      performanceColor = Colors.green;
    } else if (percentage >= 60) {
      performanceMessage = 'Good effort! Keep practicing! 💪';
      performanceColor = Colors.orange;
    } else {
      performanceMessage = 'Keep practicing! You can do better! 📚';
      performanceColor = Colors.red;
    }

    // Create exam result
    final examResult = ExamResult(
      examId: widget.examFile.path.split('/').last,
      title: _exam.title,
      totalQuestions: _exam.numberOfQuestions,
      correctAnswers: score,
      scorePercentage: percentage,
      takenAt: DateTime.now(),
      userAnswers: Map.fromIterables(
        List.generate(_userAnswers.length, (i) => i.toString()),
        _userAnswers.map((a) => (a ?? -1).toString()).toList(),
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: performanceColor,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('Exam Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              performanceMessage,
              style: TextStyle(
                color: performanceColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            _buildResultStat('Total Questions', _exam.numberOfQuestions),
            _buildResultStat('Questions Attempted', attempted),
            _buildResultStat('Correct Answers', score, color: Colors.green),
            _buildResultStat('Incorrect Answers', incorrect, color: Colors.red),
            _buildResultStat('Questions Skipped', skipped, color: Colors.orange),
            const Divider(),
            _buildResultStat(
              'Final Score',
              '${percentage.toStringAsFixed(1)}%',
              color: performanceColor,
              isBold: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(examResult); // Return to previous screen with result
            },
            child: const Text('Exit'),
          ),
          ElevatedButton(
            onPressed: () => _showReviewOptions(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Review Answers'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStat(String label, dynamic value, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: color ?? Colors.black,
              fontWeight: isBold ? FontWeight.bold : null,
              fontSize: isBold ? 18 : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('Review All Questions'),
              subtitle: const Text('See all questions with your answers'),
              onTap: () {
                Navigator.pop(context);
                _showAnswerReview(reviewWrongOnly: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Review Wrong Answers'),
              subtitle: const Text('Focus on questions you got wrong'),
              onTap: () {
                Navigator.pop(context);
                _showAnswerReview(reviewWrongOnly: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAnswerReview({bool reviewWrongOnly = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          reviewWrongOnly ? 'Wrong Answers Only' : 'Review All Questions',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _exam.questions.length,
                  itemBuilder: (context, index) {
                    final question = _exam.questions[index];
                    final userAnswer = _userAnswers[index];
                    final isCorrect = userAnswer == question.correctOptionIndex;

                    if (reviewWrongOnly && (isCorrect || userAnswer == null)) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Question ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (userAnswer != null)
                                  Icon(
                                    isCorrect ? Icons.check_circle : Icons.cancel,
                                    color: isCorrect ? Colors.green : Colors.red,
                                  )
                                else
                                  const Icon(
                                    Icons.remove_circle,
                                    color: Colors.grey,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(question.text),
                            const SizedBox(height: 16),
                            ...question.options.asMap().entries.map((entry) {
                              final isSelected = userAnswer == entry.key;
                              final isCorrectOption = question.correctOptionIndex == entry.key;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2))
                                      : (isCorrectOption ? Colors.green.withOpacity(0.1) : null),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isCorrect ? Colors.green : Colors.red)
                                        : (isCorrectOption ? Colors.green : Colors.grey),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (isSelected)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Icon(
                                          Icons.check,
                                          size: 16,
                                          color: isCorrect ? Colors.green : Colors.red,
                                        ),
                                      )
                                    else if (isCorrectOption && !isCorrect && userAnswer != null)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                    Expanded(child: Text(entry.value)),
                                  ],
                                ),
                              );
                            }),
                            if (question.explanation.isNotEmpty) ...[                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb_outline,
                                          color: Colors.blue,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Explanation',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      question.explanation,
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = _exam.questions[_currentQuestionIndex];

    return WillPopScope(
      onWillPop: () async {
        if (_isExamComplete) return true;
        
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Exam?'),
            content: const Text('Are you sure you want to exit? Your progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ?? false;

        return shouldExit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_exam.title),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.maybePop(context),
          ),
          actions: [
            if (_isCountdownVisible || _isLastFiveMinutes)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _remainingSeconds < 300 ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.timer),
              onPressed: () => setState(() => _isCountdownVisible = !_isCountdownVisible),
              tooltip: 'Toggle Timer',
            ),
            IconButton(
              icon: const Icon(Icons.grid_view),
              onPressed: _showQuestionOverview,
              tooltip: 'Question Overview',
            ),
            IconButton(
              icon: Icon(_showConstants ? Icons.close : Icons.info_outline),
              onPressed: () => setState(() => _showConstants = !_showConstants),
              tooltip: 'Show/Hide Constants',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Container(
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / _exam.numberOfQuestions,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _exam.numberOfQuestions,
                    onPageChanged: (index) {
                      setState(() {
                        _currentQuestionIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Question ${index + 1} of ${_exam.numberOfQuestions}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                IconButton(
                                  icon: Icon(
                                    question.isMarkedForReview ? Icons.flag : Icons.flag_outlined,
                                    color: question.isMarkedForReview ? Colors.orange : Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      question.isMarkedForReview = !question.isMarkedForReview;
                                    });
                                  },
                                  tooltip: 'Mark for Review',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question.text,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ...question.options.asMap().entries.map((entry) {
                                    final isSelected = _userAnswers[index] == entry.key;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      width: double.infinity,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _userAnswers[index] = entry.key;
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.blue.withOpacity(0.1)
                                                  : Colors.grey[50],
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.blue
                                                    : Colors.grey[300]!,
                                                width: isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? Colors.blue
                                                          : Colors.grey[400]!,
                                                      width: 2,
                                                    ),
                                                    color: isSelected
                                                        ? Colors.blue
                                                        : Colors.transparent,
                                                  ),
                                                  child: isSelected
                                                      ? const Icon(
                                                          Icons.check,
                                                          size: 16,
                                                          color: Colors.white,
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    entry.value,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: isSelected
                                                          ? Colors.blue[700]
                                                          : Colors.black87,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 0,
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentQuestionIndex > 0)
                        TextButton.icon(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_back_ios, size: 18),
                          label: const Text('Previous'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        )
                      else
                        const SizedBox(width: 100),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentQuestionIndex + 1}/${_exam.numberOfQuestions}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (_currentQuestionIndex < _exam.numberOfQuestions - 1)
                        TextButton.icon(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          label: const Text('Next'),
                          icon: const Icon(Icons.arrow_forward_ios, size: 18),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                title: Row(
                                  children: const [
                                    Icon(Icons.warning_rounded, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Submit Exam?'),
                                  ],
                                ),
                                content: Text(
                                  'You have answered ${_userAnswers.where((a) => a != null).length} '
                                  'out of ${_exam.numberOfQuestions} questions.\n\n'
                                  'Are you sure you want to submit?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _submitExam();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Submit'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Submit Exam'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showConstants)
              Positioned(
                right: 16,
                top: 16,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.functions,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Constants Reference',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() => _showConstants = false),
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                          const Divider(),
                          if (_exam.constants.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No constants available for this exam.',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            )
                          else
                            ..._exam.constants.entries.map((entry) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: const Text(
                                      '=',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      entry.value.toString(),
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          const SizedBox(height: 8),
                          const Divider(),
                          Text(
                            'These constants can be used in your calculations.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
