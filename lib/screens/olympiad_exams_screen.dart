import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/stream_utils.dart';
import 'exam_taking_screen.dart';

class OlympiadExamsScreen extends StatefulWidget {
  const OlympiadExamsScreen({super.key});

  @override
  State<OlympiadExamsScreen> createState() => _OlympiadExamsScreenState();
}

class _OlympiadExamsScreenState extends State<OlympiadExamsScreen> {
  List<FileSystemEntity> _exams = [];
  String _currentStream = 'natural_science';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<Directory> _getExamDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final examDir = Directory('${appDir.path}/assets/questions/olympiad_exams');
    if (!await examDir.exists()) {
      await examDir.create(recursive: true);
    }
    return examDir;
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    try {
      final examDir = await _getExamDirectory();
      final selectedStream = await StreamUtils.selectedStream;
      
      if (selectedStream == null) {
        setState(() {
          _exams = [];
          _isLoading = false;
        });
        return;
      }

      _currentStream = selectedStream == StreamType.naturalScience
          ? 'natural_science'
          : 'social_science';

      final streamDir = Directory('${examDir.path}/$_currentStream');
      if (!await streamDir.exists()) {
        setState(() {
          _exams = [];
          _isLoading = false;
        });
        return;
      }

      final files = await streamDir.list().toList();
      setState(() {
        _exams = files;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading exams: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startExam(FileSystemEntity examFile) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamTakingScreen(
          examFile: examFile as File,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Olympiad Exams'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No exams available for ${_currentStream.replaceAll('_', ' ').toUpperCase()}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadExams,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadExams,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _exams.length,
                    itemBuilder: (context, index) {
                      final exam = _exams[index];
                      final examName = exam.path.split('/').last;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.quiz),
                          ),
                          title: Text(
                            examName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Stream: ${_currentStream.replaceAll('_', ' ').toUpperCase()}',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _startExam(exam),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Start'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
