import 'package:flutter/material.dart';

class ConstantsSection extends StatefulWidget {
  final Map<String, dynamic>? constants;

  const ConstantsSection({
    super.key,
    this.constants,
  });

  @override
  State<ConstantsSection> createState() => _ConstantsSectionState();
}

class _ConstantsSectionState extends State<ConstantsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.constants == null || widget.constants!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.functions,
                size: 16,
                color: Colors.blue,
              ),
              const SizedBox(width: 4),
              Text(
                'Constants',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.constants!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${entry.key} = ${entry.value}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
