import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/device_verification_service.dart';
import '../models/premium_level.dart';
import '../utils/device_id_manager.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

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
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green[700]!,
                  Colors.green[900]!,
                ],
              ),
            ),
          ),
          // Animated money patterns
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Lottie.asset(
                'assets/animations/money_background.json',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Custom App Bar
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Cash Out',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Lottie.asset(
                          'assets/animations/wallet.json',
                          fit: BoxFit.cover,
                        ),
                        // Gradient overlay
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.green[900]!.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Main Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Glass morphism card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Enter your Telebirr phone number',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Custom TextFormField
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: const TextStyle(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Phone Number',
                                          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                          hintText: 'Enter your Telebirr phone number',
                                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(15),
                                            borderSide: BorderSide.none,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.phone,
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                          filled: true,
                                          fillColor: Colors.transparent,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your phone number';
                                          }
                                          if (!value.startsWith('09') || value.length != 10) {
                                            return 'Please enter a valid Ethiopian phone number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Animated submit button
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _isLoading
                                              ? [Colors.grey, Colors.grey.shade700]
                                              : [Colors.amber.shade400, Colors.orange.shade700],
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: MaterialButton(
                                        onPressed: _isLoading ? null : _handleCashOutRequest,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.account_balance_wallet,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'Cash Out Now',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
