import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
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

class _DashboardScreenState extends State<DashboardScreen> {
  final DateTime examDate = DateTime(2024, 6, 1); // Example exam date
  late DateTime currentTime;
  late Timer timer;
  List<String> _subjects = [];
  bool _isLoading = true;

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
          _buildCountdownTimer(),
          const SizedBox(height: 20),
          _buildPerformanceCard(),
          const SizedBox(height: 20),
          _buildSubjectProgress(),
          const SizedBox(height: 20),
          _buildFeatureCards(),
        ],
      ),
    );
  }

  Widget _buildCountdownTimer() {
    final difference = examDate.difference(currentTime);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
              Theme.of(context).colorScheme.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'Time Until National Exam',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeUnit('$days', 'Days'),
                _buildTimeUnit('$hours', 'Hours'),
                _buildTimeUnit('$minutes', 'Minutes'),
                _buildTimeUnit('$seconds', 'Seconds'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit(String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<double>>(
              future: Future.wait(
                _subjects.map((subject) {
                  // Get the subject definition to get total chapters
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
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final percentages = snapshot.data!;
                final averagePercentage = percentages.isEmpty 
                    ? 0.0 
                    : percentages.reduce((a, b) => a + b) / percentages.length;

                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 60,
                              sections: [
                                PieChartSectionData(
                                  value: averagePercentage,
                                  color: _getColorForPercentage(averagePercentage),
                                  radius: 50,
                                  showTitle: false,
                                ),
                                if (averagePercentage < 100)
                                  PieChartSectionData(
                                    value: 100 - averagePercentage,
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
                              Text(
                                '${averagePercentage.toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getColorForPercentage(averagePercentage),
                                ),
                              ),
                              Text(
                                'Complete',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getColorForPercentage(averagePercentage).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getMessageForPercentage(averagePercentage),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getColorForPercentage(averagePercentage),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getMessageForPercentage(double percentage) {
    if (percentage >= 80) {
      return 'Excellent progress! You\'re well-prepared for the exam. Focus on practice tests and reviewing challenging topics to maintain your strong performance.';
    } else if (percentage >= 60) {
      return 'Good progress! You\'re on the right track. Consider dedicating more time to subjects with lower completion rates to boost your overall readiness.';
    } else if (percentage >= 40) {
      return 'You\'re making progress, but there\'s room for improvement. Try to increase your study hours and focus on completing more chapters across all subjects.';
    } else {
      return 'Your preparation needs attention. Create a structured study plan and aim to complete more chapters each week. Don\'t hesitate to seek help with challenging topics.';
    }
  }

  Widget _buildSubjectProgress() {
    if (_subjects.isEmpty) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Please select your stream in the Profile section',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subject Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                // Get the subject definition to get total chapters
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        subject,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<double>(
                        future: ChapterCompletionManager.getSubjectCompletionPercentage(
                          subject,
                          [9, 10, 11, 12],
                          subjectDef.totalChapters,
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(),
                            );
                          }

                          final percentage = snapshot.data!;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 0,
                                    sections: [
                                      PieChartSectionData(
                                        value: percentage,
                                        color: Theme.of(context).colorScheme.primary,
                                        radius: 20,
                                        showTitle: false,
                                      ),
                                      if (percentage < 100)
                                        PieChartSectionData(
                                          value: 100 - percentage,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.2),
                                          radius: 20,
                                          showTitle: false,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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
