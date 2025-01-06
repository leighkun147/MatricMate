enum StreamType {
  naturalScience,
  socialScience,
}

class StreamUtils {
  static StreamType? selectedStream;

  static List<String> getSubjects() {
    switch (selectedStream) {
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
          'English',
          'Aptitude(SAT)',
          'Economics',
          'Geography',
          'History',
          'Math (Social Science)',
        ];
      default:
        return [];
    }
  }
}
