import 'chapter.dart';

class Subject {
  final String name;
  final String iconPath;
  final String route;
  final Map<int, List<Chapter>> chapters;

  Subject({
    required this.name,
    required this.iconPath,
    required this.route,
    required this.chapters,
  });

  int get totalChapters {
    int total = 0;
    for (var chaptersList in chapters.values) {
      total += chaptersList.length;
    }
    return total;
  }
}

// Common subjects for both streams
Subject getEnglishSubject() {
  return Subject(
    name: 'English',
    iconPath: 'assets/icons/english.svg',
    route: '/english',
    chapters: {}, // English uses a different structure
  );
}

Subject getAptitudeSubject() {
  return Subject(
    name: 'Aptitude',
    iconPath: 'assets/icons/aptitude.svg',
    route: '/aptitude',
    chapters: {}, // Aptitude uses a different structure
  );
}

// Natural Science Subjects
final List<Subject> naturalScienceSubjects = [
  Subject(
    name: 'Mathematics',
    iconPath: 'assets/icons/math.svg',
    route: '/math_natural',
    chapters: getMathNaturalChapters(),
  ),
  Subject(
    name: 'Physics',
    iconPath: 'assets/icons/physics.svg',
    route: '/physics',
    chapters: getPhysicsChapters(),
  ),
  Subject(
    name: 'Chemistry',
    iconPath: 'assets/icons/chemistry.svg',
    route: '/chemistry',
    chapters: getChemistryChapters(),
  ),
  Subject(
    name: 'Biology',
    iconPath: 'assets/icons/biology.svg',
    route: '/biology',
    chapters: getBiologyChapters(),
  ),
  getEnglishSubject(), // Add English
  getAptitudeSubject(), // Add Aptitude
];

// Social Science Subjects
final List<Subject> socialScienceSubjects = [
  Subject(
    name: 'Mathematics',
    iconPath: 'assets/icons/math_social.svg',
    route: '/math_social',
    chapters: getMathSocialScienceChapters(),
  ),
  Subject(
    name: 'Economics',
    iconPath: 'assets/icons/economics.svg',
    route: '/economics',
    chapters: getEconomicsChapters(),
  ),
  Subject(
    name: 'Geography',
    iconPath: 'assets/icons/geography.svg',
    route: '/geography',
    chapters: getGeographyChapters(),
  ),
  Subject(
    name: 'History',
    iconPath: 'assets/icons/history.svg',
    route: '/history',
    chapters: getHistoryChapters(),
  ),
  getEnglishSubject(), // Add English
  getAptitudeSubject(), // Add Aptitude
];

// Chapter data for each subject
Map<int, List<Chapter>> getMathNaturalChapters() {
  return {
    9: [
      Chapter(title: 'Further On Sets', grade: 9),
      Chapter(title: 'The Number System', grade: 9),
      Chapter(title: 'Solving Equations', grade: 9),
      Chapter(title: 'Solving Inequalities', grade: 9),
      Chapter(title: 'Introduction To Trigonometry', grade: 9),
      Chapter(title: 'Regular Polygons', grade: 9),
      Chapter(title: 'Congruency And Similarity', grade: 9),
      Chapter(title: 'Vector In Two Dimensions', grade: 9),
      Chapter(title: 'Statistic And Probability', grade: 9),
    ],
    10: [
      Chapter(title: 'Relations and Functions', grade: 10),
      Chapter(title: 'Polynomial Functions', grade: 10),
      Chapter(title: 'Exponential and Logarithmic Functions', grade: 10),
      Chapter(title: 'Trigonometric Functions', grade: 10),
      Chapter(title: 'Circles', grade: 10),
      Chapter(title: 'Solid Figures', grade: 10),
      Chapter(title: 'Coordinate Geometry', grade: 10),
    ],
    11: [
      Chapter(title: 'Relations and Functions', grade: 11),
      Chapter(title: 'Rational expressions and rational functions', grade: 11),
      Chapter(title: 'Matrices', grade: 11),
      Chapter(title: 'Determinants and their properties', grade: 11),
      Chapter(title: 'Vectors', grade: 11),
      Chapter(title: 'Transformation of the plane', grade: 11),
      Chapter(title: 'Statistics', grade: 11),
      Chapter(title: 'Probability', grade: 11),
    ],
    12: [
      Chapter(title: 'Sequences and Series', grade: 12),
      Chapter(title: 'Introductions to Calculus', grade: 12),
      Chapter(title: 'Statistics', grade: 12),
      Chapter(title: 'Introduction to Linear Programming', grade: 12),
      Chapter(title: 'Mathematical Applications in Business', grade: 12),
    ],
  };
}

