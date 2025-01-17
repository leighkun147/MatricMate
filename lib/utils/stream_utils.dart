import 'package:shared_preferences/shared_preferences.dart';

enum StreamType {
  naturalScience,
  socialScience,
}

class StreamUtils {
  static StreamType? _selectedStream;
  static const String _streamKey = 'selected_stream';

  static StreamType? get selectedStream => _selectedStream;

  static set selectedStream(StreamType? value) {
    _selectedStream = value;
    _saveStream();
  }

  static Future<void> loadSavedStream() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStream = prefs.getString(_streamKey);
    if (savedStream != null) {
      _selectedStream = StreamType.values.firstWhere(
        (type) => type.toString() == savedStream,
        orElse: () => StreamType.naturalScience,
      );
    }
  }

  static Future<void> _saveStream() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedStream != null) {
      await prefs.setString(_streamKey, _selectedStream.toString());
    }
  }

  static List<String> getSubjects() {
    switch (_selectedStream) {
      case StreamType.naturalScience:
        return [
          'Math (Natural Science)',
          'Physics',
          'Chemistry',
          'Biology',
          'English',
          'Aptitude(SAT)',
        ];
      case StreamType.socialScience:
        return [
          'Math (Social Science)',
          'English',
          'Aptitude(SAT)',
          'Economics',
          'Geography',
          'History',
        ];
      default:
        return [];
    }
  }
}
