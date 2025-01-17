import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject.dart';
import '../models/aptitude_section.dart';

class ChapterCompletionManager {
  static const String _keyPrefix = 'chapter_completion_';

  static String _getKey(String subject, String chapterTitle, int grade) {
    return '${_keyPrefix}${subject}_${grade}_$chapterTitle';
  }

  static Future<bool> isChapterCompleted(
    String subject,
    String chapterTitle,
    int grade,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(subject, chapterTitle, grade);
    return prefs.getBool(key) ?? false;
  }

  static Future<void> setChapterCompletion(
    String subject,
    String chapterTitle,
    int grade,
    bool isCompleted,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(subject, chapterTitle, grade);
    await prefs.setBool(key, isCompleted);
  }

  static Future<Map<String, bool>> getCompletionStatusForSubject(
    String subject,
    int grade,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, bool> completionStatus = {};

    final allKeys = prefs.getKeys();
    final subjectPrefix = '${_keyPrefix}${subject}_$grade';

    for (final key in allKeys) {
      if (key.startsWith(subjectPrefix)) {
        final chapterTitle = key.substring(subjectPrefix.length + 1);
        completionStatus[chapterTitle] = prefs.getBool(key) ?? false;
      }
    }

    return completionStatus;
  }

  static Future<double> getSubjectCompletionPercentage(
    String subjectName,
    List<int> grades,
    int totalChapters,
  ) async {
    if (subjectName == 'English') {
      return _getEnglishCompletionPercentage();
    } else if (subjectName == 'Aptitude') {
      return _getAptitudeCompletionPercentage();
    }

    final prefs = await SharedPreferences.getInstance();
    int completedChapters = 0;

    // Get the subject to know its chapters
    Subject? subject;
    if (naturalScienceSubjects.any((s) => s.name == subjectName)) {
      subject = naturalScienceSubjects.firstWhere((s) => s.name == subjectName);
    } else if (socialScienceSubjects.any((s) => s.name == subjectName)) {
      subject = socialScienceSubjects.firstWhere((s) => s.name == subjectName);
    }

    if (subject == null) return 0.0;

    // Count completed chapters for each grade
    for (var grade in grades) {
      if (subject.chapters.containsKey(grade)) {
        for (var chapter in subject.chapters[grade]!) {
          final key = _getKey(subjectName, chapter.title, grade);
          if (prefs.getBool(key) ?? false) {
            completedChapters++;
          }
        }
      }
    }

    // Calculate percentage based on actual total chapters from the subject
    return (completedChapters * 100) / subject.totalChapters;
  }

  static Future<double> _getEnglishCompletionPercentage() async {
    final prefs = await SharedPreferences.getInstance();
    final sections = ['Grammar', 'Communication Skills', 'Reading Comprehension'];
    int completedSections = 0;

    for (var section in sections) {
      if (prefs.getBool('english_${section}_completion') ?? false) {
        completedSections++;
      }
    }

    return (completedSections * 100) / sections.length;
  }

  static Future<double> _getAptitudeCompletionPercentage() async {
    final prefs = await SharedPreferences.getInstance();
    final sections = aptitudeSections.map((section) => section.title).toList();
    int completedSections = 0;

    for (var section in sections) {
      if (prefs.getBool('aptitude_${section}_completion') ?? false) {
        completedSections++;
      }
    }

    return (completedSections * 100) / sections.length;
  }
}
