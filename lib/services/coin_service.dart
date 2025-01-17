import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoinService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's coin balance
  static Stream<int> getCoinBalance() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => (snapshot.data()?['coins'] as num?)?.toInt() ?? 0);
  }

  // Add coins to user's balance
  static Future<void> addCoins(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'coins': FieldValue.increment(amount),
      });
    } catch (e) {
      print('Error adding coins: $e');
      rethrow;
    }
  }

  // Deduct coins from user's balance
  static Future<bool> deductCoins(int amount) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Get current balance
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final currentCoins = (doc.data()?['coins'] as num?)?.toInt() ?? 0;

      // Check if user has enough coins
      if (currentCoins < amount) {
        return false;
      }

      // Deduct coins
      await _firestore.collection('users').doc(user.uid).update({
        'coins': FieldValue.increment(-amount),
      });

      return true;
    } catch (e) {
      print('Error deducting coins: $e');
      return false;
    }
  }

  // Get coin transaction history
  static Stream<List<CoinTransaction>> getCoinHistory() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('coin_transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoinTransaction.fromMap(doc.data()))
            .toList());
  }

  // Record a coin transaction
  static Future<void> recordTransaction({
    required int amount,
    required String type,
    required String description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('coin_transactions')
          .add({
        'amount': amount,
        'type': type,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error recording transaction: $e');
      rethrow;
    }
  }
}

class CoinTransaction {
  final int amount;
  final String type;
  final String description;
  final DateTime timestamp;

  CoinTransaction({
    required this.amount,
    required this.type,
    required this.description,
    required this.timestamp,
  });

  factory CoinTransaction.fromMap(Map<String, dynamic> map) {
    return CoinTransaction(
      amount: (map['amount'] as num).toInt(),
      type: map['type'] as String,
      description: map['description'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
