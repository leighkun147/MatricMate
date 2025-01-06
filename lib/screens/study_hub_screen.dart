import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../utils/stream_utils.dart';
import 'practice_mode_screen.dart';
import 'mock_exam_screen.dart';

class StudyHubScreen extends StatefulWidget {
  const StudyHubScreen({super.key});

  @override
  State<StudyHubScreen> createState() => _StudyHubScreenState();
}

class _StudyHubScreenState extends State<StudyHubScreen> {
  @override
  Widget build(BuildContext context) {
    final subjects = StreamUtils.getSubjects();

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
        body: subjects.isEmpty
            ? const Center(
                child: Text(
                  'Please select your stream in the Profile section',
                  style: TextStyle(fontSize: 16),
                ),
              )
            : TabBarView(
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

  List<Exam> _getDummyExams() {
    // This would typically come from a database or API
    return List.generate(
      10,
      (index) => Exam(
        id: 'exam_$index',
        title: '$subject - ${2023 - index}',
        subject: subject,
        year: 2023 - index,
        duration: const Duration(hours: 3),
        questions: List.generate(
          40,
          (qIndex) => Question(
            id: 'q_$qIndex',
            text: 'Sample question ${qIndex + 1} for $subject',
            options: [
              'Option A',
              'Option B',
              'Option C',
              'Option D',
            ],
            correctOptionIndex: 0,
            explanation: 'This is a detailed explanation for question ${qIndex + 1}',
          ),
        ),
        lastScore: (index % 2 == 0) ? 85.0 : null,
        questionsAttempted: (index % 2 == 0) ? 38 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exams = _getDummyExams();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  exam.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${exam.questions.length} questions'),
                trailing: exam.lastScore != null
                    ? CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Text('${exam.lastScore!.toInt()}%'),
                      )
                    : null,
              ),
              if (exam.lastScore != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Last attempt: ${exam.questionsAttempted} questions attempted',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
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
  }
}
