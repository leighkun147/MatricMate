import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../models/question.dart';

class PracticeModeScreen extends StatefulWidget {
  final Exam exam;

  const PracticeModeScreen({
    super.key,
    required this.exam,
  });

  @override
  State<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends State<PracticeModeScreen> {
  late PageController _pageController;
  late List<Question> questions;
  bool isExplanationVisible = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    questions = widget.exam.questions;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (questions.where((q) => q.isAnswered).length) / questions.length,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: questions.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _buildQuestionCard(questions[index], index);
              },
            ),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${index + 1} of ${questions.length}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
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
          if (question.isAnswered) ...[
            const SizedBox(height: 16),
            _buildExplanationSection(question),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionCard(Question question, int optionIndex, String optionText) {
    bool isSelected = question.selectedOptionIndex == optionIndex;
    bool showResult = question.isAnswered;
    bool isCorrect = optionIndex == question.correctOptionIndex;

    Color? backgroundColor;
    if (showResult) {
      if (isCorrect) {
        backgroundColor = Colors.green.shade100;
      } else if (isSelected) {
        backgroundColor = Colors.red.shade100;
      }
    } else if (isSelected) {
      backgroundColor = Colors.blue.shade100;
    }

    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          String.fromCharCode(65 + optionIndex),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        title: Text(optionText),
        trailing: showResult && isCorrect
            ? const Icon(Icons.check_circle, color: Colors.green)
            : (showResult && isSelected
                ? const Icon(Icons.close, color: Colors.red)
                : null),
        onTap: question.isAnswered
            ? null
            : () {
                setState(() {
                  question.selectedOptionIndex = optionIndex;
                  question.isAnswered = true;
                });
              },
      ),
    );
  }

  Widget _buildExplanationSection(Question question) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                isExplanationVisible = !isExplanationVisible;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isExplanationVisible
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.blue,
                  ),
                  const Text(
                    'Explanation',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExplanationVisible)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(question.explanation),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    int currentIndex = _pageController.hasClients ? _pageController.page?.toInt() ?? 0 : 0;
    bool isFirstQuestion = currentIndex == 0;
    bool isLastQuestion = currentIndex == questions.length - 1;

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
          if (!isFirstQuestion)
            ElevatedButton.icon(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
            )
          else
            const SizedBox(width: 100),
          if (!isLastQuestion)
            ElevatedButton.icon(
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Finish'),
            ),
        ],
      ),
    );
  }
}
