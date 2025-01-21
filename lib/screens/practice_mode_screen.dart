import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../models/question.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/coin_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/constants_section.dart';

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
  final TextEditingController _reportController = TextEditingController();
  bool _isLoading = true;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    questions = widget.exam.questions;
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reportController.dispose();
    _saveProgress();
    super.dispose();
  }

  String get _progressKey => 'exam_progress_${widget.exam.id}';

  Future<void> _loadProgress() async {
    try {
      final String? savedData = _prefs.getString(_progressKey);
      
      if (savedData != null) {
        final data = json.decode(savedData) as Map<String, dynamic>;
        final savedAnswers = List<Map<String, dynamic>>.from(data['answers']);
        final lastQuestionIndex = data['lastQuestionIndex'] as int;

        if (savedAnswers.isNotEmpty) {
          if (mounted) {
            final shouldResume = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Resume Progress?'),
                content: Text(
                  'You have a saved progress in this practice session. Would you like to resume from where you left off?',
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      // Clear saved progress if starting over
                      await _prefs.remove(_progressKey);
                      
                      // Reset all questions to initial state
                      setState(() {
                        for (var question in questions) {
                          question.selectedOptionIndex = -1;
                          question.isAnswered = false;
                        }
                        // Reset page controller to start
                        _pageController = PageController(initialPage: 0);
                      });
                      
                      if (mounted) {
                        Navigator.pop(context, false);
                      }
                    },
                    child: const Text('Start Over'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Resume'),
                  ),
                ],
              ),
            );

            if (shouldResume == true) {
              // Restore progress
              for (int i = 0; i < savedAnswers.length; i++) {
                final answer = savedAnswers[i];
                if (i < questions.length) {
                  questions[i].selectedOptionIndex = answer['selectedOption'];
                  questions[i].isAnswered = answer['isAnswered'];
                }
              }
              setState(() {
                _pageController = PageController(initialPage: lastQuestionIndex);
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading progress: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProgress() async {
    try {
      final currentIndex = _pageController.hasClients 
          ? _pageController.page?.toInt() ?? 0 
          : 0;

      // Only save if there's actual progress
      if (questions.every((q) => !q.isAnswered) && currentIndex == 0) {
        return;
      }

      // Prepare answers data
      final answers = questions.map((q) => {
        'selectedOption': q.selectedOptionIndex,
        'isAnswered': q.isAnswered,
      }).toList();

      final progressData = {
        'lastQuestionIndex': currentIndex,
        'answers': answers,
        'totalQuestions': questions.length,
        'answeredQuestions': questions.where((q) => q.isAnswered).length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await _prefs.setString(_progressKey, json.encode(progressData));
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  // Save progress periodically
  Future<void> _onPageChanged(int index) async {
    await _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
              onPageChanged: _onPageChanged,
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
          const SizedBox(height: 16),
          ConstantsSection(constants: widget.exam.constants),
          const SizedBox(height: 16),
          _buildReportButton(question, index),
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
            : () async {
                setState(() {
                  question.selectedOptionIndex = optionIndex;
                  question.isAnswered = true;
                });

                // If answer is correct, increment coins
                if (optionIndex == question.correctOptionIndex) {
                  try {
                    // Add coins
                    await CoinService.addCoins(2);
                    
                    // Record the transaction
                    await CoinService.recordTransaction(
                      amount: 2,
                      type: 'earned',
                      description: 'Correct answer in practice mode',
                    );
                    
                    // Show success message at the top
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.stars, color: Colors.amber[700]),
                                const SizedBox(width: 8),
                                const Text('+ 2 coins earned!'),
                              ],
                            ),
                            duration: const Duration(milliseconds: 500),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green[700],
                            margin: EdgeInsets.only(
                              bottom: MediaQuery.of(context).size.height - 100,
                              left: 16,
                              right: 16,
                            ),
                          ),
                        );
                    }
                  } catch (e) {
                    print('Error managing coins: $e');
                  }
                }
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

  Widget _buildReportButton(Question question, int index) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showReportDialog(question, index),
        icon: const Icon(Icons.flag_outlined),
        label: const Text('Report a Problem'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey[700],
        ),
      ),
    );
  }

  Future<void> _showReportDialog(Question question, int index) async {
    _reportController.clear();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Problem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reportController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the problem with this question...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_reportController.text.trim().isEmpty) return;

              try {
                await FirebaseFirestore.instance
                    .collection('question_reports')
                    .add({
                  'userId': currentUser.uid,
                  'examId': widget.exam.id,
                  'questionIndex': index,
                  'questionText': question.text,
                  'report': _reportController.text.trim(),
                  'timestamp': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you for your feedback!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to submit report. Please try again.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                print('Error submitting report: $e');
              }
            },
            child: const Text('Submit'),
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
