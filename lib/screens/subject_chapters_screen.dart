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
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import './chapter_videos_screen.dart';

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
    final updatedChapters =
        Map<int, List<Chapter>>.from(widget.subject.chapters);

    for (var grade in grades) {
      if (widget.subject.chapters.containsKey(grade)) {
        final statusMap =
            await ChapterCompletionManager.getCompletionStatusForSubject(
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

  Future<void> _updateChapterCompletion(
      Chapter chapter, bool isCompleted) async {
    await ChapterCompletionManager.setChapterCompletion(
      widget.subject.name,
      chapter.title,
      chapter.grade,
      isCompleted,
    );

    if (mounted) {
      setState(() {
        final gradeChapters = _chaptersWithCompletionStatus[chapter.grade]!;
        final chapterIndex =
            gradeChapters.indexWhere((c) => c.title == chapter.title);

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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Practice Mode Button
                          Expanded(
                            flex: 4,
                            child: SizedBox(
                              height: 45,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FutureBuilder<ChapterQuestions>(
                                          future: _loadQuestionsFromJson(
                                              chapter.title),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator());
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
                                                title:
                                                    '${chapter.title} Practice',
                                                subject: widget.subject.name,
                                                year: DateTime.now().year,
                                                questions: chapterData.questions,
                                                duration: Duration(
                                                    minutes:
                                                        chapterData.duration),
                                                constants: chapterData.constants,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.quiz, size: 24, color: Colors.white),
                                  label: const Text(
                                    'Practice',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Video Lessons Button
                          Expanded(
                            flex: 2,  // Smaller flex for icon-only button
                            child: SizedBox(
                              height: 45,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChapterVideosScreen(
                                        subject: widget.subject.name,
                                        chapter: chapter.title,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(45, 45),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.play_circle_fill,
                                  size: 28,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Mock Exam Button
                          Expanded(
                            flex: 4,
                            child: SizedBox(
                              height: 45,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FutureBuilder<ChapterQuestions>(
                                          future: _loadQuestionsFromJson(
                                              chapter.title),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator());
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
                                                title:
                                                    '${chapter.title} Mock Exam',
                                                subject: widget.subject.name,
                                                year: DateTime.now().year,
                                                questions: chapterData.questions,
                                                duration: Duration(
                                                    minutes:
                                                        chapterData.duration),
                                                constants: chapterData.constants,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.timer, size: 24, color: Colors.white),
                                  label: const Text(
                                    'Mock',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onSecondary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
      // List of possible file locations to check
      final List<String> possiblePaths = [
        'assets/questions/subject_chapters_questions/$chapterTitle.json',
        'assets/questions/subject_chapters_questions/${chapterTitle.toLowerCase()}.json',
      ];

      // Add paths from the application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final documentsDir = Directory(path.join(
        appDir.path,
        'assets',
        'questions',
        'subject_chapters_questions',
      ));

      if (await documentsDir.exists()) {
        possiblePaths.addAll([
          path.join(documentsDir.path, '$chapterTitle.json'),
          path.join(documentsDir.path, '${chapterTitle.toLowerCase()}.json'),
        ]);
      }

      String? jsonString;
      String? successPath;

      // Try each possible path until we find a valid file
      for (final filePath in possiblePaths) {
        try {
          print('Trying to load chapter questions from: $filePath');
          if (filePath.startsWith('assets/')) {
            jsonString = await rootBundle.loadString(filePath);
          } else {
            final file = File(filePath);
            if (await file.exists()) {
              jsonString = await file.readAsString();
            }
          }
          if (jsonString != null) {
            successPath = filePath;
            print('Successfully loaded chapter questions from: $filePath');
            break;
          }
        } catch (e) {
          print('Failed to load from $filePath: $e');
          continue;
        }
      }

      if (jsonString == null) {
        throw Exception('No valid file found for chapter: $chapterTitle');
      }

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
