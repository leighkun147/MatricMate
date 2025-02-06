import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ReduAIScreen extends StatelessWidget {
  const ReduAIScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redu AI'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/under_construction.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            Text(
              'Redu AI is under production',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
