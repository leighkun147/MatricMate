import 'package:cloud_firestore/cloud_firestore.dart';

class ExamHistory {
  final String examId;
  final String subject;
  final String title;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercentage;
  final DateTime takenAt;

  ExamHistory({
    required this.examId,
    required this.subject,
    required this.title,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercentage,
    required this.takenAt,
  });

  factory ExamHistory.fromMap(Map<String, dynamic> map) {
    return ExamHistory(
      examId: map['exam_id'] ?? '',
      subject: map['subject'] ?? '',
      title: map['title'] ?? '',
      totalQuestions: map['total_questions'] ?? 0,
      correctAnswers: map['correct_answers'] ?? 0,
      scorePercentage: (map['score_percentage'] ?? 0.0).toDouble(),
      takenAt: (map['taken_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exam_id': examId,
      'subject': subject,
      'title': title,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'score_percentage': scorePercentage,
      'taken_at': Timestamp.fromDate(takenAt),
    };
  }
}
