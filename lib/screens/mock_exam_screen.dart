import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../models/exam.dart';
import '../models/question.dart';
import '../widgets/constants_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockExamScreen extends StatefulWidget {
  final Exam exam;

  const MockExamScreen({
    super.key,
    required this.exam,
  });

  @override
  State<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends State<MockExamScreen> {
  late PageController _pageController;
  late List<Question> questions;
  late Timer _timer;
  late Duration _remainingTime;
  bool _isExamComplete = false;
  bool _isCountdownVisible = true;
  bool _isLastFiveMinutes = false;
  final List<int> _timeWarnings = [30, 15, 5]; // Minutes at which to show warnings
  final Set<int> _shownWarnings = {}; // Track which warnings have been shown

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    questions = widget.exam.questions;
    _remainingTime = widget.exam.duration;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
          
          // Check for time warnings
          final currentMinutes = _remainingTime.inMinutes;
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

  void _showFiveMinuteWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('⚠️ 5 minutes remaining!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submitExam() {
    _timer.cancel();
    setState(() {
      _isExamComplete = true;
    });
    _saveExamHistory();
  }

  Future<void> _saveExamHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Calculate score
      int correctAnswers = 0;
      for (var i = 0; i < questions.length; i++) {
        if (questions[i].selectedOptionIndex == questions[i].correctOptionIndex) {
          correctAnswers++;
        }
      }

      final scorePercentage = (correctAnswers / questions.length) * 100;

      // Create exam history entry
      final examHistory = {
        'exam_id': widget.exam.id,
        'subject': widget.exam.subject,
        'title': widget.exam.title,
        'total_questions': questions.length,
        'correct_answers': correctAnswers,
        'score_percentage': scorePercentage,
        'taken_at': DateTime.now().toIso8601String(),
      };

      // Get existing histories
      List<String> histories = prefs.getStringList('exam_histories') ?? [];
      
      // Add new history
      histories.add(jsonEncode(examHistory));
      
      // Save back to storage
      await prefs.setStringList('exam_histories', histories);
    } catch (e) {
      print('Error saving exam history: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isExamComplete) {
      return _buildResultsScreen();
    }

    return WillPopScope(
      onWillPop: () async {
        bool shouldPop = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Exam?'),
            content: const Text('Are you sure you want to exit? Your progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return shouldPop;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.exam.title),
          actions: [
            IconButton(
              icon: Icon(_isCountdownVisible ? Icons.timer : Icons.timer_off),
              onPressed: _isLastFiveMinutes ? null : () {
                setState(() {
                  _isCountdownVisible = !_isCountdownVisible;
                });
              },
              tooltip: _isLastFiveMinutes 
                ? 'Timer cannot be hidden in last 5 minutes' 
                : (_isCountdownVisible ? 'Hide timer' : 'Show timer'),
            ),
            if (_isCountdownVisible) Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_remainingTime.inHours.toString().padLeft(2, '0')}:${(_remainingTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _isLastFiveMinutes ? Colors.red : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Question ${_pageController.hasClients ? (_pageController.page?.toInt() ?? 0) + 1 : 1} of ${questions.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showQuestionOverview(),
                    icon: const Icon(Icons.grid_view),
                    label: const Text('Question Overview'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionCard(questions[index], index);
                },
              ),
            ),
            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${index + 1} of ${questions.length}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(
            question.options.length,
            (optionIndex) => _buildOptionCard(
              question,
              optionIndex,
              question.options[optionIndex],
            ),
          ),
          const SizedBox(height: 16),
          ConstantsSection(constants: widget.exam.constants),
        ],
      ),
    );
  }

  Widget _buildOptionCard(Question question, int optionIndex, String optionText) {
    bool isSelected = question.selectedOptionIndex == optionIndex;

    return Card(
      color: isSelected ? Colors.blue.shade100 : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          String.fromCharCode(65 + optionIndex),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        title: Text(optionText),
        onTap: () {
          setState(() {
            question.selectedOptionIndex = optionIndex;
            question.isAnswered = true;
          });
        },
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Text('Previous'),
          ),
          ElevatedButton(
            onPressed: _submitExam,
            child: const Text('Submit Exam'),
          ),
          TextButton(
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _showQuestionOverview() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Question Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  Color backgroundColor = Colors.grey.shade200;
                  if (question.isAnswered) {
                    backgroundColor = Colors.green.shade100;
                  }
                  if (question.isMarkedForReview) {
                    backgroundColor = Colors.orange.shade100;
                  }

                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Colors.grey.shade200, 'Not Answered'),
                _buildLegendItem(Colors.green.shade100, 'Answered'),
                _buildLegendItem(Colors.orange.shade100, 'Marked for Review'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildResultsScreen() {
    final totalQuestions = questions.length;
    final answeredQuestions = questions.where((q) => q.selectedOptionIndex != null).length;
    final correctAnswers = questions.where((q) => 
      q.selectedOptionIndex != null && q.selectedOptionIndex == q.correctOptionIndex
    ).length;
    final score = (correctAnswers / totalQuestions) * 100;

    // Define score-based styling
    final (color, icon, message) = score >= 90 
        ? (Colors.green.shade400, Icons.emoji_events, 'Excellent! Outstanding Performance!')
        : score >= 80 
          ? (Colors.lightGreen.shade400, Icons.star, 'Great Job! Keep it up!')
          : score >= 70 
            ? (Colors.amber.shade400, Icons.thumb_up, 'Good Work! Room for improvement.')
            : score >= 60 
              ? (Colors.orange.shade400, Icons.trending_up, 'Fair. Keep practicing!')
              : (Colors.red.shade400, Icons.refresh, 'Need more practice. Don\'t give up!');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results'),
        automaticallyImplyLeading: false,
        backgroundColor: color.withOpacity(0.2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Score Circle
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(
                  color: color,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${score.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Stats Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: color.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildResultsStat('Total Questions', totalQuestions),
                    const Divider(),
                    _buildResultsStat('Questions Attempted', answeredQuestions),
                    const Divider(),
                    _buildResultsStat('Correct Answers', correctAnswers, color: Colors.green),
                    const Divider(),
                    _buildResultsStat(
                      'Incorrect Answers', 
                      answeredQuestions - correctAnswers,
                      color: Colors.red,
                    ),
                    const Divider(),
                    _buildResultsStat(
                      'Questions Skipped', 
                      totalQuestions - answeredQuestions,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Review Button
            if (score < 100) AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showReviewDialog,
                icon: const Icon(Icons.rate_review),
                label: const Text('Review My Answers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Return Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Return to Study Hub'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsStat(String label, int value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review Options'),
        content: const Text('Would you like to review all questions or just the ones you got wrong?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showReviewScreen(reviewWrongOnly: true);
            },
            child: const Text('Wrong Questions Only'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showReviewScreen(reviewWrongOnly: false);
            },
            child: const Text('All Questions'),
          ),
        ],
      ),
    );
  }

  void _showReviewScreen({required bool reviewWrongOnly}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ExamReviewScreen(
          questions: reviewWrongOnly 
              ? questions.where((q) => 
                  q.selectedOptionIndex != q.correctOptionIndex || 
                  q.selectedOptionIndex == null).toList()
              : questions,
        ),
      ),
    );
  }
}

class _ExamReviewScreen extends StatelessWidget {
  final List<Question> questions;

  const _ExamReviewScreen({
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer Review'),
      ),
      body: ListView.builder(
        itemCount: questions.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final question = questions[index];
          final isCorrect = question.selectedOptionIndex == question.correctOptionIndex;
          final wasAnswered = question.selectedOptionIndex != null;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(question.text),
                  const SizedBox(height: 16),
                  if (wasAnswered) ...[
                    Text(
                      'Your Answer: ${question.options[question.selectedOptionIndex!]}',
                      style: TextStyle(
                        color: isCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isCorrect) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Correct Answer: ${question.options[question.correctOptionIndex]}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ] else
                    const Text(
                      'Question Skipped',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (question.explanation != null && question.explanation!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Explanation:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(question.explanation!),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