Map<int, List<Chapter>> getMathSocialScienceChapters() {
  return {
    9: [
      Chapter(title: 'Further On Sets', grade: 9),
      Chapter(title: 'The Number System', grade: 9),
      Chapter(title: 'Solving Equations', grade: 9),
      Chapter(title: 'Solving Inequalities', grade: 9),
      Chapter(title: 'Introduction To Trigonometry', grade: 9),
      Chapter(title: 'Regular Polygons', grade: 9),
      Chapter(title: 'Congruency And Similarity', grade: 9),
      Chapter(title: 'Vector In Two Dimensions', grade: 9),
      Chapter(title: 'Statistic And Probability', grade: 9),
    ],
    10: [
      Chapter(title: 'Relations and Functions', grade: 10),
      Chapter(title: 'Polynomial Functions', grade: 10),
      Chapter(title: 'Exponential and Logarithmic Functions', grade: 10),
      Chapter(title: 'Trigonometric Functions', grade: 10),
      Chapter(title: 'Circles', grade: 10),
      Chapter(title: 'Solid Figures', grade: 10),
      Chapter(title: 'Coordinate Geometry', grade: 10),
    ],
    11: [
      Chapter(title: 'Relations and Functions', grade: 11),
      Chapter(title: 'Rational Expressions and Rational Functions', grade: 11),
      Chapter(title: 'Matrices', grade: 11),
      Chapter(title: 'Determinants and Their Properties', grade: 11),
      Chapter(title: 'Vectors', grade: 11),
      Chapter(title: 'Transformation of the Plane', grade: 11),
      Chapter(title: 'Statistics', grade: 11),
      Chapter(title: 'Probability', grade: 11),
    ],
    12: [
      Chapter(title: 'Sequences and Series', grade: 12),
      Chapter(title: 'Introductions to Calculus', grade: 12),
      Chapter(title: 'Statistics', grade: 12),
      Chapter(title: 'Introduction to Linear Programming', grade: 12),
      Chapter(title: 'Mathematical Applications in Business', grade: 12),
    ],
  };
}

Map<int, List<Chapter>> getPhysicsChapters() {
  return {
    9: [
      Chapter(title: 'Physics and Human Society', grade: 9),
      Chapter(title: 'Physical Quantity', grade: 9),
      Chapter(title: 'Motion in a Straight Line', grade: 9),
      Chapter(title: 'Force, Work, Energy and Power', grade: 9),
      Chapter(title: 'Simple Machines', grade: 9),
      Chapter(title: 'Mechanical Oscillation and Sound Wave', grade: 9),
      Chapter(title: 'Temperature and Thermometer', grade: 9),
    ],
    10: [
      Chapter(title: 'Vector Quantities', grade: 10),
      Chapter(title: 'Uniformly Accelerated Motion', grade: 10),
      Chapter(title: 'Elasticity and Static Equilibrium of Rigid Body', grade: 10),
      Chapter(title: 'Static and Current Electricity', grade: 10),
      Chapter(title: 'Magnetism', grade: 10),
      Chapter(title: 'Electromagnetic Waves and Geometrical Optics', grade: 10),
    ],
    11: [
      Chapter(title: 'Physics and Human Society', grade: 11),
      Chapter(title: 'Vectors', grade: 11),
      Chapter(title: 'Motion in One and Two Dimensions', grade: 11),
      Chapter(title: 'Dynamics', grade: 11),
      Chapter(title: 'Heat Conduction and Calorimetry', grade: 11),
      Chapter(title: 'Electrostatics and Electric Circuit', grade: 11),
      Chapter(title: 'Nuclear Physics', grade: 11),
    ],
    12: [
      Chapter(title: 'Application of Physics in Other Fields', grade: 12),
      Chapter(title: 'Two-Dimensional Motion', grade: 12),
      Chapter(title: 'Fluid Mechanics', grade: 12),
      Chapter(title: 'Electromagnetism', grade: 12),
      Chapter(title: 'Basics of Electronics', grade: 12),
    ],
  };
}

