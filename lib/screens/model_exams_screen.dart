import 'dart:io';
import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../utils/stream_utils.dart';
import 'practice_mode_screen.dart';
import 'mock_exam_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/academic_year_exam.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ModelExamsScreen extends StatefulWidget {
  const ModelExamsScreen({super.key});

  @override
  State<ModelExamsScreen> createState() => _ModelExamsScreenState();
}

class _ModelExamsScreenState extends State<ModelExamsScreen> {
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subjects = await StreamUtils.getSubjects();
    if (mounted) {
      setState(() {
        _subjects = subjects.isEmpty ? [
          'Mathematics',
          'Physics',
          'Chemistry',
          'Biology',
          'English',
          'Aptitude',
        ] : subjects;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_subjects.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DefaultTabController(
      length: _subjects.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Model Exams'),
          bottom: TabBar(
            isScrollable: true,
            tabs: _subjects.map((subject) => Tab(text: subject)).toList(),
          ),
        ),
        body: TabBarView(
          children: _subjects
              .map((subject) => _SubjectModelExamList(subject: subject))
              .toList(),
        ),
      ),
    );
  }
}

class _SubjectModelExamList extends StatelessWidget {
  final String subject;

  const _SubjectModelExamList({
    required this.subject,
  });

  Future<List<AcademicYearExam>> _loadModelExams() async {
    List<AcademicYearExam> exams = [];
    int examIndex = 1;
    bool hasMoreExams = true;

    // Get the app's document directory for downloaded files
    final appDir = await getApplicationDocumentsDirectory();
    final downloadedExamsDir = Directory(path.join(
      appDir.path,
      'assets',
      'questions',
      'model_exams',
    ));

    while (hasMoreExams) {
      try {
        final List<String> possiblePaths = [
          'assets/questions/model_exams/$subject$examIndex.json',
          'assets/questions/model_exams/${subject.toLowerCase()}$examIndex.json',
        ];

        // Add paths for downloaded files
        if (await downloadedExamsDir.exists()) {
          possiblePaths.addAll([
            path.join(downloadedExamsDir.path, '$subject$examIndex.json'),
            path.join(downloadedExamsDir.path, '${subject.toLowerCase()}$examIndex.json'),
          ]);
        }

        String? jsonString;
        String? successPath;
        
        for (final path in possiblePaths) {
          try {
            print('Trying to load: $path');
            if (path.startsWith('assets/')) {
              // Load from assets bundle
              jsonString = await rootBundle.loadString(path);
            } else {
              // Load from file system
              final file = File(path);
              if (await file.exists()) {
                jsonString = await file.readAsString();
              }
            }
            if (jsonString != null) {
              successPath = path;
              print('Successfully loaded file: $path');
              break;
            }
          } catch (e) {
            print('Failed to load $path: $e');
            continue;
          }
        }

        if (jsonString == null) {
          print('No more exams found for $subject at index $examIndex');
          hasMoreExams = false;
          break;
        }
        
        try {
          final Map<String, dynamic> jsonData = json.decode(jsonString);
          final exam = AcademicYearExam.fromJson(
            jsonData,
            subject: subject,
            year: examIndex,  // Using index instead of year for model exams
          );
          exams.add(exam);
          print('Added exam from: $successPath');
          examIndex++;
        } catch (e) {
          print('Error parsing JSON for model exam $examIndex: $e');
          hasMoreExams = false;
          break;
        }
      } catch (e) {
        print('Error loading model exam $examIndex: $e');
        hasMoreExams = false;
        break;
      }
    }
    
    print('Found ${exams.length} model exams for $subject');
    return exams;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AcademicYearExam>>(
      future: _loadModelExams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading exams: ${snapshot.error}'));
        }

        final exams = snapshot.data ?? [];

        if (exams.isEmpty) {
          return const Center(
            child: Text(
              'No model exams available for this subject',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            final examData = exams[index];
            final exam = Exam(
              id: examData.title ?? '${subject}_model_${index + 1}',
              title: examData.title ?? '$subject Model Exam ${index + 1}',
              subject: subject,
              year: index + 1,  // Using index for model exams
              questions: examData.questions,
              duration: Duration(minutes: examData.duration),
              constants: examData.constants,
            );
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      exam.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${examData.numberOfQuestions} Questions • ${examData.duration} Minutes'),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PracticeModeScreen(exam: exam),
                                ),
                              );
                            },
                            icon: const Icon(Icons.book),
                            label: const Text('Practice Mode'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MockExamScreen(exam: exam),
                                ),
                              );
                            },
                            icon: const Icon(Icons.timer),
                            label: const Text('Mock Exam'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
