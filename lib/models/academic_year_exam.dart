import '../models/question.dart';

class AcademicYearExam {
  final String subject;
  final int year;
  final int duration;
  final int numberOfQuestions;
  final List<Question> questions;
  final String? title;
  final Map<String, dynamic>? constants;

  AcademicYearExam({
    required this.subject,
    required this.year,
    required this.duration,
    required this.numberOfQuestions,
    required this.questions,
    required this.title,
    this.constants,
  });

  factory AcademicYearExam.fromJson(Map<String, dynamic> json, {String? subject, int? year}) {
    try {
      return AcademicYearExam(
        subject: subject ?? json['subject'] ?? 'Unknown Subject',
        year: year ?? json['year'] ?? DateTime.now().year,
        duration: (json['duration'] ?? 60).toInt(),
        numberOfQuestions: (json['numberOfQuestions'] ?? 0).toInt(),
        title: json['title'] ?? 'Untitled Exam',
        constants: json['constants'] != null ? Map<String, dynamic>.from(json['constants']) : null,
        questions: (json['questions'] as List)
            .map((q) => Question(
                  id: q['id'] ?? '',
                  text: q['text'] ?? '',
                  options: List<String>.from(q['options'] ?? []),
                  correctOptionIndex: (q['correctOptionIndex'] ?? 0).toInt(),
                  explanation: q['explanation'] ?? '',
                ))
            .toList(),
      );
    } catch (e, stackTrace) {
      print('Error parsing JSON for ${subject ?? "Unknown"} exam: $e\nStack trace: $stackTrace');
      rethrow;
    }
  }
}
