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
    exams.addAll(await _loadFromModelExams());
    exams.addAll(await _loadFromAcademicYear());
    exams.addAll(await _loadFromSubjectChapters());
    
    // Sort all exams by last modified date
    exams.sort((a, b) => b.year.compareTo(a.year));
    print('Found ${exams.length} total exams for $subject across all collections');
    return exams;
  }

  Future<List<AcademicYearExam>> _loadFromModelExams() async {
    List<AcademicYearExam> exams = [];
    int examIndex = 1;
    bool hasMoreExams = true;

    // Get the app's document directory for downloaded files
    final appDir = await getApplicationDocumentsDirectory();
    final modelExamsDir = Directory(path.join(
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

        if (await modelExamsDir.exists()) {
          possiblePaths.addAll([
            path.join(modelExamsDir.path, '$subject$examIndex.json'),
            path.join(modelExamsDir.path, '${subject.toLowerCase()}$examIndex.json'),
          ]);
        }

        String? jsonString;
        String? successPath;
        
        for (final path in possiblePaths) {
          try {
            print('Trying to load model exam: $path');
            if (path.startsWith('assets/')) {
              jsonString = await rootBundle.loadString(path);
            } else {
              final file = File(path);
              if (await file.exists()) {
                jsonString = await file.readAsString();
              }
            }
            if (jsonString != null) {
              successPath = path;
              print('Successfully loaded model exam: $path');
              break;
            }
          } catch (e) {
            print('Failed to load model exam $path: $e');
            continue;
          }
        }

        if (jsonString == null) {
          hasMoreExams = false;
          break;
        }
        
        try {
          final Map<String, dynamic> jsonData = json.decode(jsonString);
          final exam = AcademicYearExam.fromJson(
            jsonData,
            subject: subject,
            year: examIndex,
          );
          exams.add(exam);
          print('Added model exam from: $successPath');
          examIndex++;
        } catch (e) {
          print('Error parsing model exam JSON: $e');
          hasMoreExams = false;
          break;
        }
      } catch (e) {
        print('Error loading model exam: $e');
        hasMoreExams = false;
        break;
      }
    }
    
    print('Found ${exams.length} model exams for $subject');
    return exams;
  }

  Future<List<AcademicYearExam>> _loadFromAcademicYear() async {
    List<AcademicYearExam> exams = [];
    int examIndex = 1;
    bool hasMoreExams = true;

    // Get the app's document directory for downloaded files
    final appDir = await getApplicationDocumentsDirectory();
    final academicYearDir = Directory(path.join(
      appDir.path,
      'assets',
      'questions',
      'academic_year',
    ));

    while (hasMoreExams) {
      try {
        final List<String> possiblePaths = [
          'assets/questions/academic_year/$subject$examIndex.json',
          'assets/questions/academic_year/${subject.toLowerCase()}$examIndex.json',
        ];

        if (await academicYearDir.exists()) {
          possiblePaths.addAll([
            path.join(academicYearDir.path, '$subject$examIndex.json'),
            path.join(academicYearDir.path, '${subject.toLowerCase()}$examIndex.json'),
          ]);
        }

        String? jsonString;
        String? successPath;
        
        for (final path in possiblePaths) {
          try {
            print('Trying to load academic year exam: $path');
            if (path.startsWith('assets/')) {
              jsonString = await rootBundle.loadString(path);
            } else {
              final file = File(path);
              if (await file.exists()) {
                jsonString = await file.readAsString();
              }
            }
            if (jsonString != null) {
              successPath = path;
              print('Successfully loaded academic year exam: $path');
              break;
            }
          } catch (e) {
            print('Failed to load academic year exam $path: $e');
            continue;
          }
        }

        if (jsonString == null) {
          hasMoreExams = false;
          break;
        }
        
        try {
          final Map<String, dynamic> jsonData = json.decode(jsonString);
          final exam = AcademicYearExam.fromJson(
            jsonData,
            subject: subject,
            year: examIndex,
          );
          exams.add(exam);
          print('Added academic year exam from: $successPath');
          examIndex++;
        } catch (e) {
          print('Error parsing academic year exam JSON: $e');
          hasMoreExams = false;
          break;
        }
      } catch (e) {
        print('Error loading academic year exam: $e');
        hasMoreExams = false;
        break;
      }
    }
    
    print('Found ${exams.length} academic year exams for $subject');
    return exams;
  }

  Future<List<AcademicYearExam>> _loadFromSubjectChapters() async {
    List<AcademicYearExam> exams = [];
    int examIndex = 1;
    bool hasMoreExams = true;

    // Get the app's document directory for downloaded files
    final appDir = await getApplicationDocumentsDirectory();
    final chaptersDir = Directory(path.join(
      appDir.path,
      'assets',
      'questions',
      'subject_chapters_questions',
    ));

    while (hasMoreExams) {
      try {
        final List<String> possiblePaths = [
          'assets/questions/subject_chapters_questions/$subject$examIndex.json',
          'assets/questions/subject_chapters_questions/${subject.toLowerCase()}$examIndex.json',
        ];

        if (await chaptersDir.exists()) {
          possiblePaths.addAll([
            path.join(chaptersDir.path, '$subject$examIndex.json'),
            path.join(chaptersDir.path, '${subject.toLowerCase()}$examIndex.json'),
          ]);
        }

        String? jsonString;
        String? successPath;
        
        for (final path in possiblePaths) {
          try {
            print('Trying to load chapter exam: $path');
            if (path.startsWith('assets/')) {
              jsonString = await rootBundle.loadString(path);
            } else {
              final file = File(path);
              if (await file.exists()) {
                jsonString = await file.readAsString();
              }
            }
            if (jsonString != null) {
              successPath = path;
              print('Successfully loaded chapter exam: $path');
              break;
            }
          } catch (e) {
            print('Failed to load chapter exam $path: $e');
            continue;
          }
        }

        if (jsonString == null) {
          hasMoreExams = false;
          break;
        }
        
        try {
          final Map<String, dynamic> jsonData = json.decode(jsonString);
          final exam = AcademicYearExam.fromJson(
            jsonData,
            subject: subject,
            year: examIndex,
          );
          exams.add(exam);
          print('Added chapter exam from: $successPath');
          examIndex++;
        } catch (e) {
          print('Error parsing chapter exam JSON: $e');
          hasMoreExams = false;
          break;
        }
      } catch (e) {
        print('Error loading chapter exam: $e');
        hasMoreExams = false;
        break;
      }
    }
    
    print('Found ${exams.length} chapter exams for $subject');
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
              year: index + 1,
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
