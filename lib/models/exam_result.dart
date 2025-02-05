class ExamResult {
  final String examId;
  final String examHash; // Hash of exam content to identify unique exams
  final String title;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercentage;
  final DateTime takenAt;
  final Map<String, String> userAnswers;

  ExamResult({
    required this.examId,
    required this.examHash,
    required this.title,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.takenAt,
    required this.userAnswers,
  });

  Map<String, dynamic> toJson() {
    return {
      'examId': examId,
      'examHash': examHash,
      'title': title,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'scorePercentage': scorePercentage,
      'takenAt': takenAt.toIso8601String(),
      'userAnswers': userAnswers,
    };
  }

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      examId: json['examId'] as String,
      examHash: json['examHash'] as String? ?? json['examId'] as String, // Fallback for old results
      title: json['title'] as String,
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      scorePercentage: json['scorePercentage'] as double,
      takenAt: DateTime.parse(json['takenAt'] as String),
      userAnswers: Map<String, String>.from(json['userAnswers'] as Map),
    );
  }
}
