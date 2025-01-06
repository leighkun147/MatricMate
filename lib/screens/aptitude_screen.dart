import 'package:flutter/material.dart';
import '../models/aptitude_section.dart';
import '../models/exam.dart';
import '../models/question.dart';
import '../screens/practice_mode_screen.dart';
import '../screens/mock_exam_screen.dart';

class AptitudeScreen extends StatefulWidget {
  const AptitudeScreen({Key? key}) : super(key: key);

  @override
  State<AptitudeScreen> createState() => _AptitudeScreenState();
}

class _AptitudeScreenState extends State<AptitudeScreen> {
  final Map<String, bool> _completionStatus = {};

  @override
  void initState() {
    super.initState();
    for (var section in aptitudeSections) {
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
                      'Aptitude (SAT)',
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
                  itemCount: aptitudeSections.length,
                  itemBuilder: (context, index) {
                    final section = aptitudeSections[index];
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
                                      section.title == 'Mathematics' 
                                          ? Icons.functions 
                                          : Icons.menu_book,
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
                                                  id: 'practice_aptitude_${section.title}',
                                                  title: '${section.title} Practice',
                                                  subject: 'Aptitude',
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
                                                  id: 'mock_aptitude_${section.title}',
                                                  title: '${section.title} Mock Exam',
                                                  subject: 'Aptitude',
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
    if (sectionTitle == 'Mathematics') {
      return [
        Question(
          id: 'apt_math_1',
          text: 'If x + 2 = 5, what is the value of x?',
          options: ['2', '3', '4', '7'],
          correctOptionIndex: 1,
          explanation: 'To find x, subtract 2 from both sides: x = 5 - 2 = 3',
        ),
        Question(
          id: 'apt_math_2',
          text: 'What is 15% of 200?',
          options: ['20', '25', '30', '35'],
          correctOptionIndex: 2,
          explanation: '15% of 200 = (15/100) × 200 = 30',
        ),
      ];
    } else {
      return [
        Question(
          id: 'apt_verb_1',
          text: 'Which of these shows the best logical reasoning?',
          options: [
            'All birds can fly. Penguins are birds. Therefore, penguins can fly.',
            'All squares are rectangles. All rectangles have four sides. Therefore, all squares have four sides.',
            'Some cats are black. Some dogs are black. Therefore, some cats are dogs.',
            'It rained yesterday. The ground is wet today. Therefore, it must have rained today.'
          ],
          correctOptionIndex: 1,
          explanation: 'The second option shows valid logical reasoning using transitive property.',
        ),
        Question(
          id: 'apt_verb_2',
          text: 'Complete the sequence: 2, 4, 8, 16, __',
          options: ['20', '24', '32', '64'],
          correctOptionIndex: 2,
          explanation: 'Each number is doubled to get the next number. So, 16 × 2 = 32',
        ),
      ];
    }
  }
}
