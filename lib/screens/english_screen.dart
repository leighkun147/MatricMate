import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/english_section.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../screens/practice_mode_screen.dart';
import '../screens/mock_exam_screen.dart';

class EnglishScreen extends StatefulWidget {
  const EnglishScreen({Key? key}) : super(key: key);

  @override
  State<EnglishScreen> createState() => _EnglishScreenState();
}

class _EnglishScreenState extends State<EnglishScreen> {
  final List<Map<String, dynamic>> englishSections = [
    {
      'title': 'Grammar',
      'description': 'Practice grammar rules, tenses, and sentence structures',
      'icon': Icons.spellcheck,
      'isDisabled': false,
      'jsonFile': 'Grammar.json',
    },
    {
      'title': 'Communication Skills',
      'description': 'Improve your verbal and written communication abilities',
      'icon': Icons.record_voice_over,
      'isDisabled': false,
      'jsonFile': 'Communication Skills.json',
    },
    {
      'title': 'Reading Comprehension',
      'description': 'Enhance your reading and understanding capabilities',
      'icon': Icons.menu_book,
      'isDisabled': true, // Disabled as requested
      'jsonFile': null,
    },
  ];

  final Map<String, bool> _completionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadCompletionStatus();
  }

  Future<void> _loadCompletionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var section in englishSections) {
        final status = prefs.getBool('english_${section['title']}_completion') ?? false;
        _completionStatus[section['title']] = status;
      }
    });
  }

  Future<void> _saveCompletionStatus(String sectionTitle, bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('english_${sectionTitle}_completion', status);
    setState(() {
      _completionStatus[sectionTitle] = status;
    });
  }

  void _showCompletionDialog(String sectionTitle, bool isCompleted) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isCompleted ? 'Section Marked as Complete' : 'Section Marked as Incomplete',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            isCompleted
                ? 'You have marked $sectionTitle as completed. Keep up the good work!'
                : 'You have marked $sectionTitle as incomplete. Take your time to master it!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Question>> _loadQuestions(String jsonFileName) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/questions/subject_chapters_questions/$jsonFileName',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> questionsJson = jsonData['questions'];
      
      return questionsJson.map((q) => Question(
        id: q['id'],
        text: q['text'],
        options: List<String>.from(q['options']),
        correctOptionIndex: q['correctOptionIndex'],
        explanation: q['explanation'],
      )).toList();
    } catch (e) {
      print('Error loading questions from $jsonFileName: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'English',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: englishSections.length,
                  itemBuilder: (context, index) {
                    final section = englishSections[index];
                    return SizedBox(
                      height: 330, // Increased height for better visibility
                      child: Opacity(
                        opacity: section['isDisabled'] ? 0.5 : 1.0,
                        child: Card(
                          elevation: 4, // Added elevation for better visual appeal
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              // TODO: Navigate to section details
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(20), // Increased padding
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        section['icon'],
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          section['title'],
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                        ),
                                      ),
                                      Checkbox(
                                        value: _completionStatus[section['title']],
                                        onChanged: (bool? value) {
                                          _saveCompletionStatus(section['title'], value ?? false);
                                          _showCompletionDialog(section['title'], value ?? false);
                                        },
                                        activeColor: Theme.of(context).colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    section['description'],
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: GridView.count(
                                      crossAxisCount: 2,
                                      childAspectRatio: 4,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      children: section['title'] == 'Grammar' ? [
                                        _buildTopicContainer(context, 'Reported Speech'),
                                        _buildTopicContainer(context, 'Tenses'),
                                        _buildTopicContainer(context, 'Conditional Sentences'),
                                        _buildTopicContainer(context, 'Active and Passive Voice'),
                                        _buildTopicContainer(context, 'Modals and Auxiliaries'),
                                        _buildTopicContainer(context, 'Articles'),
                                        _buildTopicContainer(context, 'Parts of Speech'),
                                        _buildTopicContainer(context, 'Punctuation'),
                                        _buildTopicContainer(context, 'Clauses and Sentence Structure'),
                                        _buildTopicContainer(context, 'Subject-Verb Agreement'),
                                        _buildTopicContainer(context, 'Pronouns'),
                                        _buildTopicContainer(context, 'Word Order'),
                                        _buildTopicContainer(context, 'Comparatives and Superlatives'),
                                        _buildTopicContainer(context, 'Gerunds and Infinitives'),
                                      ] : section['title'] == 'Communication Skills' ? [
                                        _buildTopicContainer(context, 'Conversational Skills'),
                                        _buildTopicContainer(context, 'Effective Questioning'),
                                        _buildTopicContainer(context, 'Speaking Skills'),
                                        _buildTopicContainer(context, 'Interpersonal Communication'),
                                      ] : [
                                        _buildTopicContainer(context, 'Topic 1'),
                                        _buildTopicContainer(context, 'Topic 2'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: section['isDisabled']
                                              ? null
                                              : () async {
                                                  final questions = await _loadQuestions(section['jsonFile']);
                                                  if (questions.isNotEmpty && mounted) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => PracticeModeScreen(
                                                          exam: Exam(
                                                            id: 'practice_english_${section['title']}',
                                                            title: '${section['title']} Practice',
                                                            subject: 'English',
                                                            year: DateTime.now().year,
                                                            questions: questions,
                                                            duration: const Duration(minutes: 30),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          icon: const Icon(Icons.school, size: 18),
                                          label: const Text('Practice'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.primary,
                                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: section['isDisabled']
                                              ? null
                                              : () async {
                                                  final questions = await _loadQuestions(section['jsonFile']);
                                                  if (questions.isNotEmpty && mounted) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => MockExamScreen(
                                                          exam: Exam(
                                                            id: 'mock_english_${section['title']}',
                                                            title: '${section['title']} Mock Exam',
                                                            subject: 'English',
                                                            year: DateTime.now().year,
                                                            questions: questions,
                                                            duration: const Duration(minutes: 60),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          icon: const Icon(Icons.timer, size: 18),
                                          label: const Text('Mock'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.secondary,
                                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicContainer(BuildContext context, String topic) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              topic,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
