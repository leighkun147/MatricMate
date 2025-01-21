import 'package:flutter/material.dart';

class ConstantsButton extends StatelessWidget {
  final Map<String, dynamic>? constants;

  const ConstantsButton({super.key, this.constants});

  @override
  Widget build(BuildContext context) {
    if (constants == null || constants!.isEmpty) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.functions),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Constants'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: constants!.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${entry.key} = ${entry.value}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      tooltip: 'View Constants',
    );
  }
}
