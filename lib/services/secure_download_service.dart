import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert'; // Add this for JSON validation

class SecureDownloadService {
  static final Dio _dio = Dio();

  /// Checks if a file is already downloaded
  static Future<bool> isFileDownloaded(String collection, String filename) async {
    try {
      // Ensure lowercase filename
      filename = filename.toLowerCase();
      final filePath = await _getFilePath(collection, filename);
      final file = File(filePath);
      final exists = await file.exists();
      print('Checking file existence: $filePath');
      print('File exists: $exists');
      if (exists) {
        // Verify file is readable and contains valid JSON
        try {
          final content = await file.readAsString();
          json.decode(content); // Validate JSON
          print('File is valid JSON');
          return true;
        } catch (e) {
          print('File exists but is not valid JSON: $e');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Error checking file existence: $e');
      return false;
    }
  }

  /// Downloads a file from the given URL
  static Future<bool> downloadFile({
    required String url,
    required String collection,
    required String filename,
    Function(int received, int total)? onProgress,
  }) async {
    try {
      // Ensure lowercase filename
      filename = filename.toLowerCase();
      print('\nStarting download process for: $filename');
      print('Collection: $collection');
      print('URL: $url');
      
      // Ensure we have a valid filename
      if (filename.isEmpty) {
        throw Exception('Filename cannot be empty');
      }

      // Get the app's document directory
      final appDir = await getApplicationDocumentsDirectory();
      print('App documents directory: ${appDir.path}');
      
      // Create the base questions directory
      final questionsDir = Directory(path.join(
        appDir.path,
        'assets',
        'questions',
        'model_exams', // Fixed collection name for model exams
      ));
      print('Creating questions directory: ${questionsDir.path}');
      if (!await questionsDir.exists()) {
        await questionsDir.create(recursive: true);
        print('Created questions directory');
      }

      // Get the full file path
      final filePath = await _getFilePath(collection, filename);
      print('Target file path: $filePath');

      // Check if path is valid
      if (await FileSystemEntity.isDirectory(filePath)) {
        throw Exception('Path is a directory: $filePath');
      }

      // Download the file
      print('Starting file download...');
      final response = await _dio.download(
        url,
        filePath,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      // Verify the file was downloaded successfully
      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        print('Downloaded file size: $fileSize bytes');
        
        if (fileSize > 0) {
          // Read the file to verify it's valid JSON
          try {
            print('Verifying file content...');
            final content = await file.readAsString();
            // Try to parse it as JSON to validate
            json.decode(content);
            print('File content verified as valid JSON');
            await Future.delayed(Duration.zero); // Allow for file system sync
            print('File downloaded and verified successfully: $filePath');
            return true;
          } catch (e) {
            print('Downloaded file is not valid JSON: $e');
            await file.delete();
            throw Exception('Downloaded file is not valid JSON');
          }
        } else {
          print('Downloaded file is empty');
          await file.delete();
          throw Exception('Downloaded file is empty');
        }
      }

      throw Exception('File not found after download');
    } catch (e, stackTrace) {
      print('Error downloading file: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Gets the file path for a file in a collection
  static Future<String> _getFilePath(String collection, String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    // Ensure lowercase filename
    filename = filename.toLowerCase();
    return path.join(
      appDir.path,
      'assets',
      'questions',
      'model_exams', // Fixed collection name for model exams
      filename,
    );
  }
}
