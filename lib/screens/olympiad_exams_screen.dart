import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../utils/stream_utils.dart';
import 'exam_taking_screen.dart';
import '../models/exam_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OlympiadExamsScreen extends StatefulWidget {
  const OlympiadExamsScreen({super.key});

  @override
  State<OlympiadExamsScreen> createState() => _OlympiadExamsScreenState();
}

class _OlympiadExamsScreenState extends State<OlympiadExamsScreen> {
  List<FileSystemEntity> _exams = [];
  String _currentStream = 'natural_science';
  bool _isLoading = true;
  Map<String, ExamResult> _examResults = {};

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<Directory> _getExamDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final examDir = Directory('${appDir.path}/assets/questions/olympiad_exams');
    if (!await examDir.exists()) {
      await examDir.create(recursive: true);
    }
    return examDir;
  }

  Future<void> _loadExamResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = prefs.getStringList('olympiad_exam_results') ?? [];
      setState(() {
        _examResults = {
          for (var result in results)
            jsonDecode(result)['examId'] as String:
                ExamResult.fromJson(jsonDecode(result))
        };
      });
    } catch (e) {
      print('Error loading exam results: $e');
      setState(() {
        _examResults = {};
      });
    }
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    try {
      await _loadExamResults();
      final examDir = await _getExamDirectory();
      final selectedStream = await StreamUtils.selectedStream;
      
      if (selectedStream == null) {
        setState(() {
          _exams = [];
          _isLoading = false;
        });
        return;
      }

      _currentStream = selectedStream == StreamType.naturalScience
          ? 'natural_science'
          : 'social_science';

      final streamDir = Directory('${examDir.path}/$_currentStream');
      if (!await streamDir.exists()) {
        setState(() {
          _exams = [];
          _isLoading = false;
        });
        return;
      }

      final files = await streamDir.list().toList();
      setState(() {
        _exams = files;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading exams: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startExam(FileSystemEntity examFile) async {
    final examId = examFile.path.split('/').last;

    // Check if exam has already been taken
    if (_examResults.containsKey(examId)) {
      if (!mounted) return;
      
      // Show exam result if already taken
      final result = _examResults[examId]!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exam Already Completed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Score: ${result.scorePercentage.toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('Correct Answers: ${result.correctAnswers} out of ${result.totalQuestions}'),
              const SizedBox(height: 8),
              Text('Completed on: ${result.takenAt.toString().split('.')[0]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final result = await Navigator.push<ExamResult>(
      context,
      MaterialPageRoute(
        builder: (context) => ExamTakingScreen(
          examFile: examFile as File,
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        // Save exam result
        final prefs = await SharedPreferences.getInstance();
        final results = prefs.getStringList('olympiad_exam_results') ?? [];
        results.add(jsonEncode(result.toJson()));
        await prefs.setStringList('olympiad_exam_results', results);
        
        setState(() {
          _examResults[examId] = result;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exam completed with score: ${result.scorePercentage.toStringAsFixed(1)}%'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error saving exam result: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving exam result'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Olympiad Exams'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No exams available for ${_currentStream.replaceAll('_', ' ').toUpperCase()}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadExams,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadExams,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _exams.length,
                    itemBuilder: (context, index) {
                      final exam = _exams[index];
                      final examName = exam.path.split('/').last;
                      
                      final examResult = _examResults[examName];
                      final bool examTaken = examResult != null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: examTaken ? Colors.blue : Colors.grey[300],
                            child: Icon(
                              examTaken ? Icons.check : Icons.quiz,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            examName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Stream: ${_currentStream.replaceAll('_', ' ').toUpperCase()}',
                          ),
                          trailing: examTaken
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () => _startExam(exam),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Start'),
                                ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
