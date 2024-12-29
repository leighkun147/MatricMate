class LeaderboardEntry {
  final String id;
  final String name;
  final String avatarUrl;
  final int rank;
  final int points;
  final List<String> badges;
  final int weeklyProgress;
  final int level;
  final String school;
  final Map<String, int> subjectScores;
  final int streak;

  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.rank,
    required this.points,
    required this.badges,
    required this.weeklyProgress,
    required this.level,
    required this.school,
    required this.subjectScores,
    required this.streak,
  });

  // Calculate the points needed for next rank
  int get pointsToNextRank {
    const rankThresholds = [1000, 2000, 3000, 4000, 5000];
    for (final threshold in rankThresholds) {
      if (points < threshold) {
        return threshold - points;
      }
    }
    return 0;
  }

  // Calculate progress percentage to next rank
  double get progressToNextRank {
    if (pointsToNextRank == 0) return 100;
    const rankSize = 1000;
    return ((rankSize - pointsToNextRank) / rankSize * 100).clamp(0, 100);
  }

  String get rankBadge {
    if (rank == 1) return '👑';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '';
  }

  String get levelTitle {
    if (level >= 20) return 'Expert';
    if (level >= 15) return 'Master';
    if (level >= 10) return 'Advanced';
    if (level >= 5) return 'Intermediate';
    return 'Beginner';
  }
}
