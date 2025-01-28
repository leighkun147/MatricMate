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
  bool _hasShownTip = false;
  // Store the last deleted item and its position for undo
  ExamHistory? _lastDeletedHistory;
  String? _lastDeletedHistoryJson;
  int? _lastDeletedIndex;

  @override
  void initState() {
    super.initState();
    _loadExamHistories();
    _checkIfTipShown();
  }

  Future<void> _checkIfTipShown() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShownTip = prefs.getBool('delete_tip_shown') ?? false;
    if (!_hasShownTip && mounted) {
      // Wait for the UI to build
      Future.delayed(const Duration(seconds: 1), () {
        _showDeleteTip();
      });
    }
  }

  void _showDeleteTip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('delete_tip_shown', true);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tip: Tap the delete icon or swipe left to delete an exam history'),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  Future<void> _deleteExamHistory(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final histories = prefs.getStringList('exam_histories') ?? [];
    
    // Store the deleted history for undo
    _lastDeletedHistoryJson = histories[index];
    _lastDeletedHistory = _examHistories[index];
    _lastDeletedIndex = index;
    
    // Remove the history at the specified index
    histories.removeAt(index);
    
    // Save the updated list back to SharedPreferences
    await prefs.setStringList('exam_histories', histories);
    
    // Update the state
    setState(() {
      _examHistories.removeAt(index);
    });

    if (!mounted) return;
    
    // Show a snackbar confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Exam history deleted'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: _undoDelete,
        ),
      ),
    );
  }

  Future<void> _undoDelete() async {
    if (_lastDeletedHistory == null || 
        _lastDeletedHistoryJson == null || 
        _lastDeletedIndex == null) return;

    final prefs = await SharedPreferences.getInstance();
    final histories = prefs.getStringList('exam_histories') ?? [];
    
    // Insert the history back at its original position
    histories.insert(_lastDeletedIndex!, _lastDeletedHistoryJson!);
    await prefs.setStringList('exam_histories', histories);

    setState(() {
      _examHistories.insert(_lastDeletedIndex!, _lastDeletedHistory!);
    });

    // Clear the stored deleted item
    _lastDeletedHistory = null;
    _lastDeletedHistoryJson = null;
    _lastDeletedIndex = null;
  }

  Future<bool> _confirmDelete(String examTitle) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete History'),
        content: Text('Are you sure you want to delete the history for "$examTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
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

                    return Dismissible(
                      key: Key(history.examId + history.takenAt.toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmDelete(history.title),
                      onDismissed: (_) => _deleteExamHistory(index),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade700,
                        ),
                      ),
                      child: Card(
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
                                  Row(
                                    children: [
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
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red.shade400,
                                          size: 20,
                                        ),
                                        onPressed: () async {
                                          if (await _confirmDelete(history.title)) {
                                            _deleteExamHistory(index);
                                          }
                                        },
                                        tooltip: 'Delete this exam history',
                                      ),
                                    ],
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

  @override
  void dispose() {
    // Clear any stored deleted items when disposing
    _lastDeletedHistory = null;
    _lastDeletedHistoryJson = null;
    _lastDeletedIndex = null;
    super.dispose();
  }
}
