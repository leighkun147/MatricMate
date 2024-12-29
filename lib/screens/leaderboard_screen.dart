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
              Colors.grey[900]!,
              Colors.grey[850]!,
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
                        colors: [Colors.blue[700]!, Colors.blue[900]!],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _getMotivationalMessage(),
                      style: const TextStyle(
                        color: Colors.white,
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
                    const Divider(
                      color: Colors.white24,
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

    return Container(
      height: height,
      width: isFirst ? 120.0 : 100.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            if (position == 1) ...[Colors.amber[400]!, Colors.orange[600]!]
            else if (position == 2) ...[Colors.blueAccent[100]!, Colors.blue[400]!]
            else ...[Colors.green[400]!, Colors.green[600]!],
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (position == 1)
                ? Colors.amber.withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
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
              color: Colors.white,
              shadows: [
                const Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
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
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankListItem(Map<String, dynamic> entry) {
    final rank = entry['rank'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[800]!,
            Colors.grey[850]!,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Text(
              entry['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (rank <= 10) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'TOP 10',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '#${entry['rank']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rank <= 10 ? Colors.blue[300] : Colors.white70,
                fontSize: 18,
              ),
            ),
            Text(
              '${entry['points']} pts',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2, duration: 200.ms);
  }
}
