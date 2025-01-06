import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _entries = _getDummyData();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getDummyData() {
    return List.generate(
      20,
      (index) => {
        'name': 'Student ${index + 1}',
        'rank': index + 1,
        'points': 5000 - (index * 200),
        'level': 20 - index,
      },
    );
  }

  String _getMotivationalMessage() {
    if (_userRank <= 3) return "Incredible work! Keep defending your position! 🏆";
    if (_userRank <= 5) return "You're so close to the top 3! Keep pushing! 🚀";
    if (_userRank <= 10) return "Top 10 achievement! The podium awaits you! 💪";
    return "Keep climbing, the top spot is within reach! 🎯";
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
        child: RefreshIndicator(
          onRefresh: _loadLeaderboard,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _getMotivationalMessage(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn().scale(),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildTopThree(),
                    Divider(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
                      height: 32,
                      thickness: 2,
                    ),
                    ..._entries.skip(3).map(_buildRankListItem),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopThree() {
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
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
