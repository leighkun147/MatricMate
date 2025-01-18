import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/premium_level.dart';
import '../utils/device_id_manager.dart';

class DeviceVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isDeviceApproved() async {
    final deviceId = await DeviceIdManager.getDeviceId();
    final docSnapshot = await _firestore
        .collection('approved_devices')
        .doc(deviceId)
        .get();

    return docSnapshot.exists;
  }

  Future<PremiumLevel?> getDevicePremiumLevel() async {
    final deviceId = await DeviceIdManager.getDeviceId();
    final docSnapshot = await _firestore
        .collection('approved_devices')
        .doc(deviceId)
        .get();

    if (!docSnapshot.exists) return null;

    final premiumLevelStr = docSnapshot.data()?['premium_level'] as String?;
    if (premiumLevelStr == null) return PremiumLevel.basic;

    return PremiumLevel.values.firstWhere(
      (level) => level.name == premiumLevelStr.toLowerCase(),
      orElse: () => PremiumLevel.basic,
    );
  }

  Future<bool> canAccessPremiumLevel(PremiumLevel requiredLevel) async {
    final currentLevel = await getDevicePremiumLevel();
    if (currentLevel == null) return false;
    return currentLevel.canAccess(requiredLevel);
  }
}
