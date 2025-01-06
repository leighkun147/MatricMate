import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'form_submission_screen.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
      ),
      body: Stack(
        children: [
          GridView.builder(
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
              SvgPicture.asset(
                paymentMethod.logoPath,
                height: 64,
                width: 64,
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
              Text(
                'Payment Instructions - ${paymentMethod.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
  final String logoPath;
  final List<String> instructions;

  const PaymentMethod({
    required this.name,
    required this.logoPath,
    required this.instructions,
  });
}

final List<PaymentMethod> paymentMethods = [
  PaymentMethod(
    name: 'Commercial Bank of Ethiopia',
    logoPath: 'assets/icons/cbe.svg',
    instructions: [
      'Visit your nearest CBE branch',
      'Provide our account number: 1000123456',
      'Make the payment',
      'Keep your transaction receipt',
    ],
  ),
  PaymentMethod(
    name: 'Telebirr',
    logoPath: 'assets/icons/telebirr.svg',
    instructions: [
      'Open your Telebirr app',
      'Select "Pay Bill"',
      'Enter our merchant ID: TB123456',
      'Enter the amount and confirm',
    ],
  ),
  PaymentMethod(
    name: 'Dashen Bank',
    logoPath: 'assets/icons/dashen.svg',
    instructions: [
      'Visit your nearest Dashen Bank branch',
      'Provide our account number: 0123456789',
      'Make the payment',
      'Keep your transaction receipt',
    ],
  ),
  PaymentMethod(
    name: 'Awash Bank',
    logoPath: 'assets/icons/awash.svg',
    instructions: [
      'Visit your nearest Awash Bank branch',
      'Provide our account number: 9876543210',
      'Make the payment',
      'Keep your transaction receipt',
    ],
  ),
  PaymentMethod(
    name: 'Wegagen Bank',
    logoPath: 'assets/icons/wegagen.svg',
    instructions: [
      'Visit your nearest Wegagen Bank branch',
      'Provide our account number: 5432109876',
      'Make the payment',
      'Keep your transaction receipt',
    ],
  ),
  PaymentMethod(
    name: 'E-Birr',
    logoPath: 'assets/icons/ebirr.svg',
    instructions: [
      'Open your E-Birr app',
      'Select "Pay Merchant"',
      'Enter our merchant code: EB987654',
      'Enter the amount and confirm',
    ],
  ),
];
