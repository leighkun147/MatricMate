import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/subject.dart';
import '../utils/stream_utils.dart';
import '../utils/chapter_completion_manager.dart';
import 'subject_chapters_screen.dart';
import 'english_screen.dart';
import 'aptitude_screen.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final selectedStream = await StreamUtils.selectedStream;
    if (mounted) {
      setState(() {
        _subjects = selectedStream == StreamType.naturalScience
            ? naturalScienceSubjects
            : socialScienceSubjects;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _subjects.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'Study',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onBackground,
                              ),
                        ),
                      ),
                    ),
                    if (_subjects.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'Please select your stream in the Profile section',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    else
                      SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildSubjectCard(
                            context,
                            _subjects[index],
                            index,
                          ),
                          childCount: _subjects.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, Subject subject, int index) {
    return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (subject.name == 'English') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnglishScreen(),
                ),
              );
            } else if (subject.name == 'Aptitude') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AptitudeScreen(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubjectChaptersScreen(subject: subject),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ],
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Image.asset(
                        'assets/icons/${subject.name.toLowerCase()}.png',
                        width: 64,
                        height: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 8.0),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subject.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: FutureBuilder<double>(
                          future: ChapterCompletionManager
                              .getSubjectCompletionPercentage(
                            subject.name,
                            [9, 10, 11, 12],
                            subject.totalChapters,
                          ),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return const SizedBox.shrink();

                            final percentage = snapshot.data!;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 0,
                                      centerSpaceRadius: 0,
                                      sections: [
                                        PieChartSectionData(
                                          value: percentage,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          radius: 8,
                                          showTitle: false,
                                        ),
                                        if (percentage < 100)
                                          PieChartSectionData(
                                            value: 100 - percentage,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.2),
                                            radius: 8,
                                            showTitle: false,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)));
  }
}
