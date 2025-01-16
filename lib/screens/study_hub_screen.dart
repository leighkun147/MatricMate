import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../utils/stream_utils.dart';
import 'practice_mode_screen.dart';
import 'mock_exam_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/academic_year_exam.dart';

class StudyHubScreen extends StatefulWidget {
  const StudyHubScreen({super.key});

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen> {
  @override
  Widget build(BuildContext context) {
    // Get subjects, default to social science subjects if empty
    List<String> subjects = StreamUtils.getSubjects();
    if (subjects.isEmpty) {
      subjects = [
          'Math (Social Science)',
          'English',
          'Aptitude(SAT)',
          'Economics',
          'Geography',
          'History',
        ];
    }

    return DefaultTabController(
      length: subjects.length,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            isScrollable: true,
            tabs: subjects.map((subject) => Tab(text: subject)).toList(),
          ),
        ),
        body: TabBarView(
          children: subjects
              .map((subject) => _SubjectExamList(subject: subject))
              .toList(),
        ),
      ),
    );
  }
}

class _SubjectExamList extends StatelessWidget {
  final String subject;

  const _SubjectExamList({
    required this.subject,
  });

  Future<List<AcademicYearExam>> _loadAcademicYearExams() async {
    List<AcademicYearExam> exams = [];
    final currentYear = DateTime.now().year;
    // Start from 1990 to include older exam files
    final startYear = 1990;
    
    print('Attempting to load exams for subject: $subject from $startYear to $currentYear');
    
    for (int year = startYear; year <= currentYear; year++) {
      try {
        final List<String> possiblePaths = [
          'assets/questions/academic_year/$subject$year.json',
          'assets/questions/academic_year/${subject.toLowerCase()}$year.json',
        ];

        String? jsonString;
        String? successPath;
        
        for (final path in possiblePaths) {
          try {
            print('Trying to load: $path');
            jsonString = await rootBundle.loadString(path);
            successPath = path;
            print('Successfully loaded file: $path');
            print('File contents: $jsonString'); 
            break;
          } catch (e) {
            continue;
          }
        }

        if (jsonString == null) {
          throw Exception('No valid file found for $subject$year');
        }
        
        try {
          final Map<String, dynamic> jsonData = json.decode(jsonString);
          print('Successfully parsed JSON: $jsonData');
          final exam = AcademicYearExam.fromJson(
            jsonData,
            subject: subject,
            year: year,
          );
          print('Successfully created exam object: ${exam.subject}, ${exam.year}, ${exam.numberOfQuestions} questions');
          exams.add(exam);
        } catch (e) {
          print('Error parsing JSON or creating exam object: $e');
          rethrow;
        }
      } catch (e) {
        print('Error loading $subject$year: $e');
        continue;
      }
    }
    
    print('Found ${exams.length} exams for $subject');
    exams.sort((a, b) => b.year.compareTo(a.year));
    return exams;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AcademicYearExam>>(
      future: _loadAcademicYearExams(),
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
              'No exams available for this subject',
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
              id: '${subject}_${examData.year}',
              title: '$subject ${examData.year}',
              subject: subject,
              year: examData.year,
              questions: examData.questions,
              duration: Duration(minutes: examData.duration),
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
