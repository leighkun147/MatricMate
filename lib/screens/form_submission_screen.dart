import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class FormSubmissionScreen extends StatefulWidget {
  const FormSubmissionScreen({super.key});

  @override
  State<FormSubmissionScreen> createState() => _FormSubmissionScreenState();
}

class _FormSubmissionScreenState extends State<FormSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPaymentMethod;
  String _submissionType = 'upload';
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
              onPressed: () {
                if (_formKey.currentState!.validate() &&
                    (_submissionType == 'details')) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        title: Row(
                          children: const [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 30,
                            ),
                            SizedBox(width: 10),
                            Text('Success!'),
                          ],
                        ),
                        content: const Text(
                          'Your form has been successfully submitted! 🎉\n\n'
                          'Please wait for approval from our team. We\'ll process your request as soon as possible.',
                          style: TextStyle(fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('OK'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pop(); // Return to previous screen
                            },
                          ),
                        ],
                      );
                    },
                  );
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
