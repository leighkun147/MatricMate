import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/chapter.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../models/chapter_questions.dart';
import '../screens/practice_mode_screen.dart';
import '../screens/mock_exam_screen.dart';
import '../utils/chapter_completion_manager.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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
  Map<int, List<Chapter>> _chaptersWithCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: grades.length, vsync: this);
    _loadCompletionStatus();
  }

  Future<void> _loadCompletionStatus() async {
    final updatedChapters = Map<int, List<Chapter>>.from(widget.subject.chapters);
    
    for (var grade in grades) {
      if (widget.subject.chapters.containsKey(grade)) {
        final statusMap = await ChapterCompletionManager.getCompletionStatusForSubject(
          widget.subject.name,
          grade,
        );
        
        updatedChapters[grade] = widget.subject.chapters[grade]!.map((chapter) {
          return Chapter(
            title: chapter.title,
            grade: chapter.grade,
            isCompleted: statusMap[chapter.title] ?? false,
          );
        }).toList();
      }
    }
    
    if (mounted) {
      setState(() {
        _chaptersWithCompletionStatus = updatedChapters;
      });
    }
  }

  Future<void> _updateChapterCompletion(Chapter chapter, bool isCompleted) async {
    await ChapterCompletionManager.setChapterCompletion(
      widget.subject.name,
      chapter.title,
      chapter.grade,
      isCompleted,
    );
    
    if (mounted) {
      setState(() {
        final gradeChapters = _chaptersWithCompletionStatus[chapter.grade]!;
        final chapterIndex = gradeChapters.indexWhere((c) => c.title == chapter.title);
        
        gradeChapters[chapterIndex] = Chapter(
          title: chapter.title,
          grade: chapter.grade,
          isCompleted: isCompleted,
        );
      });
    }
    
    if (isCompleted) {
      _showCompletionDialog();
    }
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
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
                tabs: grades.map((grade) => Tab(text: 'Grade $grade')).toList(),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: grades.map((grade) {
                    final chapters = _chaptersWithCompletionStatus[grade] ?? [];
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
                ListTile(
                  title: Text(
                    chapter.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  subtitle: FutureBuilder<ChapterQuestions>(
                    future: _loadQuestionsFromJson(chapter.title),
                    builder: (context, snapshot) {
                      final questionsCount =
                          snapshot.data?.numberOfQuestions ?? 0;
                      return Text('$questionsCount Questions');
                    },
                  ),
                  trailing: Checkbox(
                    value: chapter.isCompleted,
                    onChanged: (bool? value) {
                      _updateChapterCompletion(chapter, value ?? false);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
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
                              builder: (context) =>
                                  FutureBuilder<ChapterQuestions>(
                                future: _loadQuestionsFromJson(chapter.title),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  if (snapshot.hasError) {
                                    return Center(
                                        child: Text(
                                            'Error loading questions: ${snapshot.error}'));
                                  }

                                  final chapterData = snapshot.data!;

                                  return PracticeModeScreen(
                                    exam: Exam(
                                      id: 'practice_${chapter.title}',
                                      title: '${chapter.title} Practice',
                                      subject: widget.subject.name,
                                      year: DateTime.now().year,
                                      questions: chapterData.questions,
                                      duration: Duration(
                                          minutes: chapterData.duration),
                                      constants: chapterData.constants,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.school),
                        label: const Text('Practice Mode'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
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
                              builder: (context) =>
                                  FutureBuilder<ChapterQuestions>(
                                future: _loadQuestionsFromJson(chapter.title),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  if (snapshot.hasError) {
                                    return Center(
                                        child: Text(
                                            'Error loading questions: ${snapshot.error}'));
                                  }

                                  final chapterData = snapshot.data!;

                                  return MockExamScreen(
                                    exam: Exam(
                                      id: 'mock_${chapter.title}',
                                      title: '${chapter.title} Mock Exam',
                                      subject: widget.subject.name,
                                      year: DateTime.now().year,
                                      questions: chapterData.questions,
                                      duration: Duration(
                                          minutes: chapterData.duration),
                                      constants: chapterData.constants,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.timer),
                        label: const Text('Mock Exam'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSecondary,
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

  Future<ChapterQuestions> _loadQuestionsFromJson(String chapterTitle) async {
    try {
      final String jsonString = await rootBundle.loadString(
          'assets/questions/subject_chapters_questions/$chapterTitle.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      return ChapterQuestions.fromJson(jsonData);
    } catch (e) {
      print('Error loading questions for $chapterTitle: $e');
      // Return default values if JSON file is not found or has errors
      return ChapterQuestions(
        title: chapterTitle,
        duration: 60,
        numberOfQuestions: 0,
        questions: [],
      );
    }
  }
}
