import 'package:flutter/material.dart';
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
  final Map<String, bool> _completionStatus = {};

  @override
  void initState() {
    super.initState();
    for (var section in englishSections) {
      _completionStatus[section.title] = false;
    }
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
                      height: 260, // Increased height for better visibility
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
                                      section.title == 'Grammar' 
                                          ? Icons.spellcheck
                                          : section.title == 'Reading Comprehension'
                                              ? Icons.menu_book
                                              : Icons.record_voice_over,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        section.title,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                    Checkbox(
                                      value: _completionStatus[section.title],
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _completionStatus[section.title] = value ?? false;
                                        });
                                        _showCompletionDialog(section.title, value ?? false);
                                      },
                                      activeColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  section.description,
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
                                    children: section.topics.map((topic) {
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
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PracticeModeScreen(
                                                exam: Exam(
                                                  id: 'practice_english_${section.title}',
                                                  title: '${section.title} Practice',
                                                  subject: 'English',
                                                  year: DateTime.now().year,
                                                  questions: _getDummyQuestions(section.title),
                                                  duration: const Duration(minutes: 30),
                                                ),
                                              ),
                                            ),
                                          );
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
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MockExamScreen(
                                                exam: Exam(
                                                  id: 'mock_english_${section.title}',
                                                  title: '${section.title} Mock Exam',
                                                  subject: 'English',
                                                  year: DateTime.now().year,
                                                  questions: _getDummyQuestions(section.title),
                                                  duration: const Duration(minutes: 60),
                                                ),
                                              ),
                                            ),
                                          );
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

  List<Question> _getDummyQuestions(String sectionTitle) {
    if (sectionTitle == 'Grammar') {
      return [
        Question(
          id: 'eng_gram_1',
          text: 'Which sentence is grammatically correct?',
          options: [
            'She don\'t like coffee.',
            'She doesn\'t like coffee.',
            'She not like coffee.',
            'She do not likes coffee.'
          ],
          correctOptionIndex: 1,
          explanation: '"Doesn\'t" is the correct form for third-person singular negative.',
        ),
        Question(
          id: 'eng_gram_2',
          text: 'Choose the correct past participle:',
          options: ['wrote', 'written', 'writed', 'writing'],
          correctOptionIndex: 1,
          explanation: '"Written" is the correct past participle of "write".',
        ),
      ];
    } else if (sectionTitle == 'Reading Comprehension') {
      return [
        Question(
          id: 'eng_read_1',
          text: 'What is the main purpose of a topic sentence?',
          options: [
            'To conclude a paragraph',
            'To provide evidence',
            'To introduce the main idea',
            'To transition between ideas'
          ],
          correctOptionIndex: 2,
          explanation: 'A topic sentence introduces the main idea of a paragraph.',
        ),
        Question(
          id: 'eng_read_2',
          text: 'What is inference in reading?',
          options: [
            'Direct statement of facts',
            'Drawing conclusions from evidence',
            'Summarizing the text',
            'Finding vocabulary words'
          ],
          correctOptionIndex: 1,
          explanation: 'Inference involves drawing conclusions based on evidence and context clues.',
        ),
      ];
    } else {
      return [
        Question(
          id: 'eng_voc_1',
          text: 'What is a synonym for "happy"?',
          options: ['sad', 'joyful', 'angry', 'tired'],
          correctOptionIndex: 1,
          explanation: '"Joyful" means the same as "happy".',
        ),
        Question(
          id: 'eng_voc_2',
          text: 'Choose the correct antonym for "bright":',
          options: ['dim', 'light', 'shiny', 'clear'],
          correctOptionIndex: 0,
          explanation: '"Dim" is the opposite of "bright".',
        ),
      ];
    }
  }
}
