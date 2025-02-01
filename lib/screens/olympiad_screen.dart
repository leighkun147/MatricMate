import 'package:flutter/material.dart';
import '../utils/pattern_painters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'your_olympiad_screen.dart';

class OlympiadScreen extends StatefulWidget {
  const OlympiadScreen({super.key});

  @override
  State<OlympiadScreen> createState() => _OlympiadScreenState();
}

class _OlympiadScreenState extends State<OlympiadScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Stream<List<DocumentSnapshot>> _getOlympiadEvents() {
    return FirebaseFirestore.instance
        .collection('Olympiad')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Widget _buildEventCards(BuildContext context, List<DocumentSnapshot> events) {
    return Column(
      children: events.map((event) {
        final data = event.data() as Map<String, dynamic>;
        
        // Debug prints
        print('Raw date from Firestore: ${data['date']}');
        print('Date type: ${data['date']?.runtimeType}');
        
        // Debug prints for all fields
        print('Document ID: ${event.id}');
        print('All fields in document:');
        data.forEach((key, value) {
          print('Field: $key = $value (${value?.runtimeType})');
        });
        
        // Find the date field (handling spaces in field name)
        String formattedDate = 'Date TBA';
        final dateField = data.entries
            .firstWhere(
              (entry) => entry.key.trim() == 'date',
              orElse: () => MapEntry('', null),
            )
            .value;
        
        if (dateField != null) {
          try {
            if (dateField is Timestamp) {
              final date = dateField.toDate();
              formattedDate = "${date.day} ${_getMonth(date.month)}, ${date.year}";
              print('Converted timestamp date: $formattedDate');
            } else if (dateField is String) {
              // Try to parse the string date
              final date = DateTime.parse(dateField);
              formattedDate = "${date.day} ${_getMonth(date.month)}, ${date.year}";
              print('Converted string date: $formattedDate');
            } else {
              print('Unknown date format: $dateField');
            }
          } catch (e) {
            print('Error formatting date: $e');
            formattedDate = dateField.toString();
          }
        }

        // Get registration status
        final registrationStatus = (data['registration_status'] as String?)?.toLowerCase() ?? 'closed';

        return _buildEventCard(
          context: context,
          title: event.id,
          date: formattedDate,
          time: data['time'] ?? '9:00 AM - 5:00 PM',
          venue: data['venue'] ?? 'Venue TBA',
          subjects: List<String>.from(data['subjects'] ?? []),
          registrationDeadline: data['Registration_deadline'] ?? 'Deadline TBA',
          registrationStatus: registrationStatus,
        );
      }).toList(),
    );
  }

  String _getMonth(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildEventCard({
    required BuildContext context,
    required String title,
    required String date,
    required String time,
    required String venue,
    required List<String> subjects,
    required String registrationDeadline,
    required String registrationStatus,
  }) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Event details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    context,
                    Icons.calendar_today,
                    'Date',
                    date,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    Icons.access_time,
                    'Time',
                    time,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    Icons.location_on,
                    'Venue',
                    venue,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Subjects',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subjects.map((subject) => Chip(
                      label: Text(subject),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registration Deadline',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                registrationDeadline,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: registrationStatus == 'open' 
                          ? () {
                              // TODO: Implement registration
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Registration process will start soon!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          : null, // Button will be disabled if registration is closed
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // Change button color based on status
                        backgroundColor: registrationStatus == 'open' 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      icon: Icon(
                        registrationStatus == 'open' 
                            ? Icons.app_registration
                            : Icons.lock_outline,
                      ),
                      label: Text(
                        registrationStatus == 'open' 
                            ? (title == 'Natural Science' ? 'Register Now' : 'Coming Soon')
                            : 'Registration Closed',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
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
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('MatricMate Olympiad'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: DiagonalPatternPainter(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Available Events'),
                Tab(text: 'Your Olympiad'),
              ],
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Available Events Tab
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Upcoming Events',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          StreamBuilder<List<DocumentSnapshot>>(
                            stream: _getOlympiadEvents(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              }

                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text('No events found'),
                                );
                              }

                              return _buildEventCards(context, snapshot.data!);
                            },
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
                // Your Olympiad Tab
                const YourOlympiadScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
