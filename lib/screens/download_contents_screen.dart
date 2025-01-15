import 'package:flutter/material.dart';

class DownloadContentsScreen extends StatefulWidget {
  const DownloadContentsScreen({super.key});

  @override
  State<DownloadContentsScreen> createState() => _DownloadContentsScreenState();
}

class _DownloadContentsScreenState extends State<DownloadContentsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Contents'),
      ),
      body: const Center(
        child: Text('Download Contents Screen - Coming Soon'),
      ),
    );
  }
}
