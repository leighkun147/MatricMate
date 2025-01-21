import 'question.dart';

class Exam {
  final String id;
  final String title;
  final String subject;
  final int year;
  final Duration duration;
  final List<Question> questions;
  final double? lastScore;
  final int? questionsAttempted;
  final Map<String, dynamic>? constants;
  Exam({
    required this.id,
    required this.title,
    required this.subject,
    required this.year,
    required this.duration,
    required this.questions,
    this.constants,
    this.lastScore,
    this.questionsAttempted,
  });
}
