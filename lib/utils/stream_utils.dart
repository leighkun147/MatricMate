import 'package:shared_preferences/shared_preferences.dart';

enum StreamType {
  naturalScience,
  socialScience,
}

class StreamUtils {
  static const String _streamKey = 'selected_stream';

  static Future<StreamType?> get selectedStream async {
    final prefs = await SharedPreferences.getInstance();
    final savedStream = prefs.getString(_streamKey);
    if (savedStream != null) {
      return StreamType.values.firstWhere(
        (type) => type.toString() == savedStream,
        orElse: () => StreamType.naturalScience,
      );
    }
    return null;
  }

  static Future<void> setSelectedStream(StreamType? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value != null) {
      await prefs.setString(_streamKey, value.toString());
    } else {
      await prefs.remove(_streamKey);
    }
  }

  static Future<List<String>> getSubjects() async {
    final stream = await selectedStream;
    switch (stream) {
      case StreamType.naturalScience:
        return [
          'Mathematics',
          'Physics',
          'Chemistry',
          'Biology',
          'English',
          'Aptitude',
        ];
      case StreamType.socialScience:
        return [
          'Mathematics',
          'English',
          'Geography',
          'History',
          'Economics',
          'Aptitude',
        ];
      default:
        return [];
    }
  }
}
