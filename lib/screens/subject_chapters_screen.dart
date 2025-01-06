import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/chapter.dart';

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
                          // TODO: Navigate to practice mode
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
                          // TODO: Navigate to mock exam mode 
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
}
