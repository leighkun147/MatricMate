class AptitudeSection {
  final String title;
  final String description;
  final List<String> topics;

  AptitudeSection({
    required this.title,
    required this.description,
    required this.topics,
  });
}

final List<AptitudeSection> aptitudeSections = [
  AptitudeSection(
    title: 'Mathematics',
    description: 'Practice mathematical concepts and problem-solving skills',
    topics: [
      'Algebra',
      'Geometry',
      'Arithmetic',
      'Data Analysis',
      'Quantitative Comparison',
      'Word Problems',
      'Functions and Graphs',
    ],
  ),
  AptitudeSection(
    title: 'Reading and Verbal',
    description: 'Enhance your reading comprehension and verbal reasoning abilities',
    topics: [
      'Critical Reading',
      'Sentence Completion',
      'Reading Comprehension',
      'Text Analysis',
      'Vocabulary',
      'Analogies',
      'Sentence Structure',
    ],
  ),
];