Map<int, List<Chapter>> getBiologyChapters() {
  return {
    9: [
      Chapter(title: 'Introduction to Biology', grade: 9),
      Chapter(title: 'Characteristics and Classification of Organisms', grade: 9),
      Chapter(title: 'Cells', grade: 9),
      Chapter(title: 'Reproduction', grade: 9),
      Chapter(title: 'Human Health, Nutrition, and Disease', grade: 9),
      Chapter(title: 'Ecology', grade: 9),
    ],
    10: [
      Chapter(title: 'Sub-fields of Biology', grade: 10),
      Chapter(title: 'Plants', grade: 10),
      Chapter(title: 'Biochemical Molecules', grade: 10),
      Chapter(title: 'Cell Reproduction', grade: 10),
      Chapter(title: 'Human Biology', grade: 10),
      Chapter(title: 'Ecological Interaction', grade: 10),
    ],
    11: [
      Chapter(title: 'Biology and Technology', grade: 11),
      Chapter(title: 'Characteristics of Animals', grade: 11),
      Chapter(title: 'Enzymes', grade: 11),
      Chapter(title: 'Genetics', grade: 11),
      Chapter(title: 'The Human Body Systems', grade: 11),
      Chapter(title: 'Population and Natural Resources', grade: 11),
    ],
    12: [
      Chapter(title: 'Application of Biology', grade: 12),
      Chapter(title: 'Applications in Biotechnology', grade: 12),
      Chapter(title: 'Energy Transformation', grade: 12),
      Chapter(title: 'Evolution', grade: 12),
      Chapter(title: 'Human Body Systems', grade: 12),
      Chapter(title: 'Climate Change', grade: 12),
    ],
  };
}

Map<int, List<Chapter>> getChemistryChapters() {
  return {
    9: [
      Chapter(title: 'Chemistry and Its Importance', grade: 9),
      Chapter(title: 'Measurements and Scientific Methods', grade: 9),
      Chapter(title: 'Structure of the Atom', grade: 9),
      Chapter(title: 'Periodic Classification of Elements', grade: 9),
      Chapter(title: 'Chemical Bonding', grade: 9),
    ],
    10: [
      Chapter(title: 'Chemical Reactions and Stoichiometry', grade: 10),
      Chapter(title: 'Solutions', grade: 10),
      Chapter(title: 'Important Inorganic Compounds', grade: 10),
      Chapter(title: 'Energy Changes and Electrochemistry', grade: 10),
      Chapter(title: 'Metals and Nonmetals', grade: 10),
      Chapter(title: 'Hydrocarbons and Their Natural Sources', grade: 10),
    ],
    11: [
      Chapter(title: 'Atomic Structure and Periodic Properties of the Elements', grade: 11),
      Chapter(title: 'Chemical Bonding', grade: 11),
      Chapter(title: 'Physical State of Matters', grade: 11),
      Chapter(title: 'Chemical Kinetics', grade: 11),
      Chapter(title: 'Chemical Equilibrium', grade: 11),
      Chapter(title: 'Some Important Oxygen-Containing Organic Compounds', grade: 11),
    ],
    12: [
      Chapter(title: 'Acid-Base Equilibria', grade: 12),
      Chapter(title: 'Electrochemistry', grade: 12),
      Chapter(title: 'Industrial Chemistry', grade: 12),
      Chapter(title: 'Polymers', grade: 12),
      Chapter(title: 'Introduction to Environmental Chemistry', grade: 12),
    ],
  };
}

