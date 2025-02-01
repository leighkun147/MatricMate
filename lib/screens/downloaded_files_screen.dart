import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

class DownloadedFilesScreen extends StatefulWidget {
  const DownloadedFilesScreen({super.key});

  @override
  State<DownloadedFilesScreen> createState() => _DownloadedFilesScreenState();
}

class FileDetails {
  final String name;
  final int size;
  final DateTime lastModified;
  final Map<String, dynamic>? content;
  final String collection;

  FileDetails({
    required this.name,
    required this.size,
    required this.lastModified,
    this.content,
    required this.collection,
  });
}

class _DownloadedFilesScreenState extends State<DownloadedFilesScreen> {
  List<FileDetails> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      setState(() => _isLoading = true);
      
      final appDir = await getApplicationDocumentsDirectory();
      final collections = ['model_exams', 'academic_year', 'subject_chapters_questions'];
      final fileDetails = <FileDetails>[];

      // Load files from each collection
      for (final collection in collections) {
        final collectionDir = Directory(path.join(
          appDir.path,
          'assets',
          'questions',
          collection,
        ));

        print('Checking collection directory: ${collectionDir.path}');

        if (!await collectionDir.exists()) {
          print('Directory does not exist: ${collectionDir.path}');
          continue;
        }

        final files = await collectionDir.list().toList();
        print('Found ${files.length} files in $collection');

        for (var entity in files) {
          if (entity is File) {
            print('Processing file: ${entity.path}');
            try {
              final stats = await entity.stat();
              Map<String, dynamic>? content;
              
              try {
                final fileContent = await entity.readAsString();
                content = json.decode(fileContent) as Map<String, dynamic>;
                print('Successfully parsed JSON from: ${entity.path}');

                fileDetails.add(FileDetails(
                  name: path.basename(entity.path),
                  size: stats.size,
                  lastModified: stats.modified,
                  content: content,
                  collection: collection, // Add collection information
                ));
                print('Added file to list: ${path.basename(entity.path)} from $collection');
              } catch (e) {
                print('Error reading/parsing JSON from ${entity.path}: $e');
              }
            } catch (e) {
              print('Error processing file ${entity.path}: $e');
            }
          }
        }
      }

      // Sort files by last modified date, most recent first
      fileDetails.sort((a, b) => b.lastModified.compareTo(a.lastModified));

      setState(() {
        _files = fileDetails;
        _isLoading = false;
      });
      
      print('Final files list length: ${_files.length}');
      for (var file in _files) {
        print('Loaded file: ${file.name} from ${file.collection}, size: ${file.size}, has content: ${file.content != null}');
      }
    } catch (e, stackTrace) {
      print('Error loading files: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _files = [];
        _isLoading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getCollectionColor(String collection) {
    switch (collection) {
      case 'academic_year':
        return Colors.blue;
      case 'model_exams':
        return Colors.purple;
      case 'subject_chapters_questions':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCollectionIcon(String collection) {
    switch (collection) {
      case 'academic_year':
        return Icons.school;
      case 'model_exams':
        return Icons.assignment;
      case 'subject_chapters_questions':
        return Icons.book;
      default:
        return Icons.file_present;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No downloaded files found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final content = file.content;
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: Icon(
                          _getCollectionIcon(file.collection),
                          color: _getCollectionColor(file.collection),
                        ),
                        title: Text(
                          file.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Size: ${_formatFileSize(file.size)}\n'
                          'Last Modified: ${_formatDate(file.lastModified)}\n'
                          'Collection: ${file.collection}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete File'),
                                    content: Text('Are you sure you want to delete ${file.name}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true && mounted) {
                                  try {
                                    final appDir = await getApplicationDocumentsDirectory();
                                    final filePath = path.join(
                                      appDir.path,
                                      'assets',
                                      'questions',
                                      file.collection,
                                      file.name,
                                    );
                                    await File(filePath).delete();
                                    _loadFiles();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('File deleted successfully')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Error deleting file')),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        children: [
                          if (content != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'File Contents:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (content['type'] != null)
                                          Text('Type: ${content['type']}'),
                                        if (content['subject'] != null)
                                          Text('Subject: ${content['subject']}'),
                                        if (content['year'] != null)
                                          Text('Year: ${content['year']}'),
                                        if (content['questions'] != null)
                                          Text('Questions: ${(content['questions'] as List?)?.length ?? 0} items'),
                                        if (content['difficulty'] != null)
                                          Text('Difficulty: ${content['difficulty']}'),
                                        if (content['duration'] != null)
                                          Text('Duration: ${content['duration']} minutes'),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(file.name),
                                                content: SingleChildScrollView(
                                                  child: Text(
                                                    const JsonEncoder.withIndent('  ')
                                                        .convert(content),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child: const Text('View Full JSON'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
