class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  bool isAnswered;
  bool isMarkedForReview;
  int? selectedOptionIndex;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.isAnswered = false,
    this.isMarkedForReview = false,
    this.selectedOptionIndex,
  });

  bool get isCorrect => 
    isAnswered && selectedOptionIndex == correctOptionIndex;
}
