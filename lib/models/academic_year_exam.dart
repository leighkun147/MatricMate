import '../models/question.dart';

class AcademicYearExam {
  final String subject;
  final int year;
  final int duration;
  final int numberOfQuestions;
  final List<Question> questions;
  final String? title;

  AcademicYearExam({
    required this.subject,
    required this.year,
    required this.duration,
    required this.numberOfQuestions,
    required this.questions,
    this.title,
  });

  factory AcademicYearExam.fromJson(Map<String, dynamic> json, {String? subject, int? year}) {
    return AcademicYearExam(
      subject: subject ?? json['subject'] ?? 'Unknown Subject',
      year: year ?? json['year'] ?? DateTime.now().year,
      duration: json['duration'] ?? 60,
      numberOfQuestions: json['numberOfQuestions'] ?? 0,
      title: json['title'],
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
