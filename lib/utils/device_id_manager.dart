import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class DeviceIdManager {
  static const String _deviceIdKey = 'device_id';
  static SharedPreferences? _prefs;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String> getDeviceId() async {
    _prefs = await SharedPreferences.getInstance();
    String? deviceId = _prefs!.getString(_deviceIdKey);

    if (deviceId != null) {
      return deviceId;
    }

    // Generate a new device ID if none exists
    deviceId = await _generateDeviceId();
    await _prefs!.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  static Future<String> _generateDeviceId() async {
    String uniqueIdentifier = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        uniqueIdentifier = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        uniqueIdentifier = iosInfo.identifierForVendor ?? '';
      }
    } catch (e) {
      print('Error getting device info: $e');
    }

    // Combine with UUID for extra uniqueness
    final uuid = Uuid();
    return '$uniqueIdentifier-${uuid.v4()}';
  }
}
