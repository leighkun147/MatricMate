import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/stream_utils.dart';
import 'package:dio/dio.dart';
import 'downloaded_exams_screen.dart';
import 'olympiad_exams_screen.dart';
import 'package:lottie/lottie.dart';

class YourOlympiadScreen extends StatefulWidget {
  const YourOlympiadScreen({super.key});

  @override
  State<YourOlympiadScreen> createState() => _YourOlympiadScreenState();
}

class _YourOlympiadScreenState extends State<YourOlympiadScreen> {
  final Set<String> _selectedExams = {};
  bool _isDownloading = false;
  final Dio _dio = Dio();
  Set<String> _downloadedExams = {};

  @override
  void initState() {
    super.initState();
    _loadDownloadedExams();
  }

  Future<void> _loadDownloadedExams() async {
    final examDir = await _getExamDirectory();
    final selectedStream = await StreamUtils.selectedStream;
    if (selectedStream == null) return;

    final streamValue = selectedStream == StreamType.naturalScience
        ? 'natural_science'
        : 'social_science';

    final streamDir = Directory('${examDir.path}/$streamValue');
    if (!await streamDir.exists()) return;

    final files = await streamDir.list().toList();
    setState(() {
      _downloadedExams = files
          .map((file) => file.path.split('/').last)
          .toSet();
    });
  }

  Stream<List<DocumentSnapshot>> _getOlympiadExams() async* {
    final selectedStream = await StreamUtils.selectedStream;
    if (selectedStream == null) {
      yield [];
      return;
    }

    final streamValue = selectedStream == StreamType.naturalScience
        ? 'natural_science'
        : 'social_science';

    yield* FirebaseFirestore.instance
        .collection('Olympiad_exams')
        .where('stream', isEqualTo: streamValue)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Get the directory for storing olympiad exams
  Future<Directory> _getExamDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final examDir = Directory('${appDir.path}/assets/questions/olympiad_exams');
    if (!await examDir.exists()) {
      await examDir.create(recursive: true);
    }
    return examDir;
  }

  Future<void> _downloadSelectedExams() async {
    if (_selectedExams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one exam to download')),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final examDir = await _getExamDirectory();

      for (final examId in _selectedExams) {
        final doc = await FirebaseFirestore.instance
            .collection('Olympiad_exams')
            .doc(examId)
            .get();
        
        if (!doc.exists) continue;
        
        final data = doc.data() as Map<String, dynamic>;
        final downloadUrl = data['download_url'] as String;
        final filename = data['filename'] as String;
        final stream = data['stream'] as String;
        
        final streamDir = Directory('${examDir.path}/$stream');
        if (!await streamDir.exists()) {
          await streamDir.create();
        }
        
        final filePath = '${streamDir.path}/$filename';

        if (await File(filePath).exists()) {
          continue;
        }

        await _dio.download(
          downloadUrl,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              debugPrint('${(received / total * 100).toStringAsFixed(0)}%');
            }
          },
        );
      }

      // Load downloaded exams
      await _loadDownloadedExams();
      
      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Files downloaded successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading exams: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDownloading = false;
        _selectedExams.clear();
      });
    }
  }

  Future<void> _viewDownloadedExams() async {
    final examDir = await _getExamDirectory();
    
    if (!await examDir.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No downloaded exams found')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DownloadedExamsScreen(examDir: examDir),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AbsorbPointer(
        absorbing: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Exams',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      onPressed: _viewDownloadedExams,
                      icon: const Icon(Icons.folder),
                      tooltip: 'View Downloaded Exams',
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Note: All downloaded exams must be taken for the olympiad',
                  style: TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: _getOlympiadExams(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No exams available'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final doc = snapshot.data![index];
                        final data = doc.data() as Map<String, dynamic>;
                        final stream = data['stream'] as String;
                        final filename = data['filename'] as String;
                        final isDownloaded = _downloadedExams.contains(filename);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: isDownloaded
                                ? const CircleAvatar(
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.check, color: Colors.white),
                                  )
                                : Checkbox(
                                    value: _selectedExams.contains(doc.id),
                                    onChanged: _isDownloading
                                        ? null
                                        : (bool? value) {
                                            setState(() {
                                              if (value ?? false) {
                                                _selectedExams.add(doc.id);
                                              } else {
                                                _selectedExams.remove(doc.id);
                                              }
                                            });
                                          },
                                  ),
                            title: Text(
                              filename,
                              style: TextStyle(
                                fontWeight: isDownloaded ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Stream: ${stream.replaceAll('_', ' ').toUpperCase()}'),
                                if (isDownloaded)
                                  const Text(
                                    'Downloaded',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isDownloaded
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.description),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _downloadedExams.isNotEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OlympiadExamsScreen(),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Take Exam'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadSelectedExams,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isDownloading ? 'Downloading...' : 'Download Selected Exams'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isDownloading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          // Under Construction Animation Overlay
          Positioned(
            top: kToolbarHeight, // Start below app bar
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.white.withOpacity(0.9),
              child: Stack(
                children: [
                  Center(
                    child: Lottie.asset(
                      'assets/animations/under_construction.json',
                      width: 300,
                      height: 300,
                      repeat: true,
                      animate: true,
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.6,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white,
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Under Construction',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Coming Soon',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.black54,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ],
                ),
              ),
          ),
          ],
        ),
      ),
    );
  }
}


