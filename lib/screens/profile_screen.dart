import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme_provider.dart';
import '../models/user_model.dart';
import '../models/premium_level.dart';
import '../utils/device_id_manager.dart';
import '../services/device_verification_service.dart';
import 'stream_selection_screen.dart';
import 'payment_methods_screen.dart';
import 'login_screen.dart';
import '../services/coin_service.dart';
import 'theme_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  UserModel? _userModel;
  bool _isLoading = true;
  late Stream<DocumentSnapshot> _userStream;
  Stream<DocumentSnapshot>? _requestStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .snapshots();
    _initializeRequestStream();
    _loadUserData();
  }

  Future<void> _initializeRequestStream() async {
    try {
      final deviceId = await DeviceIdManager.getDeviceId();
      if (deviceId != null) {
        _requestStream = FirebaseFirestore.instance
            .collection('requests')
            .doc(deviceId)
            .snapshots();
        setState(() {});
      }
    } catch (e) {
      print('Error initializing request stream: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userModel = UserModel.fromMap(doc.data()!);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error signing out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          _userModel =
              UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildStats(),
                const SizedBox(height: 24),
                _buildPaymentMethodsCard(),
                const SizedBox(height: 24),
                _buildSettings(context),
                const SizedBox(height: 16),
                _buildLogoutButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[300],
          child: Icon(
            Icons.person,
            size: 50,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const CircularProgressIndicator()
        else
          Text(
            _userModel?.username ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(String label, dynamic value, {Color? valueColor}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        return StreamBuilder<int>(
          stream: CoinService.getCoinBalance(),
          builder: (context, coinSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting ||
                coinSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            final coins = coinSnapshot.data ?? 0;
            
            // Get referral data from Firestore
            final referralCount = (data['referral_count'] as num?)?.toInt() ?? 0;
            final referralEarnings = (data['referral_earnings'] as num?)?.toInt() ?? 0;
            
            // These are placeholder values that we'll implement later
            const ranking = 0;
            const activation = false;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                    child: Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Coins',
                          coins,
                          valueColor: Colors.amber[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          'Ranking',
                          '#$ranking',
                          valueColor: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Activation',
                          activation ? 'ON' : 'OFF',
                          valueColor: activation ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          'Referrals',
                          referralCount,
                          valueColor: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Total Earnings',
                          '$referralEarnings ETB',
                          valueColor: Colors.green[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: DeviceIdManager.getDeviceId(),
                          builder: (context, deviceIdSnapshot) {
                            if (!deviceIdSnapshot.hasData) {
                              return _buildStatItem(
                                'Premium',
                                'LOADING',
                                valueColor: Colors.grey[700],
                              );
                            }

                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('approved_devices')
                                  .doc(deviceIdSnapshot.data)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                String premiumText = 'NONE';
                                Color? premiumColor = Colors.grey[700];

                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final premiumLevel = snapshot.data!.get('premium_level') as String? ?? 'none';
                                  premiumText = premiumLevel.toUpperCase();
                                  
                                  switch (premiumLevel.toLowerCase()) {
                                    case 'basic':
                                      premiumColor = Colors.green[700];
                                      break;
                                    case 'pro':
                                      premiumColor = Colors.blue[700];
                                      break;
                                    case 'elite':
                                      premiumColor = Colors.purple[700];
                                      break;
                                  }
                                }

                                return _buildStatItem(
                                  'Premium',
                                  premiumText,
                                  valueColor: premiumColor,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Payment Methods'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              try {
                // Get device ID
                String? deviceId = await DeviceIdManager.getDeviceId();
                if (deviceId == null) {
                  throw Exception('Could not get device ID');
                }

                // Try to get the request status from Firestore
                try {
                  final doc = await FirebaseFirestore.instance
                      .collection('requests')
                      .doc(deviceId)
                      .get();

                  if (doc.exists && doc.get('status') == 'pending') {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Payment Request Pending'),
                            content: const Text(
                              'You have a pending payment request. Please wait for confirmation before making another request.',
                              style: TextStyle(fontSize: 16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                    return;
                  }
                  if (doc.exists && doc.get('status') == 'rejected') {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          String rejectionReason = doc.get('rejection_reason') ?? 'No reason provided';
                          return AlertDialog(
                            title: const Text('Payment Request Rejected'),
                            content: Text(
                              'Your payment request has been rejected.\n\nReason: $rejectionReason\n\nYou can try again later or visit the payment options to update your payment method',
                              style: const TextStyle(fontSize: 16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // After the alert, go to the Payment Methods screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PaymentMethodsScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Go to Payment Methods'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                    return;
                  }
                } catch (e) {
                  // If there's any error (like no internet), proceed to payment methods
                  print('Error checking request status: $e');
                }

                // If we reach here, either:
                // 1. There was no internet connection
                // 2. There was no pending request
                // 3. The request was approved/rejected
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodsScreen(),
                    ),
                  );
                }
              } catch (e) {
                // Handle device ID error
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Select Your Stream'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StreamSelectionScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Customize Theme'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ThemeSelectionScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Add help & support functionality
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: 120,
      child: ElevatedButton(
        onPressed: _signOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Logout',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
