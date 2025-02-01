import 'package:flutter/material.dart';

class YourOlympiadScreen extends StatelessWidget {
  const YourOlympiadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Your registered olympiads and exams will appear here',
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
