import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/premium_level.dart';
import '../models/download_item.dart';
import '../services/device_verification_service.dart';
import '../services/secure_download_service.dart';
import '../services/user_cache_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'payment_methods_screen.dart';
import 'downloaded_files_screen.dart';

class DownloadContentsScreen extends StatefulWidget {
  const DownloadContentsScreen({super.key});

  @override
  State<DownloadContentsScreen> createState() => _DownloadContentsScreenState();
}

class _DownloadContentsScreenState extends State<DownloadContentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeviceVerificationService _deviceVerification = DeviceVerificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  PremiumLevel _currentPremiumLevel = PremiumLevel.zero;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Map to store download items grouped by collection
  final Map<String, List<DownloadItem>> _downloadItems = {
    'academic_year': [],
    'model_exams': [],
    'subject_chapters_questions': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeData();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Create necessary directories
      final appDir = await getApplicationDocumentsDirectory();
      final questionsDir = Directory('${appDir.path}/assets/questions');
      if (!await questionsDir.exists()) {
        await questionsDir.create(recursive: true);
      }

      // Load premium level
      await _loadPremiumLevel();
      
      // Load download items
      await _loadDownloadItems();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPremiumLevel() async {
    try {
      final level = await UserCacheService.getCachedPremiumLevel();
      setState(() {
        _currentPremiumLevel = _getPremiumLevelFromString(level);
      });
    } catch (e) {
      setState(() {
        _currentPremiumLevel = PremiumLevel.zero;
        _errorMessage = 'Error loading premium level: $e';
      });
    }
  }

  PremiumLevel _getPremiumLevelFromString(String level) {
    switch (level.toLowerCase()) {
      case 'basic':
        return PremiumLevel.basic;
      case 'pro':
        return PremiumLevel.pro;
      case 'elite':
        return PremiumLevel.elite;
      default:
        return PremiumLevel.zero;
    }
  }

  Future<void> _loadDownloadItems() async {
    try {
      // Clear existing items
      _downloadItems.forEach((key, _) => _downloadItems[key]?.clear());

      // Load items from each collection
      for (String collection in _downloadItems.keys) {
        final snapshot = await _firestore.collection(collection).get();
        final items = snapshot.docs
            .map((doc) => DownloadItem.fromFirestore(doc, collection))
            .toList();
            
        // Check if each file is already downloaded
        for (var item in items) {
          final isDownloaded = await SecureDownloadService.isFileDownloaded(
            item.collection,
            item.filename,
          );
          if (!isDownloaded) {
            _downloadItems[collection]?.add(item);
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading items: $e';
      });
    }
  }

  Future<void> _handleDownload(DownloadItem item) async {
    try {
      final canAccess = await _deviceVerification.canAccessPremiumLevel(item.reqLevel);

      if (!canAccess) {
        if (!mounted) return;
        _showUpgradeDialog(item.reqLevel);
        return;
      }

      // Debug prints
      print('Attempting to download:');
      print('Filename: ${item.filename}');
      print('Collection: ${item.collection}');
      print('URL: ${item.downloadUrl}');

      if (item.filename.isEmpty) {
        _showErrorMessage('Invalid filename');
        return;
      }

      if (item.downloadUrl.isEmpty) {
        _showErrorMessage('Invalid download URL');
        return;
      }

      // Start download
      setState(() {
        item.isDownloading = true;
        item.progress = 0;
      });

      final success = await SecureDownloadService.downloadFile(
        url: item.downloadUrl,
        collection: item.collection,
        filename: item.filename,
        onProgress: (received, total) {
          if (total != -1) {
            setState(() {
              item.progress = received / total;
            });
          }
        },
      );

      if (success && mounted) {
        setState(() {
          _downloadItems[item.collection]?.remove(item);
        });
        _showSuccessMessage('${item.filename} downloaded successfully');
      } else if (mounted) {
        _showErrorMessage('Failed to download ${item.filename}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error downloading ${item.filename}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          item.isDownloading = false;
          item.progress = 0;
        });
      }
    }
  }

  void _showUpgradeDialog(PremiumLevel requiredLevel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Upgrade to ${requiredLevel.name.toUpperCase()}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'This content requires ${requiredLevel.name.toUpperCase()} access.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upgrade your account to access premium content!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentMethodsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.star),
            label: const Text('Upgrade Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildDownloadCard(DownloadItem item) {
    final bool canDownload = item.reqLevel.index <= _currentPremiumLevel.index;
    final cardColor = canDownload ? null : Colors.grey.shade100;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardColor,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              _getCollectionIcon(item.collection),
              color: _getCollectionColor(item.collection),
              size: 32,
            ),
            title: Text(
              item.displayName, // Use displayName for UI
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Required Level: ${item.reqLevel.name.toUpperCase()}',
                  style: TextStyle(
                    color: canDownload ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: item.isDownloading
                ? const SizedBox(width: 32, height: 32)
                : IconButton(
                    icon: Icon(
                      canDownload ? Icons.download : Icons.lock_outline,
                      color: canDownload ? Colors.blue : Colors.grey,
                    ),
                    onPressed: canDownload
                        ? () => _handleDownload(item)
                        : () => _showUpgradeDialog(item.reqLevel),
                  ),
          ),
          if (item.isDownloading) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: item.progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getCollectionColor(item.collection),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(item.progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
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

  Widget _buildCollectionGroup(String collection, List<DownloadItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getCollectionColor(collection).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getCollectionIcon(collection),
                  color: _getCollectionColor(collection),
                ),
                const SizedBox(width: 8),
                Text(
                  collection.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getCollectionColor(collection),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getCollectionColor(collection),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(_buildDownloadCard),
        ],
      ),
    );
  }

  Widget _buildTabContent(PremiumLevel level) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final hasItems = _downloadItems.values.any((items) => items.isNotEmpty);
    
    if (!hasItems) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'All content downloaded!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new content',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _downloadItems.entries.map((entry) {
          final collectionItems = entry.value
              .where((item) => item.reqLevel.index <= level.index)
              .toList();
          return _buildCollectionGroup(entry.key, collectionItems);
        }).toList(),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Delete All Downloads?'),
          ],
        ),
        content: const Text(
          'This will delete all downloaded files. You will need to download them again to access them. Are you sure you want to proceed?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllDownloads();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllDownloads() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final appDir = await getApplicationDocumentsDirectory();
      final questionsDir = Directory('${appDir.path}/assets/questions');
      
      if (await questionsDir.exists()) {
        // Delete all files in each collection directory
        for (String collection in _downloadItems.keys) {
          final collectionDir = Directory('${questionsDir.path}/$collection');
          if (await collectionDir.exists()) {
            await collectionDir.delete(recursive: true);
            print('Deleted directory: ${collectionDir.path}');
          }
        }
        
        // Recreate the base directories
        await questionsDir.create(recursive: true);
      }

      // Reload the download items
      await _loadDownloadItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('All downloads deleted successfully'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error deleting downloads: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error deleting downloads: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Contents'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            tooltip: 'View Downloaded Files',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DownloadedFilesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete All Downloads',
            onPressed: _showDeleteConfirmationDialog,
          ),
        ],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Zero'),
            Tab(text: 'Basic'),
            Tab(text: 'Pro'),
            Tab(text: 'Elite'),
          ],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading content...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(PremiumLevel.zero),
                _buildTabContent(PremiumLevel.basic),
                _buildTabContent(PremiumLevel.pro),
                _buildTabContent(PremiumLevel.elite),
              ],
            ),
    );
  }
}
