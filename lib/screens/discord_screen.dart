import 'package:flutter/material.dart';

class DiscordScreen extends StatefulWidget {
  const DiscordScreen({super.key});

  @override
  State<DiscordScreen> createState() => _DiscordScreenState();
}

class _DiscordScreenState extends State<DiscordScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discord'),
      ),
      body: const Center(
        child: Text('Discord Screen - Coming Soon'),
      ),
    );
  }
}
