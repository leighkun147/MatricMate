import 'package:flutter/material.dart';
import 'dart:async';
import '../models/exam.dart';
import '../models/question.dart';

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
        } else {
          _submitExam();
        }
      });
    });
  }

  void _submitExam() {
    _timer.cancel();
    setState(() {
      _isExamComplete = true;
    });
    _showResults();
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
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${_remainingTime.inHours.toString().padLeft(2, '0')}:${(_remainingTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
    int totalQuestions = questions.length;
    int answeredQuestions = questions.where((q) => q.isAnswered).length;
    int correctAnswers = questions.where((q) => q.isCorrect).length;
    double percentage = (correctAnswers / totalQuestions) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      'Overall Score',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildResultsStat('Total Questions', totalQuestions),
            _buildResultsStat('Questions Attempted', answeredQuestions),
            _buildResultsStat('Correct Answers', correctAnswers),
            _buildResultsStat('Incorrect Answers', answeredQuestions - correctAnswers),
            _buildResultsStat('Questions Skipped', totalQuestions - answeredQuestions),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Return to Study Hub'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsStat(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showResults() {
    // Here you would typically save the results to local storage
    // and sync with Firebase when online
  }
}
