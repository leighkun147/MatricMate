import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_submission_screen.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  Future<List<PaymentMethod>> _fetchPaymentMethods() async {
    try {
      print('Fetching payment methods from Firestore...');
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('payment_methods')
          .where('account_number', isNull: false)
          .get();

      print('Number of documents found: ${querySnapshot.docs.length}');
      
      List<PaymentMethod> methods = [];
      for (var doc in querySnapshot.docs) {
        try {
          print('Processing document ID: ${doc.id}');
          print('Document data: ${doc.data()}');
          
          final data = doc.data() as Map<String, dynamic>;
          print('Fields in document:');
          print('- download_url: ${data['download_url']}');
          print('- account_number: ${data['account_number']}');
          print('- instructions: ${data['instructions']}');
          
          methods.add(PaymentMethod.fromFirestore(doc));
          print('Successfully processed document: ${doc.id}');
        } catch (e, stackTrace) {
          print('Error processing document ${doc.id}: $e');
          print('Stack trace: $stackTrace');
        }
      }
      
      print('Successfully processed ${methods.length} payment methods');
      return methods;
    } catch (e, stackTrace) {
      print('Error fetching payment methods: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<PaymentMethod>>(
            future: _fetchPaymentMethods(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading payment methods: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No payment methods available at the moment.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final paymentMethods = snapshot.data!;
              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.8,
                ),
                itemCount: paymentMethods.length,
                itemBuilder: (context, index) {
                  return PaymentMethodCard(
                    paymentMethod: paymentMethods[index],
                    onTap: () => _showPaymentInstructions(context, paymentMethods[index]),
                  );
                },
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FormSubmissionScreen(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('I Have Paid'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentInstructions(BuildContext context, PaymentMethod method) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PaymentInstructionsSheet(paymentMethod: method),
    );
  }
}

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final VoidCallback onTap;

  const PaymentMethodCard({
    super.key,
    required this.paymentMethod,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/bank_logos/${paymentMethod.name}.jpg',
                height: 64,
                width: 64,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                paymentMethod.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentInstructionsSheet extends StatelessWidget {
  final PaymentMethod paymentMethod;

  const PaymentInstructionsSheet({
    super.key,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Image.asset(
                    'assets/images/bank_logos/${paymentMethod.name}.jpg',
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        size: 24,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paymentMethod.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Account Number: ${paymentMethod.accountNumber}\nAccount Holder: ${paymentMethod.accountHolderName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Follow these steps:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ...paymentMethod.instructions.map((instruction) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.circle, size: 8),
                              const SizedBox(width: 8),
                              Expanded(child: Text(instruction)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                    const Text(
                      'Click the \'I Have Paid\' button below to proceed.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FormSubmissionScreen(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('I Have Paid'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PaymentMethod {
  final String name;
  final String accountNumber;
  final String accountHolderName;
  final List<String> instructions;

  const PaymentMethod({
    required this.name,
    required this.accountNumber,
    required this.accountHolderName,
    required this.instructions,
  });

  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    print('Raw document data in fromFirestore: $data');
    
    // Validate required fields
    if (data['account_number'] == null) {
      throw FormatException('account_number is missing in document ${doc.id}');
    }
    
    // Try to find instructions field (handle both 'instructions' and 'instructions ' field names)
    var instructionsField = data['instructions'];
    if (instructionsField == null) {
      instructionsField = data['instructions '];  // Try with space
    }
    
    if (instructionsField == null) {
      print('Available fields in document: ${data.keys.toList()}');
      throw FormatException('instructions field not found in document ${doc.id}');
    }
    
    // Safely convert instructions to List<String>
    List<String> instructionsList = [];
    try {
      if (instructionsField is List) {
        instructionsList = instructionsField.map((item) {
          // Clean up the string (remove quotes and trim)
          String cleaned = item.toString()
              .replaceAll('\'', '')
              .trim();
          return cleaned;
        }).toList();
      } else if (instructionsField is String) {
        // If it's a single string, split by comma
        instructionsList = instructionsField
            .split(',')
            .map((s) => s.replaceAll('\'', '').trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      
      print('Processed instructions list: $instructionsList');
      
      if (instructionsList.isEmpty) {
        // Provide default instructions if none are found
        instructionsList = [
          'Visit the nearest ${doc.id} branch',
          'Provide the following account details:',
          '  - Account Number: ${data['account_number']}',
          '  - Account Holder: ${data['Name']}',
          'Make the payment',
          'Keep your transaction receipt',
        ];
      }
    } catch (e) {
      print('Error processing instructions for ${doc.id}: $e');
      print('Raw instructions value: $instructionsField');
      // Use default instructions instead of throwing
      instructionsList = [
        'Visit the nearest branch',
        'Provide our account number: ${data['account_number']}',
        'Make the payment',
        'Keep your transaction receipt',
      ];
    }
    
    // Validate account holder name
    if (data['Name'] == null) {
      throw FormatException('Name (account holder) is missing in document ${doc.id}');
    }

    return PaymentMethod(
      name: doc.id,
      accountNumber: data['account_number'] as String,
      accountHolderName: data['Name'] as String,
      instructions: instructionsList,
    );
  }
}

// Payment methods are now loaded from Firestore
