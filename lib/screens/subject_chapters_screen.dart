import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/chapter.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../screens/practice_mode_screen.dart';
import '../screens/mock_exam_screen.dart';

class SubjectChaptersScreen extends StatefulWidget {
  final Subject subject;

  const SubjectChaptersScreen({
    Key? key,
    required this.subject,
  }) : super(key: key);

  @override
  State<SubjectChaptersScreen> createState() => _SubjectChaptersScreenState();
}

class _SubjectChaptersScreenState extends State<SubjectChaptersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<int> grades = [9, 10, 11, 12];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: grades.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Chapter Marked as Complete',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'You have marked this chapter as completed. Keep up the good work!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.subject.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: grades
                    .map((grade) => Tab(text: 'Grade $grade'))
                    .toList(),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: grades.map((grade) {
                    final chapters = widget.subject.chapters[grade] ?? [];
                    return _buildChapterList(chapters);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterList(List<Chapter> chapters) {
    if (chapters.isEmpty) {
      return Center(
        child: Text(
          'No chapters available',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chapter.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    Checkbox(
                      value: chapter.isCompleted,
                      onChanged: (bool? value) {
                        setState(() {
                          chapters[index] = Chapter(
                            title: chapter.title,
                            grade: chapter.grade,
                            isCompleted: value ?? false,
                          );
                        });
                        if (value ?? false) {
                          _showCompletionDialog();
                        }
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PracticeModeScreen(
                                exam: Exam(
                                  id: 'practice_${chapter.title}',
                                  title: '${chapter.title} Practice',
                                  subject: widget.subject.name,
                                  year: DateTime.now().year,
                                  questions: _getDummyQuestions(),
                                  duration: const Duration(minutes: 30),
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.school),
                        label: const Text('Practice Mode'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MockExamScreen(
                                exam: Exam(
                                  id: 'mock_${chapter.title}',
                                  title: '${chapter.title} Mock Exam',
                                  subject: widget.subject.name,
                                  year: DateTime.now().year,
                                  questions: _getDummyQuestions(),
                                  duration: const Duration(minutes: 60),
                                ),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.timer),
                        label: const Text('Mock Exam'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Question> _getDummyQuestions() {
    return [
      Question(
        id: 'q1',
        text: 'What is the capital city of Ethiopia?',
        options: ['Addis Ababa', 'Hawassa', 'Bahir Dar', 'Dire Dawa'],
        correctOptionIndex: 0,
        explanation: 'Addis Ababa is the capital city of Ethiopia.',
      ),
      Question(
        id: 'q2',
        text: 'Which Ethiopian emperor led the victory at Adwa?',
        options: ['Menelik II', 'Haile Selassie', 'Tewodros II', 'Yohannes IV'],
        correctOptionIndex: 0,
        explanation: 'Emperor Menelik II led Ethiopian forces to victory at the Battle of Adwa in 1896.',
      ),
      Question(
        id: 'q3',
        text: 'What is the main language spoken in Ethiopia?',
        options: ['Amharic', 'Tigrinya', 'Oromiffa', 'Somali'],
        correctOptionIndex: 0,
        explanation: 'Amharic is the official working language of Ethiopia.',
      ),
      Question(
        id: 'q4',
        text: 'Which Ethiopian coffee region is most famous?',
        options: ['Yirgacheffe', 'Sidamo', 'Harrar', 'Limu'],
        correctOptionIndex: 0,
        explanation: 'Yirgacheffe is internationally renowned for its high-quality coffee beans.',
      ),
    ];
  }
}
