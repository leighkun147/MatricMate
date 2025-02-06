import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../models/user_model.dart';
import '../utils/device_id_manager.dart';
import 'stream_selection_screen.dart';
import 'payment_methods_screen.dart';
import 'login_screen.dart';
import '../services/coin_service.dart';
import 'theme_selection_screen.dart';
import 'exam_history_screen.dart';
import '../services/user_cache_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String _premiumLevel = 'zero';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final cachedUsername = prefs.getString('${user!.uid}_username');

    if (cachedUsername != null) {
      setState(() {
        _userModel = UserModel(
          uid: user!.uid,
          username: cachedUsername,
          phoneNumber: '',
          email: user!.email ?? '',
        );
        _isLoading = false;
      });
    } else {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();

      if (doc.exists && mounted) {
        final username = doc.get('username') as String;
        // Cache the username
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('${user!.uid}_username', username);

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${user!.uid}_username'); // Clear cached username
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

  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _signOut();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          _userModel =
              UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);
        }

        return Scaffold(
            endDrawer: _buildStatisticsDrawer(),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                Builder(
                  builder: (context) => Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: Material(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Statistics',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildExamHistoryCard(),
                    const SizedBox(height: 24),
                    _buildPaymentMethodsCard(),
                    const SizedBox(height: 24),
                    _buildSettings(context),
                    const Divider(height: 32),
                    _buildLogoutButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ));
      },
    );
  }

  Widget _buildProfileHeader() {
    return FutureBuilder<String?>(
      future: DeviceIdManager.getDeviceId(),
      builder: (context, deviceIdSnapshot) {
        if (!deviceIdSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('approved_devices')
              .doc(deviceIdSnapshot.data)
              .snapshots(),
          builder: (context, snapshot) {
            final premiumLevel = snapshot.hasData && snapshot.data!.exists
                ? (snapshot.data!.get('premium_level') as String? ?? 'zero')
                : 'zero';

            // Cache the premium level whenever it changes
            UserCacheService.updatePremiumLevel(premiumLevel);

            // Define premium level gradients and effects
            final Map<String, List<Color>> premiumGradients = {
              'zero': [Colors.grey[300]!, Colors.grey[400]!],
              'basic': [Colors.blue[300]!, Colors.purple[300]!],
              'pro': [Colors.purple[400]!, Colors.pink[300]!],
              'elite': [
                const Color(0xFFFFD700),
                const Color(0xFFFFA500),
              ],
            };

            final Map<String, Widget> premiumBadges = {
              'zero': const SizedBox.shrink(),
              'basic': Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'BASIC',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              'pro': Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.pink[300]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
              'elite': Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      'ELITE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            };

            return Column(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: premiumGradients[premiumLevel]!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                          if (premiumLevel == 'elite')
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              spreadRadius: 4,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 54,
                                color: Colors.grey[800],
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: premiumLevel == 'zero'
                                        ? Colors.blue
                                        : Colors.purple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.school,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (premiumLevel != 'zero')
                      Positioned(
                        top: 0,
                        right: 0,
                        child: premiumBadges[premiumLevel]!,
                      ),
                    if (premiumLevel == 'zero')
                      Positioned(
                        top: -5,
                        right: -5,
                        child: IconButton(
                          icon: const Icon(
                            Icons.workspace_premium,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Upgrade Your Device'),
                                content: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Unlock premium features:'),
                                    SizedBox(height: 8),
                                    Text('• Advanced study analytics'),
                                    Text('• Unlimited study plans'),
                                    Text('• Priority support'),
                                    Text('• Ad-free experience'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Maybe Later'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      // TODO: Implement device upgrade process
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Upgrade Now'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (premiumLevel == 'zero')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Upgrade to unlock all features',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
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
          },
        );
      },
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
                color:
                    valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsDrawer() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
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

            final data =
                userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            final coins = coinSnapshot.data ?? 0;

            // Get referral data from Firestore
            final referralCount =
                (data['referral_count'] as num?)?.toInt() ?? 0;
            final referralEarnings =
                (data['referral_earnings'] as num?)?.toInt() ?? 0;

            // These are placeholder values that we'll implement later
            const ranking = 0;
            const activation = false;

            return Drawer(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Statistics',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                    valueColor: activation
                                        ? Colors.green[700]
                                        : Colors.red[700],
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
                                          Color? premiumColor =
                                              Colors.grey[700];

                                          if (snapshot.hasData &&
                                              snapshot.data!.exists) {
                                            final premiumLevel = snapshot.data!
                                                        .get('premium_level')
                                                    as String? ??
                                                'none';
                                            premiumText =
                                                premiumLevel.toUpperCase();

                                            // Cache the premium level whenever it changes
                                            UserCacheService.updatePremiumLevel(
                                                premiumLevel);

                                            switch (
                                                premiumLevel.toLowerCase()) {
                                              case 'basic':
                                                premiumColor =
                                                    Colors.green[700];
                                                break;
                                              case 'pro':
                                                premiumColor = Colors.blue[700];
                                                break;
                                              case 'elite':
                                                premiumColor =
                                                    Colors.purple[700];
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
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExamHistoryCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Mock Exam History',
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
            leading: const Icon(Icons.history_edu),
            title: const Text('View History'),
            subtitle: const Text('See your past mock exam results'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExamHistoryScreen(),
                ),
              );
            },
          ),
        ),
      ],
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
                          String rejectionReason =
                              doc.get('rejection_reason') ??
                                  'No reason provided';
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
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.color_lens),
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
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(bottom: 16),
      child: IconButton(
        onPressed: _showLogoutConfirmationDialog,
        icon: const Icon(Icons.exit_to_app),
        color: Colors.red[700],
        tooltip: 'Logout',
        iconSize: 24,
      ),
    );
  }
}
