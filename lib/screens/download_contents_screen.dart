import 'package:flutter/material.dart';
import '../models/premium_level.dart';
import '../services/device_verification_service.dart';
import 'payment_methods_screen.dart';

class DownloadContentsScreen extends StatefulWidget {
  const DownloadContentsScreen({super.key});

  @override
  State<DownloadContentsScreen> createState() => _DownloadContentsScreenState();
}

class _DownloadContentsScreenState extends State<DownloadContentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeviceVerificationService _deviceVerification = DeviceVerificationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleDownload(PremiumFeature feature) async {
    final canAccess = await _deviceVerification.canAccessPremiumLevel(feature.level);
    
    if (!canAccess) {
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Premium Access Required'),
          content: Text('You need ${feature.title} access to download these contents. '
              'Please make a purchase to access these materials.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentMethodsScreen(),
                  ),
                );
              },
              child: const Text('Make Purchase'),
            ),
          ],
        ),
      );
      return;
    }

    // TODO: Implement actual download functionality
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting download...')),
    );
  }

  Widget _buildFeatureCard(PremiumFeature feature) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feature.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              feature.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            ...feature.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            Text(
              'ETB ${feature.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleDownload(feature),
                child: const Text('Download Contents'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Contents'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Basic'),
            Tab(text: 'Pro'),
            Tab(text: 'Elite'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: premiumFeatures.map((feature) => SingleChildScrollView(
          child: _buildFeatureCard(feature),
        )).toList(),
      ),
    );
  }
}
