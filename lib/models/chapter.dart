class Chapter {
  final String title;
  final int grade;
  final bool isCompleted;

  Chapter({
    required this.title,
    required this.grade,
    this.isCompleted = false,
  });
}

class GradeChapters {
  final int grade;
  final List<Chapter> chapters;

  GradeChapters({
    required this.grade,
    required this.chapters,
  });
}
