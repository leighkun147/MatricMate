class EnglishSection {
  final String title;
  final String description;
  final List<String> topics;

  EnglishSection({
    required this.title,
    required this.description,
    required this.topics,
  });
}

final List<EnglishSection> englishSections = [
  EnglishSection(
    title: 'Reading Comprehension',
    description: 'Practice your reading comprehension skills with various text types and question formats',
    topics: [
      'Main Ideas and Details',
      'Author\'s Purpose',
      'Inference and Interpretation',
      'Vocabulary in Context',
      'Text Structure and Organization',
    ],
  ),
  EnglishSection(
    title: 'Grammar',
    description: 'Master essential grammar concepts and rules',
    topics: [
      'Tenses',
      'Voice (Active/Passive)',
      'Reported Speech',
      'Conditionals',
      'Modal Verbs',
      'Prepositions',
      'Articles and Determiners',
    ],
  ),
  EnglishSection(
    title: 'Communication Skills',
    description: 'Develop effective written and verbal communication skills',
    topics: [
      'Essay Writing',
      'Letter Writing',
      'Public Speaking',
      'Presentation Skills',
      'Business Communication',
      'Email Writing',
    ],
  ),
];
