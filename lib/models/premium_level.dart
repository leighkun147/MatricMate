import '../services/premium_price_service.dart';

enum PremiumLevel {
  zero,
  basic,
  pro,
  elite;

  bool canAccess(PremiumLevel requiredLevel) {
    switch (this) {
      case PremiumLevel.zero:
        return requiredLevel == PremiumLevel.zero;
      case PremiumLevel.basic:
        return requiredLevel == PremiumLevel.zero ||
            requiredLevel == PremiumLevel.basic;
      case PremiumLevel.pro:
        return requiredLevel == PremiumLevel.zero ||
            requiredLevel == PremiumLevel.basic ||
            requiredLevel == PremiumLevel.pro;
      case PremiumLevel.elite:
        return true; // Elite can access all levels
    }
  }
}

class PremiumFeature {
  final String title;
  final String description;
  final List<String> features;
  final double price;
  final PremiumLevel level;

  const PremiumFeature({
    required this.title,
    required this.description,
    required this.features,
    required this.price,
    required this.level,
  });
}

Future<List<PremiumFeature>> getPremiumFeatures() async {
  return [
    PremiumFeature(
      title: 'Basic',
      description: 'Start your journey with essential features',
      features: [
        'Access to basic study materials',
        'Practice questions for core subjects',
        'Progress tracking',
        'Limited mock exams',
      ],
      price: await PremiumPriceService().getPriceForLevel('basic'),
      level: PremiumLevel.basic,
    ),
    PremiumFeature(
      title: 'Pro',
      description: 'Enhanced learning experience with advanced features',
      features: [
        'All Basic features',
        'Advanced study materials',
        'Detailed performance analytics',
        'Unlimited mock exams',
        'Priority support',
      ],
      price: await PremiumPriceService().getPriceForLevel('pro'),
      level: PremiumLevel.pro,
    ),
    PremiumFeature(
      title: 'Elite',
      description: 'Ultimate preparation package for top performers',
      features: [
        'All Pro features',
        'Exclusive study materials',
        'One-on-one tutoring sessions',
        'Custom study plans',
        'Guaranteed score improvement',
        'VIP support',
      ],
      price: await PremiumPriceService().getPriceForLevel('elite'),
      level: PremiumLevel.elite,
    ),
  ];
}
