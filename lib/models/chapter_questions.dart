import '/models/question.dart';

class ChapterQuestions {
  final String title;
  final int duration;
  final int numberOfQuestions;
  final List<Question> questions;
  final Map<String, dynamic>? constants;

  ChapterQuestions({
    required this.title,
    required this.duration,
    required this.numberOfQuestions,
    required this.questions,
    this.constants,
  });

  factory ChapterQuestions.fromJson(Map<String, dynamic> json) {
    return ChapterQuestions(
      title: json['title'],
      duration: json['duration'],
      numberOfQuestions: json['numberOfQuestions'],
      constants: json['constants'] != null ? Map<String, dynamic>.from(json['constants']) : null,
      questions: (json['questions'] as List)
          .map((q) => Question(
                id: q['id'],
                text: q['text'],
                options: List<String>.from(q['options']),
                correctOptionIndex: q['correctOptionIndex'],
                explanation: q['explanation'],
              ))
          .toList(),
    );
  }
}
