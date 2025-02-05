import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/device_verification_service.dart';
import '../utils/pattern_painters.dart';
import 'olympiad_screen.dart';
import '../services/user_cache_service.dart';
import 'payment_methods_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late List<Map<String, dynamic>> _entries;
  bool _isLoading = true;
  int _userRank = 7; // Current user's rank for motivational messages

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    try {
      // TODO: Implement actual leaderboard data loading from Firebase
      setState(() {
        _entries = [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading leaderboard: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
        child: RefreshIndicator(
          onRefresh: _loadLeaderboard,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                  child: _buildOlympiadCard(),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_entries.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 40),
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 100,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Rankings Available',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Take exams and compete with other students to see your name on the leaderboard!',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                                ),
                          ),
                          const SizedBox(height: 32),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ).animate().fadeIn(duration: 600.ms).scale(),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTopThree(),
                    if (_entries.length > 3) ...[  // Only show divider if there are more entries
                      Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .onBackground
                            .withOpacity(0.2),
                        height: 32,
                        thickness: 2,
                      ),
                      ..._entries.skip(3).map(_buildRankListItem),
                    ],
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleOlympiadAccess() async {
    final premiumLevel = await UserCacheService.getCachedPremiumLevel();

    if (!mounted) return;

    if (premiumLevel.toLowerCase() == 'pro' ||
        premiumLevel.toLowerCase() == 'elite') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OlympiadScreen(),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Premium Access Required'),
          content: const Text(
            'The MatricMate Olympiad is exclusively available for Pro and Elite members. '
            'Upgrade your account to participate in these prestigious academic competitions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentMethodsScreen(),
                  ),
                );
              },
              child: const Text('Upgrade Now'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildOlympiadCard() {
    return GestureDetector(
        onTap: _handleOlympiadAccess,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 8,
            shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DiagonalPatternPainter(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.emoji_events_outlined,
                                color: Colors.white,
                                size: 24,
                              ).animate()
                                .shimmer(duration: 2000.ms),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MatricMate Olympiad',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    'Academic Excellence',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Soon',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildOlympiadStat(
                                icon: Icons.people_outline,
                                value: '1K+',
                                label: 'Students',
                              ),
                              _buildOlympiadStat(
                                icon: Icons.military_tech_outlined,
                                value: '50+',
                                label: 'Prizes',
                              ),
                              _buildOlympiadStat(
                                icon: Icons.school_outlined,
                                value: '10+',
                                label: 'Subjects',
                              ),
                            ],
                          ),
                        ),
                        ],
                      ),
                    ),
                    // Shine effects
                    Positioned(
                      top: -80,
                      right: -80,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                        .fadeIn(duration: 2000.ms)
                        .fadeOut(duration: 2000.ms),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn().scale());
  }

  Widget _buildOlympiadStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
        ),
      ],
    );
  }

  Widget _buildTopThree() {
    if (_entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Rankings Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to take an exam and claim the top spot!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ).animate().fadeIn().scale();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildTopThreeItem(_entries[1], 2), // Second place
          _buildTopThreeItem(_entries[0], 1), // First place
          _buildTopThreeItem(_entries[2], 3), // Third place
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildTopThreeItem(Map<String, dynamic> entry, int position) {
    final isFirst = position == 1;
    final height = isFirst ? 160.0 : 130.0;

    Color getBaseColor() {
      switch (position) {
        case 1:
          return Colors.amber;
        case 2:
          return Colors.blueAccent;
        default:
          return Colors.green;
      }
    }

    return Container(
      height: height,
      width: isFirst ? 120.0 : 100.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            getBaseColor().withOpacity(0.8),
            getBaseColor().withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: getBaseColor().withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isFirst)
            const Text('👑', style: TextStyle(fontSize: 32))
                .animate()
                .shimmer(duration: 2000.ms, delay: 500.ms),
          Text(
            position == 1
                ? '🥇'
                : position == 2
                    ? '🥈'
                    : '🥉',
            style: TextStyle(fontSize: isFirst ? 28 : 24),
          ),
          const SizedBox(height: 8),
          Text(
            entry['name'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isFirst ? 18 : 16,
              color: Theme.of(context).colorScheme.onPrimary,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '${entry['points']} pts',
            style: TextStyle(
              fontSize: isFirst ? 16 : 14,
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankListItem(Map<String, dynamic> entry) {
    final isCurrentUser = entry['rank'] == _userRank;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: Theme.of(context).colorScheme.primary)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Text(
            '#${entry['rank']}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          entry['name'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry['points']} pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  'Level ${entry['level']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.star,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }
}
