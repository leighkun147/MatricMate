import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumPriceService {
  static final PremiumPriceService _instance = PremiumPriceService._internal();
  factory PremiumPriceService() => _instance;
  PremiumPriceService._internal();

  final Map<String, double> _cachedPrices = {};
  DateTime? _lastFetchTime;
  static const _cacheExpirationMinutes = 60; // Cache expires after 1 hour

  Future<double> getPriceForLevel(String level) async {
    // Check if cache is valid
    if (_isCacheValid() && _cachedPrices.containsKey(level)) {
      return _cachedPrices[level]!;
    }

    // If cache is invalid or price not found, fetch from Firestore
    await _refreshCache();
    return _cachedPrices[level] ?? 0.0;
  }

  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    final difference = DateTime.now().difference(_lastFetchTime!);
    return difference.inMinutes < _cacheExpirationMinutes;
  }

  Future<void> _refreshCache() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('premium_level_prices')
          .get();

      _cachedPrices.clear();
      for (var doc in snapshot.docs) {
        _cachedPrices[doc.id] = (doc['price'] as num).toDouble();
      }
      _lastFetchTime = DateTime.now();
    } catch (e) {
      print('Error fetching premium prices: $e');
      // Fallback prices if Firestore fetch fails
      _cachedPrices.addAll({
        'basic': 199.99,
        'pro': 399.99,
        'elite': 599.99,
      });
    }
  }

  // Force refresh cache
  Future<void> forceRefresh() async {
    _lastFetchTime = null;
    await _refreshCache();
  }
}
