import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/device_verification_service.dart';
import '../models/premium_level.dart';
import '../utils/device_id_manager.dart';

class CashOutScreen extends StatefulWidget {
  const CashOutScreen({super.key});

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _deviceVerificationService = DeviceVerificationService();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _calculateRequiredAmount() async {
    final deviceId = await DeviceIdManager.getDeviceId();
    final currentLevel = await _deviceVerificationService.getDevicePremiumLevel();

    int premiumUpgradeCost = 0;
    if (currentLevel == null) {
      // Device not registered, needs 600 for registration
      premiumUpgradeCost = 600;
    } else {
      // Device exists, check current premium level
      switch (currentLevel) {
        case PremiumLevel.zero:
          premiumUpgradeCost = 600;
          break;
        case PremiumLevel.basic:
          premiumUpgradeCost = 400;
          break;
        case PremiumLevel.pro:
          premiumUpgradeCost = 200;
          break;
        case PremiumLevel.elite:
          premiumUpgradeCost = 0;
          break;
      }
    }

    // Calculate how much of the 600 ETB will be used for premium upgrade
    int deductionFromBase = premiumUpgradeCost > 600 ? 600 : premiumUpgradeCost;
    int remainingForCashOut = 600 - deductionFromBase;

    return {
      'deviceId': deviceId,
      'premiumUpgradeCost': premiumUpgradeCost,
      'deductionFromBase': deductionFromBase,
      'remainingForCashOut': remainingForCashOut,
      'currentLevel': currentLevel,
    };
  }

  Future<void> _handleCashOutRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to make a cash-out request'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get required amount calculations
      final requirements = await _calculateRequiredAmount();
      
      // Get user's referral earnings
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final referralEarnings =
          (userDoc.data()?['referral_earnings'] as num?)?.toInt() ?? 0;

      if (referralEarnings < 600) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Insufficient Balance'),
            content: Text(
              'You need at least 600 ETB for cash-out. '
              'From this amount, ${requirements['deductionFromBase']} ETB will be used for premium upgrade '
              'and ${requirements['remainingForCashOut']} ETB will be sent to your Telebirr account. '
              'Keep referring more users to increase your earnings!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Start a batch write
      final batch = FirebaseFirestore.instance.batch();

      // Update or create device document if premium upgrade is needed
      if (requirements['premiumUpgradeCost'] > 0) {
        final deviceRef = FirebaseFirestore.instance
            .collection('approved_devices')
            .doc(requirements['deviceId']);
        
        batch.set(deviceRef, {
          'premium_level': PremiumLevel.elite.name,
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Update user's referral earnings
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);
      batch.update(userRef, {
        'referral_earnings': referralEarnings - 600,
      });

      // Create cash-out request with remaining amount
      final cashOutRef = FirebaseFirestore.instance
          .collection('cash_out_request')
          .doc(currentUser.uid);
      batch.set(cashOutRef, {
        'user_name': currentUser.uid,
        'amount': requirements['remainingForCashOut'],
        'phone_number': _phoneController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'premium_upgrade_amount': requirements['deductionFromBase'],
      });

      // Commit the batch
      await batch.commit();

      if (!mounted) return;

      // Show success message with breakdown
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cash-out request submitted! ${requirements['deductionFromBase']} ETB used for premium upgrade, '
            '${requirements['remainingForCashOut']} ETB will be sent to your Telebirr account.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting cash-out request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Out'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your Telebirr phone number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your Telebirr phone number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  // Add Ethiopian phone number validation
                  if (!value.startsWith('09') || value.length != 10) {
                    return 'Please enter a valid Ethiopian phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCashOutRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Submit Cash Out Request',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
