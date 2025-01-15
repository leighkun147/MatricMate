import 'package:flutter/material.dart';
import '../utils/device_id_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';

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
            DropdownButtonFormField<String>(
              value: _selectedPremiumLevel,
              decoration: const InputDecoration(
                labelText: 'Premium Level',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'basic',
                  child: Text('Basic (200 ETB)'),
                ),
                DropdownMenuItem(
                  value: 'pro',
                  child: Text('Pro (400 ETB)'),
                ),
                DropdownMenuItem(
                  value: 'elite',
                  child: Text('Elite (600 ETB)'),
                ),
              ],
              onChanged: (String? value) async {
                if (value == null) return;
                
                // Get the device ID and check current level
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

                  // Check if requesting same level or trying to downgrade
                  if (_getPremiumLevelRank(value) <= _getPremiumLevelRank(currentLevel)) {
                    _showErrorDialog(
                      'You cannot request ${value.toUpperCase()} level as you already have '
                      '${currentLevel.toUpperCase()} level access, which includes all '
                      'features of lower levels.'
                    );
                    return;
                  }

                  // If validation passes, update the selected level
                  setState(() {
                    _selectedPremiumLevel = value;
                  });
                } catch (e) {
                  print('Error checking premium level: $e');
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a premium level';
                }
                return null;
              },
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
            if (_isPhoneBasedPayment())
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Sender\'s Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (_isPhoneBasedPayment() && (value == null || value.isEmpty)) {
                    return 'Please enter sender\'s phone number';
                  }
                  return null;
                },
              )
            else
              TextFormField(
                controller: _transactionIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (!_isPhoneBasedPayment() && (value == null || value.isEmpty)) {
                    return 'Please enter transaction ID';
                  }
                  return null;
                },
              ),
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
