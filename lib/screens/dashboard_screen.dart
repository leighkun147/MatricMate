import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math' as math;
import 'discord_screen.dart';
import 'download_contents_screen.dart';
import 'study_plan_screen.dart';
import 'payment_methods_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/device_id_manager.dart';
import '../utils/stream_utils.dart';
import '../models/subject.dart';
import '../utils/chapter_completion_manager.dart';
import 'cash_out_screen.dart';
import 'model_exams_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late DateTime currentTime;
  late Timer timer;
  List<String> _subjects = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    currentTime = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateTime.now();
      });
    });
    _loadSubjects();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _loadSubjects() async {
    final selectedStream = await StreamUtils.selectedStream;
    if (mounted) {
      setState(() {
        _subjects = selectedStream == StreamType.naturalScience
            ? [
                'Mathematics',
                'Physics',
                'Chemistry',
                'Biology',
                'English',
                'Aptitude',
              ]
            : [
                'Mathematics',
                'English',
                'Geography',
                'History',
                'Economics',
                'Aptitude',
              ];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    timer.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildImageCarousel(),
          const SizedBox(height: 20),
          _buildPerformanceCard(),
          const SizedBox(height: 20),
          _buildFeatureCards(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    final List<Map<String, String>> carouselItems = [
      {
        'image': 'assets/images/IMG-20231230-WA0001.jpg',
        'title': 'Welcome to MatricMate',
        'description': 'Your ultimate companion for exam preparation'
      },
      {
        'image': 'assets/images/IMG-20231230-WA0002.jpg',
        'title': 'Study Planning',
        'description': 'Create and manage your study schedule effectively'
      },
      {
        'image': 'assets/images/IMG-20240317-WA0006.jpg',
        'title': 'Practice Questions',
        'description': 'Access a wide range of practice materials'
      },
      {
        'image': 'assets/images/IMG-20240317-WA0007.jpg',
        'title': 'Track Progress',
        'description': 'Monitor your performance and improvements'
      },
      {
        'image': 'assets/images/IMG-20240317-WA0009.jpg',
        'title': 'Join Olympiads',
        'description': 'Participate in academic competitions'
      },
      {
        'image': 'assets/images/IMG-20240317-WA0010.jpg',
        'title': 'Study Resources',
        'description': 'Access comprehensive study materials'
      },
      {
        'image': 'assets/images/IMG-20240317-WA0011.jpg',
        'title': 'Performance Analytics',
        'description': 'Get detailed insights into your progress'
      },
      {
        'image': 'assets/images/IMG-20240317-WA0012.jpg',
        'title': 'Community Support',
        'description': 'Connect with fellow students and educators'
      },
      {
        'image': 'assets/images/IMG-20240317-WA0013.jpg',
        'title': 'Exam Preparation',
        'description': 'Get ready for your national exams'
      },
      {
        'image': 'assets/images/IMG-20240317-WA0014.jpg',
        'title': 'About Us',
        'description': 'Learn more about MatricMate and our mission'
      },
    ];

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: carouselItems.length,
        itemBuilder: (context, index) {
          final item = carouselItems[index];
          return Container(
            width: MediaQuery.of(context).size.width * 0.8,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      item['image']!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['description']!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Performance Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildInfoButton(),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Theme.of(context).colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Theme.of(context).colorScheme.onPrimary,
                      unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      tabs: [
                        Tab(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.pie_chart),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Overall Progress',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Tab(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.subject),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Subject Progress',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverallProgressCard(),
                        _buildSubjectProgressCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoButton() {
    return IconButton(
      icon: Icon(
        Icons.info_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Performance Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoItem(
                        Icons.pie_chart,
                        'Overall Progress',
                        'View your total progress across all subjects with detailed analytics.',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(
                        Icons.subject,
                        'Subject Progress',
                        'Track individual subject completion and identify areas needing attention.',
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverallProgressCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: FutureBuilder<List<double>>(
            future: Future.wait(
              _subjects.map((subject) {
                Subject? subjectDef;
                if (subject == 'English') {
                  subjectDef = getEnglishSubject();
                } else if (subject == 'Aptitude') {
                  subjectDef = getAptitudeSubject();
                } else {
                  subjectDef = [...naturalScienceSubjects, ...socialScienceSubjects]
                      .firstWhere((s) => s.name == subject);
                }
                
                return ChapterCompletionManager.getSubjectCompletionPercentage(
                  subject,
                  [9, 10, 11, 12],
                  subjectDef.totalChapters,
                );
              }),
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox(
                  height: constraints.maxHeight * 0.8,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final percentages = snapshot.data!;
              final averagePercentage = percentages.isEmpty 
                  ? 0.0 
                  : percentages.reduce((a, b) => a + b) / percentages.length;

              return Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: Stack(
                      children: [
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: averagePercentage),
                            duration: const Duration(milliseconds: 1500),
                            builder: (context, value, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sectionsSpace: 0,
                                      centerSpaceRadius: 60,
                                      sections: [
                                        PieChartSectionData(
                                          value: value,
                                          color: _getColorForPercentage(value),
                                          radius: 50,
                                          showTitle: false,
                                        ),
                                        if (value < 100)
                                          PieChartSectionData(
                                            value: 100 - value,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            radius: 50,
                                            showTitle: false,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0, end: value),
                                        duration: const Duration(milliseconds: 1500),
                                        builder: (context, value, child) {
                                          return Text(
                                            '${value.toStringAsFixed(1)}%',
                                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: _getColorForPercentage(averagePercentage),
                                            ),
                                          );
                                        },
                                      ),
                                      Text(
                                        'Complete',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Positioned(
                          right: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildAnimatedStatCard(
                                'Strongest Subject',
                                _subjects[percentages.indexOf(percentages.reduce((a, b) => math.max(a, b)))],
                                Icons.emoji_events,
                                Colors.amber,
                              ),
                              const SizedBox(height: 12),
                              _buildAnimatedStatCard(
                                'Needs Attention',
                                _subjects[percentages.indexOf(percentages.reduce((a, b) => math.min(a, b)))],
                                Icons.warning_outlined,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getColorForPercentage(averagePercentage).withOpacity(0.15),
                          _getColorForPercentage(averagePercentage).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getColorForPercentage(averagePercentage).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForPercentage(averagePercentage),
                          color: _getColorForPercentage(averagePercentage),
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getMessageForPercentage(averagePercentage),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _getColorForPercentage(averagePercentage),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStatCard(String label, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.4,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildSubjectProgressCard() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Subject Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swipe,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Swipe',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_subjects.isEmpty)
          const Center(
            child: Text(
              'Please select your stream in the Profile section',
              style: TextStyle(fontSize: 16),
            ),
          )
        else
          Expanded(
            child: PageView.builder(
              itemCount: (_subjects.length / 2).ceil(),
              itemBuilder: (context, pageIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildSubjectProgressRow(pageIndex * 2),
                      if (pageIndex * 2 + 1 < _subjects.length)
                        const SizedBox(height: 16),
                      if (pageIndex * 2 + 1 < _subjects.length)
                        _buildSubjectProgressRow(pageIndex * 2 + 1),
                      const SizedBox(height: 16),
                      // Page indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(
                            (_subjects.length / 2).ceil(),
                            (index) => Container(
                              width: index == pageIndex ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: index == pageIndex
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSubjectProgressRow(int index) {
    if (index >= _subjects.length) return const SizedBox();
    
    final subject = _subjects[index];
    Subject subjectDef;
    if (subject == 'English') {
      subjectDef = getEnglishSubject();
    } else if (subject == 'Aptitude') {
      subjectDef = getAptitudeSubject();
    } else {
      subjectDef = [...naturalScienceSubjects, ...socialScienceSubjects]
          .firstWhere((s) => s.name == subject);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subject,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Chapters: ${subjectDef.totalChapters}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 24),
            Expanded(
              flex: 2,
              child: FutureBuilder<double>(
                future: ChapterCompletionManager.getSubjectCompletionPercentage(
                  subject,
                  [9, 10, 11, 12],
                  subjectDef.totalChapters,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final percentage = snapshot.data!;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 0,
                                centerSpaceRadius: 0,
                                sections: [
                                  PieChartSectionData(
                                    value: percentage,
                                    color: _getColorForPercentage(percentage),
                                    radius: 20,
                                    showTitle: false,
                                  ),
                                  if (percentage < 100)
                                    PieChartSectionData(
                                      value: 100 - percentage,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      radius: 20,
                                      showTitle: false,
                                    ),
                                ],
                              ),
                            ),
                            Center(
                              child: Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getColorForPercentage(percentage),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getProgressMessage(percentage),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getColorForPercentage(percentage),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProgressMessage(double percentage) {
    if (percentage >= 80) {
      return 'Excellent!';
    } else if (percentage >= 60) {
      return 'Good Progress';
    } else if (percentage >= 40) {
      return 'Keep Going';
    } else {
      return 'Needs Focus';
    }
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  IconData _getIconForPercentage(double percentage) {
    if (percentage >= 90) return Icons.emoji_events;
    if (percentage >= 75) return Icons.star;
    if (percentage >= 60) return Icons.thumb_up;
    if (percentage >= 40) return Icons.trending_up;
    return Icons.warning_outlined;
  }

  String _getMessageForPercentage(double percentage) {
    if (percentage >= 80) {
      return 'Excellent progress! Keep up the great work. You\'re well-prepared for your exams.';
    } else if (percentage >= 60) {
      return 'Good progress! Stay consistent and focus on challenging topics.';
    } else if (percentage >= 40) {
      return 'Making progress. Try to increase your study time for better results.';
    } else {
      return 'Needs attention. Create a study plan and focus on fundamentals.';
    }
  }

  Widget _buildFeatureCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: [
        _buildFeatureCard(
          'Download Contents',
          Icon(
            Icons.download,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DownloadContentsScreen(),
              ),
            );
          },
        ),
        _buildPaymentMethodsCard(),
        _buildFeatureCard(
          'Study Plan',
          Icon(
            Icons.calendar_today,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudyPlanScreen(),
              ),
            );
          },
        ),
        _buildFeatureCard(
          'Model Exams',
          Image.asset(
            'assets/icons/model_exam.png',
            width: 40,
            height: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ModelExamsScreen(),
              ),
            );
          },
        ),
        _buildFeatureCard(
          'Discord',
          Icon(
            Icons.chat,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DiscordScreen(),
              ),
            );
          },
        ),
        _buildFeatureCard(
          'Cashout',
          Icon(
            Icons.attach_money,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CashOutScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, dynamic icon, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          try {
            String? deviceId = await DeviceIdManager.getDeviceId();
            if (deviceId == null) {
              throw Exception('Could not get device ID');
            }

            try {
              final doc = await FirebaseFirestore.instance
                  .collection('requests')
                  .doc(deviceId)
                  .get();

              if (doc.exists && doc.get('status') == 'pending') {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Payment Request Pending'),
                        content: const Text(
                          'You have a pending payment request. Please wait for confirmation before making another request.',
                          style: TextStyle(fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                }
                return;
              }
              if (doc.exists && doc.get('status') == 'rejected') {
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      String rejectionReason =
                          doc.get('rejection_reason') ?? 'No reason provided';
                      return AlertDialog(
                        title: const Text('Payment Request Rejected'),
                        content: Text(
                          'Your payment request has been rejected.\n\nReason: $rejectionReason\n\nYou can try again later or visit the payment options to update your payment method',
                          style: const TextStyle(fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PaymentMethodsScreen(),
                                ),
                              );
                            },
                            child: const Text('Go to Payment Methods'),
                          ),
                        ],
                      );
                    },
                  );
                }
                return;
              }
            } catch (e) {
              print('Error checking request status: $e');
            }

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentMethodsScreen(),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            const Text(
              'Payment Methods',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
