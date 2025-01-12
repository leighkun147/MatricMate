import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/device_id_manager.dart';
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
  String _submissionType = 'upload';
  String? _selectedPremiumLevel;
  XFile? _selectedImage;
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
      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('username', isEqualTo: referrerUsername)
          .limit(1)
          .get();
      
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
        final bool referrerExists = await _validateReferrer(_referrerController.text);
        if (!referrerExists) {
          throw Exception('The referrer username does not exist');
        }
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
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Submit to Firestore using the user's UID as the document ID
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  bool _isPhoneBasedPayment() {
    return _selectedPaymentMethod == 'Telebirr' || _selectedPaymentMethod == 'E-Birr';
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
              onChanged: (String? value) {
                setState(() {
                  _selectedPremiumLevel = value;
                });
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
              'Proof of Payment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: Image upload functionality is temporarily disabled. Please use the transaction details option below.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('Upload Screenshot/Receipt (Currently Unavailable)'),
              value: 'upload',
              groupValue: _submissionType,
              onChanged: null,
            ),
            if (_submissionType == 'upload') ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image upload is temporarily disabled. Please use the transaction details option.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose File'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Selected file: ${_selectedImage!.name}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
            ],
            RadioListTile<String>(
              title: const Text('Submit Transaction Details'),
              value: 'details',
              groupValue: _submissionType,
              onChanged: (value) {
                setState(() {
                  _submissionType = value!;
                });
              },
            ),
            if (_submissionType == 'details') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _senderNameController,
                decoration: const InputDecoration(
                  labelText: 'Sender\'s Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_submissionType == 'details' && (value == null || value.isEmpty)) {
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
                    if (_submissionType == 'details' && _isPhoneBasedPayment() && (value == null || value.isEmpty)) {
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
                    if (_submissionType == 'details' && !_isPhoneBasedPayment() && (value == null || value.isEmpty)) {
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
