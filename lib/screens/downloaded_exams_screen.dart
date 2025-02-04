import 'package:flutter/material.dart';
import 'dart:io';

class DownloadedExamsScreen extends StatefulWidget {
  final Directory examDir;

  const DownloadedExamsScreen({
    super.key,
    required this.examDir,
  });

  @override
  State<DownloadedExamsScreen> createState() => _DownloadedExamsScreenState();
}

class _DownloadedExamsScreenState extends State<DownloadedExamsScreen> {
  List<FileSystemEntity> _files = [];
  String _currentStream = 'natural_science';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final streamDir = Directory('${widget.examDir.path}/$_currentStream');
    if (await streamDir.exists()) {
      final files = await streamDir.list().toList();
      setState(() => _files = files);
    } else {
      setState(() => _files = []);
    }
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      await file.delete();
      await _loadFiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Exams'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'natural_science',
                        label: Text('Natural Science'),
                      ),
                      ButtonSegment(
                        value: 'social_science',
                        label: Text('Social Science'),
                      ),
                    ],
                    selected: {_currentStream},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _currentStream = newSelection.first;
                        _loadFiles();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _files.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No downloaded exams for ${_currentStream.replaceAll('_', ' ').toUpperCase()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(file.path.split('/').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteFile(file),
                  ),
                );
              },
            ),
    );
  }
}
