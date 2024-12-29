class Subject {
  final String name;
  final String iconPath;
  final String route;

  Subject({
    required this.name,
    required this.iconPath,
    required this.route,
  });
}

final List<Subject> subjects = [
  Subject(
    name: 'Math (Natural)',
    iconPath: 'assets/icons/math_natural.svg',
    route: '/math_natural',
  ),
  Subject(
    name: 'Physics',
    iconPath: 'assets/icons/physics.svg',
    route: '/physics',
  ),
  Subject(
    name: 'Chemistry',
    iconPath: 'assets/icons/chemistry.svg',
    route: '/chemistry',
  ),
  Subject(
    name: 'Biology',
    iconPath: 'assets/icons/biology.svg',
    route: '/biology',
  ),
  Subject(
    name: 'English',
    iconPath: 'assets/icons/english.svg',
    route: '/english',
  ),
  Subject(
    name: 'Aptitude',
    iconPath: 'assets/icons/aptitude.svg',
    route: '/aptitude',
  ),
  Subject(
    name: 'Civics',
    iconPath: 'assets/icons/civics.svg',
    route: '/civics',
  ),
  Subject(
    name: 'Economics',
    iconPath: 'assets/icons/economics.svg',
    route: '/economics',
  ),
  Subject(
    name: 'Geography',
    iconPath: 'assets/icons/geography.svg',
    route: '/geography',
  ),
  Subject(
    name: 'History',
    iconPath: 'assets/icons/history.svg',
    route: '/history',
  ),
  Subject(
    name: 'Math (Social)',
    iconPath: 'assets/icons/math_social.svg',
    route: '/math_social',
  ),
];
