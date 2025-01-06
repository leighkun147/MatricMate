import 'package:flutter/material.dart';
import '../utils/stream_utils.dart';

class StreamSelectionScreen extends StatefulWidget {
  const StreamSelectionScreen({super.key});

  @override
  State<StreamSelectionScreen> createState() => _StreamSelectionScreenState();
}

class _StreamSelectionScreenState extends State<StreamSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Stream'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose your academic stream to personalize your study materials',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildStreamCard(
              'Natural Science',
              'Includes Math, Physics, Chemistry, and Biology',
              StreamType.naturalScience,
            ),
            const SizedBox(height: 16),
            _buildStreamCard(
              'Social Science',
              'Includes Economics, Geography, History, and Math',
              StreamType.socialScience,
            ),
            const Spacer(),
            if (StreamUtils.selectedStream != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Complete'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamCard(
    String title,
    String description,
    StreamType stream,
  ) {
    final isSelected = StreamUtils.selectedStream == stream;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            StreamUtils.selectedStream = stream;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
