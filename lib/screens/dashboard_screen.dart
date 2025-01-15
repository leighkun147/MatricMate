import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'discord_screen.dart';
import 'download_contents_screen.dart';
import 'study_plan_screen.dart';
import 'payment_methods_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/device_id_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DateTime examDate = DateTime(2024, 6, 1); // Example exam date
  late DateTime currentTime;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    currentTime = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Time Until National Exam',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
    );
  }

  Widget _buildTimeUnit(String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: Colors.white70,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ];
                          if (value >= 0 && value < days.length) {
                            return Text(days[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 40),
                        const FlSpot(1, 55),
                        const FlSpot(2, 45),
                        const FlSpot(3, 70),
                        const FlSpot(4, 65),
                        const FlSpot(5, 85),
                        const FlSpot(6, 75),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectProgress() {
    final subjects = [
      {'name': 'Math', 'progress': 0.75},
      {'name': 'Physics', 'progress': 0.60},
      {'name': 'Chemistry', 'progress': 0.85},
      {'name': 'Biology', 'progress': 0.45},
    ];

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
            ...subjects.map((subject) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(subject['name'] as String),
                        ),
                        Expanded(
                          flex: 8,
                          child: LinearProgressIndicator(
                            value: subject['progress'] as double,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                            '${((subject['progress'] as double) * 100).toInt()}%'),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                )),
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
          Icons.download,
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
          Icons.calendar_today,
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
          'Discord',
          Icons.chat,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DiscordScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, VoidCallback onTap) {
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
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
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
