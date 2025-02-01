import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

class SecureDownloadService {
  static final Dio _dio = Dio();
  
  // Define valid collections
  static const List<String> validCollections = [
    'model_exams',
    'academic_year',
    'subject_chapters_questions'
  ];

  /// Checks if a file is already downloaded
  static Future<bool> isFileDownloaded(String collection, String filename) async {
    try {
      // Validate collection
      if (!validCollections.contains(collection)) {
        throw Exception('Invalid collection: $collection. Must be one of: $validCollections');
      }
      
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
      // Validate collection
      if (!validCollections.contains(collection)) {
        throw Exception('Invalid collection: $collection. Must be one of: $validCollections');
      }
      
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
      
      // Create the target directory
      final targetDir = path.join(
        appDir.path,
        'assets',
        'questions',
        collection,
      );
      
      // Create the directory if it doesn't exist
      final dir = Directory(targetDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        print('Created directory: $targetDir');
      }

      // Get the full file path
      final filePath = await _getFilePath(collection, filename);
      print('Target file path: $filePath');

      // Delete existing file if it exists
      final existingFile = File(filePath);
      if (await existingFile.exists()) {
        await existingFile.delete();
        print('Deleted existing file: $filePath');
      }

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
      collection,
      filename,
    );
  }

  /// Gets the size of a downloaded file in bytes
  static Future<int> getFileSize(String collection, String filename) async {
    try {
      final filePath = await _getFilePath(collection, filename);
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      print('Error getting file size: $e');
      return 0;
    }
  }

  /// Checks if a file is already downloaded and matches the expected size
  static Future<(bool, bool)> isFileDownloadedAndValid(
    String collection,
    String filename,
    int expectedSize,
  ) async {
    try {
      // Validate collection
      if (!validCollections.contains(collection)) {
        throw Exception('Invalid collection: $collection. Must be one of: $validCollections');
      }
      
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
          
          // Check file size
          final actualSize = await file.length();
          final sizeMatches = expectedSize > 0 && actualSize == expectedSize;
          
          return (true, sizeMatches);
        } catch (e) {
          print('File exists but is not valid JSON: $e');
          return (false, false);
        }
      }
      return (false, false);
    } catch (e) {
      print('Error checking file existence: $e');
      return (false, false);
    }
  }
}
