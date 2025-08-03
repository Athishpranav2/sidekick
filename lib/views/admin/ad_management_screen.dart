import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ad_model.dart';
import '../../core/services/ad_service.dart';
import '../../core/constants/app_colors.dart';

class AdManagementScreen extends StatefulWidget {
  const AdManagementScreen({super.key});

  @override
  State<AdManagementScreen> createState() => _AdManagementScreenState();
}

class _AdManagementScreenState extends State<AdManagementScreen> {
  List<AdModel> ads = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedAds = await AdService.getActiveAds(limit: 50);
      setState(() {
        ads = fetchedAds;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error loading ads: $e', false);
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Ad Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddAdDialog(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.systemRed),
            )
          : RefreshIndicator(
              onRefresh: _loadAds,
              color: AppColors.systemRed,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  final ad = ads[index];
                  return _buildAdCard(ad);
                },
              ),
            ),
    );
  }

  Widget _buildAdCard(AdModel ad) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          ad.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              ad.description,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ad.isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ad.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: ad.isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (ad.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.systemRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ad.category!,
                      style: TextStyle(
                        color: AppColors.systemRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) => _handleAdAction(value, ad),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Edit', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: ad.isActive ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(
                    ad.isActive ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ad.isActive ? 'Deactivate' : 'Activate',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAdAction(String action, AdModel ad) {
    switch (action) {
      case 'edit':
        _showEditAdDialog(ad);
        break;
      case 'activate':
      case 'deactivate':
        _toggleAdStatus(ad);
        break;
      case 'delete':
        _showDeleteConfirmation(ad);
        break;
    }
  }

  void _toggleAdStatus(AdModel ad) async {
    try {
      await AdService.updateAd(ad.id, {'isActive': !ad.isActive});
      _showSnackBar(ad.isActive ? 'Ad deactivated' : 'Ad activated', true);
      _loadAds();
    } catch (e) {
      _showSnackBar('Error updating ad: $e', false);
    }
  }

  void _showDeleteConfirmation(AdModel ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Ad', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${ad.title}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdService.deleteAd(ad.id);
                _showSnackBar('Ad deleted successfully', true);
                _loadAds();
              } catch (e) {
                _showSnackBar('Error deleting ad: $e', false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddAdDialog() {
    // This would open a form to create a new ad
    _showSnackBar('Add ad functionality coming soon!', true);
  }

  void _showEditAdDialog(AdModel ad) {
    // This would open a form to edit the ad
    _showSnackBar('Edit ad functionality coming soon!', true);
  }
}
