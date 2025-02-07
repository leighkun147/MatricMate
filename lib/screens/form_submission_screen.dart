import 'package:flutter/material.dart';
import '../models/premium_level.dart';
import '../utils/device_id_manager.dart';
import '../services/premium_price_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormSubmissionScreen extends StatefulWidget {
  const FormSubmissionScreen({super.key});

  @override
  State<FormSubmissionScreen> createState() => _FormSubmissionScreenState();
}

class _FormSubmissionScreenState extends State<FormSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPaymentMethod;
  String? _selectedPremiumLevel;
  final TextEditingController _referrerController = TextEditingController();
  final TextEditingController _transactionIdController = TextEditingController();
  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  final List<String> _paymentMethods = [
    'Commercial Bank of Ethiopia (CBE)',
    'Telebirr',
    'Dashen Bank',
    'Awash Bank',
    'Wegagen Bank',
    'E-Birr',
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _validateReferrer(String referrerUsername) async {
    try {
      print('Attempting to validate referrer: $referrerUsername');
      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('username', isEqualTo: referrerUsername.trim())
          .limit(1)
          .get();
      
      print('Query result docs length: ${result.docs.length}');
      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error validating referrer: $e');
      return false;
    }
  }

  Future<void> _submitFormToFirestore(String deviceId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Validate referrer if provided
      if (_referrerController.text.isNotEmpty) {
        print('Referrer username provided: ${_referrerController.text}');
        final bool referrerExists = await _validateReferrer(_referrerController.text);
        if (!referrerExists) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The referrer username was not found. Please check and try again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Check if device is approved and get its premium level
      String currentLevel = 'zero';
      try {
        final approvedDeviceDoc = await _firestore
            .collection('approved_devices')
            .doc(deviceId)
            .get();
        
        if (approvedDeviceDoc.exists) {
          currentLevel = approvedDeviceDoc.data()?['premium_level'] ?? 'zero';
        }
      } catch (e) {
        print('Error checking approved devices: $e');
        // Continue with zero level if there's an error
      }

      // Prepare the data
      Map<String, dynamic> requestData = {
        'usersUID': currentUser.uid,
        'Referrer\'s_username': _referrerController.text.isEmpty ? null : _referrerController.text,
        'payment_method': _selectedPaymentMethod,
        'premium_level': _selectedPremiumLevel,
        'sender\'s_name': _senderNameController.text,
        'transaction_id': _isPhoneBasedPayment() ? null : _transactionIdController.text,
        'sender\'s_phone_number': _isPhoneBasedPayment() ? _phoneNumberController.text : null,
       'device_id': deviceId,
        'status': 'pending',
        'current_level': currentLevel,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Submit to Firestore using the deviceId as the document ID
      await _firestore
          .collection('requests')
          .doc(deviceId)
          .set(requestData);

      return;
    } catch (e) {
      print('Error submitting form: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _referrerController.dispose();
    _transactionIdController.dispose();
    _senderNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  bool _isPhoneBasedPayment() {
    return _selectedPaymentMethod == 'Telebirr' || _selectedPaymentMethod == 'E-Birr';
  }

  int _getPremiumLevelRank(String level) {
    switch (level.toLowerCase()) {
      case 'basic':
        return 1;
      case 'pro':
        return 2;
      case 'elite':
        return 3;
      default:
        return 0; // for 'zero' or unknown levels
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invalid Selection'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _referrerController,
              decoration: const InputDecoration(
                labelText: 'Referrer\'s Username (Optional)',
                border: OutlineInputBorder(),
                helperText: 'Enter the username of the person who referred you (if any)',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  return null;
                } else {
                  return null;
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Choose Your Premium Level',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock more features and enhance your learning experience',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: FutureBuilder<List<PremiumFeature>>(
                future: getPremiumFeatures(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final features = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      final isSelected = _selectedPremiumLevel == feature.level.name.toLowerCase();

                      return GestureDetector(
                        onTap: () async {
                          final value = feature.level.name.toLowerCase();
                          final deviceId = await DeviceIdManager.getDeviceId();
                          if (deviceId == null) return;
                          
                          try {
                            final approvedDeviceDoc = await _firestore
                                .collection('approved_devices')
                                .doc(deviceId)
                                .get();
                            
                            String currentLevel = 'zero';
                            if (approvedDeviceDoc.exists) {
                              currentLevel = approvedDeviceDoc.data()?['premium_level'] ?? 'zero';
                            }

                            if (_getPremiumLevelRank(value) <= _getPremiumLevelRank(currentLevel)) {
                              _showErrorDialog(
                                'You cannot request ${value.toUpperCase()} level as you already have '
                                '${currentLevel.toUpperCase()} level access, which includes all '
                                'features of lower levels.'
                              );
                              return;
                            }

                            setState(() {
                              _selectedPremiumLevel = value;
                            });
                          } catch (e) {
                            print('Error checking premium level: $e');
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: MediaQuery.of(context).size.width * 0.7,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isSelected
                                  ? [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                    ]
                                  : [
                                      Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                                      Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                    ],
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                                      : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      feature.title.toUpperCase(),
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.onPrimary
                                                : Theme.of(context).colorScheme.onSurface,
                                          ),
                                    ),
                                    if (feature.price > 0) ...[  
                                      const SizedBox(height: 4),
                                      Text(
                                        '${feature.price.toStringAsFixed(2)} ETB',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Theme.of(context).colorScheme.onPrimary
                                                  : Theme.of(context).colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      feature.description,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.9)
                                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  itemCount: feature.features.length,
                                  itemBuilder: (context, featureIndex) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 16,
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.onPrimary
                                                : Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              feature.features[featureIndex],
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: isSelected
                                                        ? Theme.of(context).colorScheme.onPrimary
                                                        : Theme.of(context).colorScheme.onSurface,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Selected Plan',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: _paymentMethods.map((String method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a payment method';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Transaction Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _senderNameController,
              decoration: const InputDecoration(
                labelText: 'Sender\'s Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter sender\'s name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (_isPhoneBasedPayment()) ...[              
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Sender\'s Phone Number',
                  border: OutlineInputBorder(),
                  prefixText: '+251',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (!RegExp(r'^9[0-9]{8}$').hasMatch(value)) {
                    return 'Please enter valid phone number';
                  }
                  return null;
                },
              ),
            ] else ...[              
              TextFormField(
                controller: _transactionIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter transaction ID';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    String? deviceId = await DeviceIdManager.getDeviceId();
                    if (deviceId == null) {
                      throw Exception('Could not get device ID');
                    }

                    // Check current premium level before submitting
                    final approvedDeviceDoc = await _firestore
                        .collection('approved_devices')
                        .doc(deviceId)
                        .get();
                    
                    String currentLevel = 'zero';
                    if (approvedDeviceDoc.exists) {
                      currentLevel = approvedDeviceDoc.data()?['premium_level'] ?? 'zero';
                    }

                    // Check if premium level is selected
                    if (_selectedPremiumLevel == null) {
                      _showErrorDialog(
                        'Please select a premium level before submitting.'
                      );
                      return;
                    }

                    // Prevent submission if requesting same or lower level
                    if (_getPremiumLevelRank(_selectedPremiumLevel!) <= _getPremiumLevelRank(currentLevel)) {
                      _showErrorDialog(
                        'You cannot request ${_selectedPremiumLevel!.toUpperCase()} level as you already have '
                        '${currentLevel.toUpperCase()} level access, which includes all '
                        'features of lower levels.'
                      );
                      return;
                    }

                    await _submitFormToFirestore(deviceId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Form submitted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
