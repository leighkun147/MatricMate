import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam_history.dart';

class ExamHistoryScreen extends StatefulWidget {
  const ExamHistoryScreen({super.key});

  @override
  State<ExamHistoryScreen> createState() => _ExamHistoryScreenState();
}

class _ExamHistoryScreenState extends State<ExamHistoryScreen> {
  List<ExamHistory> _examHistories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExamHistories();
  }

  Future<void> _loadExamHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final histories = prefs.getStringList('exam_histories') ?? [];

      setState(() {
        _examHistories = histories.map((history) {
          final map = json.decode(history) as Map<String, dynamic>;
          return ExamHistory(
            examId: map['exam_id'],
            subject: map['subject'],
            title: map['title'],
            totalQuestions: map['total_questions'],
            correctAnswers: map['correct_answers'],
            scorePercentage: map['score_percentage'],
            takenAt: DateTime.parse(map['taken_at']),
          );
        }).toList();

        // Sort by date, newest first
        _examHistories.sort((a, b) => b.takenAt.compareTo(a.takenAt));
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading exam histories: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Exam History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _examHistories.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_edu,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No exam history yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Take a mock exam to see your progress here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _examHistories.length,
                  itemBuilder: (context, index) {
                    final history = _examHistories[index];
                    final wrongAnswers =
                        history.totalQuestions - history.correctAnswers;
                    final scoreColor = history.scorePercentage >= 80
                        ? Colors.green
                        : history.scorePercentage >= 60
                            ? Colors.orange
                            : Colors.red;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        history.title,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        history.subject,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scoreColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${history.scorePercentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: scoreColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatChip(
                                  Icons.check_circle_outline,
                                  '${history.correctAnswers} Correct',
                                  Colors.green,
                                ),
                                _buildStatChip(
                                  Icons.cancel_outlined,
                                  '$wrongAnswers Wrong',
                                  Colors.red,
                                ),
                                _buildStatChip(
                                  Icons.question_answer_outlined,
                                  '${history.totalQuestions} Total',
                                  Colors.blue,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Taken on ${DateFormat('MMM d, y • h:mm a').format(history.takenAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}