Map<int, List<Chapter>> getEconomicsChapters() {
  return {
    9: [
      Chapter(title: 'Introducing Economics', grade: 9),
      Chapter(title: 'The Basic Economic Problems and Economic Systems', grade: 9),
      Chapter(title: 'Economic Resources and Markets', grade: 9),
      Chapter(title: 'Introduction to Demand and Supply', grade: 9),
      Chapter(title: 'Introduction to Production and Cost', grade: 9),
      Chapter(title: 'Introduction to Money', grade: 9),
      Chapter(title: 'Introduction to Macroeconomics', grade: 9),
      Chapter(title: 'Basic Entrepreneurship', grade: 9),
    ],
    10: [
      Chapter(title: 'Theory of Consumer Behaviour', grade: 10),
      Chapter(title: 'Theories of Demand and Supply', grade: 10),
      Chapter(title: 'Theories of Production and Cost', grade: 10),
      Chapter(title: 'Market Structure', grade: 10),
      Chapter(title: 'Banking and Finance', grade: 10),
      Chapter(title: 'Economic Growth', grade: 10),
      Chapter(title: 'The Ethiopian Economy', grade: 10),
      Chapter(title: 'Business Start-ups and Innovation', grade: 10),
    ],
    11: [
      Chapter(title: 'Theory of Consumer Behaviour', grade: 11),
      Chapter(title: 'Market Structure and the Decision of Firm', grade: 11),
      Chapter(title: 'National Income Accounting', grade: 11),
      Chapter(title: 'Consumption, Saving, and Investment', grade: 11),
      Chapter(title: 'Trade and Finance', grade: 11),
      Chapter(title: 'Economic Development', grade: 11),
      Chapter(title: 'Main Sectors, Sectoral Policies, and Strategies of Ethiopia', grade: 11),
    ],
    12: [
      Chapter(title: 'The Fundamental Concepts of Macroeconomics', grade: 12),
      Chapter(title: 'Aggregate Demand and Aggregate Supply Analysis', grade: 12),
      Chapter(title: 'Market Failure and Consumer Protection', grade: 12),
      Chapter(title: 'Macroeconomic Policy Instruments', grade: 12),
      Chapter(title: 'Tax Theory and Practice', grade: 12),
      Chapter(title: 'Poverty and Inequality', grade: 12),
      Chapter(title: 'Macroeconomic Reforms in Ethiopia', grade: 12),
      Chapter(title: 'Economy, Environment, and Climate Change', grade: 12),
    ],
  };
}

Map<int, List<Chapter>> getGeographyChapters() {
  return {
    9: [
      Chapter(title: 'Introduction to Geography', grade: 9),
      Chapter(title: 'The Earth and Its Movement', grade: 9),
      Chapter(title: 'The Structure of the Earth', grade: 9),
      Chapter(title: 'Natural Resources', grade: 9),
      Chapter(title: 'Climate and Weather', grade: 9),
      Chapter(title: 'Map Reading and Interpretation', grade: 9),
      Chapter(title: 'Population Geography', grade: 9),
      Chapter(title: 'Settlement Geography', grade: 9),
    ],
    10: [
      Chapter(title: 'Physical Geography of Africa', grade: 10),
      Chapter(title: 'Physical Geography of Ethiopia', grade: 10),
      Chapter(title: 'Agriculture and Land Use', grade: 10),
      Chapter(title: 'Transport and Communication', grade: 10),
      Chapter(title: 'Human Geography of Africa', grade: 10),
      Chapter(title: 'Human Geography of Ethiopia', grade: 10),
      Chapter(title: 'Urbanization', grade: 10),
      Chapter(title: 'Environmental Issues', grade: 10),
    ],
    11: [
      Chapter(title: 'Physical Geography (Landforms and Landscapes)', grade: 11),
      Chapter(title: 'The Atmosphere and Weather Systems', grade: 11),
      Chapter(title: 'Hydrology and Water Resources', grade: 11),
      Chapter(title: 'Population and Settlement Patterns', grade: 11),
      Chapter(title: 'Economic Geography (Agriculture, Industry, and Services)', grade: 11),
      Chapter(title: 'Urbanization and Urban Planning', grade: 11),
      Chapter(title: 'Geographical Information Systems (GIS)', grade: 11),
      Chapter(title: 'Environmental Management and Sustainability', grade: 11),
    ],
    12: [
      Chapter(title: 'Climate and Weather Systems', grade: 12),
      Chapter(title: 'Geomorphology', grade: 12),
      Chapter(title: 'Human Geography and Regional Development', grade: 12),
      Chapter(title: 'The Economic Geography of Africa', grade: 12),
      Chapter(title: 'Natural Hazards and Disasters', grade: 12),
      Chapter(title: 'Environmental Issues and Sustainable Development', grade: 12),
      Chapter(title: 'Geographical Information Systems (GIS) and Remote Sensing', grade: 12),
      Chapter(title: 'Spatial Planning and Resource Management', grade: 12),
    ],
  };
}

