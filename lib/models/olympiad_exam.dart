import 'dart:convert';

class OlympiadExam {
  final String title;
  final int duration;
  final Map<String, dynamic> constants;
  final int numberOfQuestions;
  final List<Question> questions;

  OlympiadExam({
    required this.title,
    required this.duration,
    required this.constants,
    required this.numberOfQuestions,
    required this.questions,
  });

  factory OlympiadExam.fromJson(Map<String, dynamic> json) {
    return OlympiadExam(
      title: json['title'] as String,
      duration: json['duration'] as int,
      constants: json['constants'] as Map<String, dynamic>,
      numberOfQuestions: json['numberOfQuestions'] as int,
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }

  factory OlympiadExam.fromFile(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return OlympiadExam.fromJson(json);
  }
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      options: (json['options'] as List).map((e) => e as String).toList(),
      correctOptionIndex: json['correctOptionIndex'] as int,
      explanation: json['explanation'] as String,
    );
  }
}
