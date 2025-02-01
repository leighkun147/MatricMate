import 'package:cloud_firestore/cloud_firestore.dart';
import 'premium_level.dart';

class DownloadItem {
  final String documentId; // For actual file saving
  final String displayName; // For UI display
  final String downloadUrl;
  final PremiumLevel reqLevel;
  final String collection;
  final int fileSize; // Size of the file in bytes
  final String? stream; // Either 'natural_science' or 'social_science'
  bool isDownloading;
  double progress;
  bool isDownloaded;  // Added property
  bool needsUpdate; // Indicates if local file exists but needs update
  bool justCompleted; // Temporary state to show completion before removal

  DownloadItem({
    required this.documentId,
    required this.displayName,
    required this.downloadUrl,
    required this.reqLevel,
    required this.collection,
    required this.fileSize,
    this.stream,
    this.isDownloading = false,
    this.progress = 0,
    this.isDownloaded = false,
    this.needsUpdate = false,
    this.justCompleted = false,
  });

  // Get the actual filename for saving (always lowercase documentId.json)
  String get filename => '${documentId.toLowerCase()}.json';

  factory DownloadItem.fromFirestore(DocumentSnapshot doc, String collection) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Extract file name from download URL if available
    String urlFileName = '';
    final String downloadUrl = data['download_url'] as String? ?? '';
    if (downloadUrl.isNotEmpty) {
      final uri = Uri.parse(downloadUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        if (lastSegment.toLowerCase().contains('.json')) {
          // Remove .json and convert to lowercase
          urlFileName = lastSegment.toLowerCase().split('.').first;
        }
      }
    }

    // Use URL filename if available, otherwise use lowercase document ID
    final String actualDocumentId = urlFileName.isNotEmpty ? urlFileName : doc.id.toLowerCase();
    
    // Get display name from filename field, fallback to document ID
    String displayName = data['filename'] as String? ?? actualDocumentId;
    
    // Validate download URL
    if (downloadUrl.isEmpty) {
      throw Exception('Download URL is required');
    }

    // Get required level
    String levelStr = (data['req_level'] as String? ?? 'zero').toLowerCase();
    PremiumLevel reqLevel;
    switch (levelStr) {
      case 'basic':
        reqLevel = PremiumLevel.basic;
        break;
      case 'pro':
        reqLevel = PremiumLevel.pro;
        break;
      case 'elite':
        reqLevel = PremiumLevel.elite;
        break;
      default:
        reqLevel = PremiumLevel.zero;
    }

    // Get file size
    final int fileSize = (data['file_size'] as num?)?.toInt() ?? 0;

    // Get stream type
    final String? stream = data['stream'] as String?;

    return DownloadItem(
      documentId: actualDocumentId,
      displayName: displayName,
      downloadUrl: downloadUrl,
      reqLevel: reqLevel,
      collection: collection,
      fileSize: fileSize,
      stream: stream,
    );
  }

  @override
  String toString() {
    return 'DownloadItem(documentId: $documentId, displayName: $displayName, collection: $collection, reqLevel: ${reqLevel.name})';
  }
}