Map<int, List<Chapter>> getHistoryChapters() {
  return {
    9: [
      Chapter(title: 'The Prehistoric Era', grade: 9),
      Chapter(title: 'The Ancient Civilizations of the World', grade: 9),
      Chapter(title: 'Ancient African Civilizations', grade: 9),
      Chapter(title: 'Ancient Egypt and Its Contributions', grade: 9),
      Chapter(title: 'Early African Kingdoms', grade: 9),
      Chapter(title: 'The Rise of Rome and Greece', grade: 9),
      Chapter(title: 'Development of World Religions', grade: 9),
      Chapter(title: 'The Middle Ages in Europe and Africa', grade: 9),
    ],
    10: [
      Chapter(title: 'The Rise and Fall of Ancient Civilizations', grade: 10),
      Chapter(title: 'The Medieval World (Europe, Africa, and Asia)', grade: 10),
      Chapter(title: 'The Renaissance and Reformation', grade: 10),
      Chapter(title: 'The Age of Exploration', grade: 10),
      Chapter(title: 'The Enlightenment and Revolutions', grade: 10),
      Chapter(title: 'The Industrial Revolution', grade: 10),
      Chapter(title: 'The Slave Trade and Colonization', grade: 10),
      Chapter(title: 'The African Diaspora and Post-Colonial History', grade: 10),
    ],
    11: [
      Chapter(title: 'The Age of Empires (European and Asian Empires)', grade: 11),
      Chapter(title: 'The Formation of the Modern State System', grade: 11),
      Chapter(title: 'The French Revolution and Its Impact', grade: 11),
      Chapter(title: 'Industrialization and Its Global Impact', grade: 11),
      Chapter(title: 'The World Wars (World War I & II)', grade: 11),
      Chapter(title: 'Post-World War Developments and the Cold War', grade: 11),
      Chapter(title: 'Decolonization and the African Struggle for Independence', grade: 11),
      Chapter(title: 'The Contemporary World (Globalization and Regional Conflicts)', grade: 11),
    ],
    12: [
      Chapter(title: 'The Rise of Modern Nations (Nationalism and State Formation)', grade: 12),
      Chapter(title: 'The Role of Technology and Innovations in History', grade: 12),
      Chapter(title: 'The Impact of Global Wars (World War I & II)', grade: 12),
      Chapter(title: 'The Interwar Period and the Great Depression', grade: 12),
      Chapter(title: 'The Cold War and Its Influence', grade: 12),
      Chapter(title: 'The Struggle for Independence and Nation-Building', grade: 12),
      Chapter(title: 'Contemporary Historical Movements (Post-Colonial Struggles)', grade: 12),
      Chapter(title: 'International Relations and Globalization', grade: 12),
    ],
  };
}
