import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/admob_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class UserProfileCard extends StatefulWidget {
  final String userId; // strict lookup by uid only

  const UserProfileCard({super.key, required this.userId});

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard> {
  bool _isLoading = true;
  String? _displayName;
  String? _department;
  String? _year;
  String? _instagram;
  bool _instagramUnlocked = false;
  String? _error;
  bool _isAdLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('[UserProfileCard] Lookup start: userId=${widget.userId}');
      Map<String, dynamic>? data;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists) {
        data = doc.data();
        debugPrint('[UserProfileCard] Loaded by userId: ${doc.id}');
      } else {
        debugPrint('[UserProfileCard] No user doc for id: ${widget.userId}');
      }

      if (data == null) {
        setState(() {
          _error = 'Profile not found';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _displayName = (data?['displayName'] as String?) ?? 'User';
        _department = data?['department'] as String?;
        _year = data?['year'] as String?;
        _instagram = data?['instagram'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[UserProfileCard] Error: $e');
      setState(() {
        _error = 'Failed to load profile';
        _isLoading = false;
      });
    }
  }

  Future<void> _unlockInstagram() async {
    if (_isAdLoading) return;
    setState(() => _isAdLoading = true);
    try {
      // Load rewarded ad (uses test unit in debug, real in release)
      debugPrint('[Unlock] Start rewarded load');
      final ad = await AdMobService.loadRewardedAd();
      if (ad != null) {
        debugPrint('[Unlock] Rewarded available, preparing show');
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            if (mounted) setState(() => _isAdLoading = false);
            debugPrint('[Unlock] Ad dismissed');
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            if (mounted) setState(() => _isAdLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to show ad. Please try again.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            debugPrint('[Unlock] Failed to show: $error');
          },
        );

        await ad.show(
          onUserEarnedReward: (_, reward) {
            if (!mounted) return;
            setState(() {
              _instagramUnlocked = true;
            });
            _openInstagram();
            debugPrint('[Unlock] Reward earned: ${reward.amount}');
          },
        );
      } else {
        if (!mounted) return;
        setState(() => _isAdLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad unavailable. Please try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        debugPrint('[Unlock] Ad unavailable (load returned null)');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAdLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong starting the ad.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      debugPrint('[Unlock] Exception: $e');
    }
  }

  Future<void> _openInstagram() async {
    if (_instagram == null || _instagram!.isEmpty) return;
    final Uri url = Uri.parse('https://instagram.com/${_instagram!}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Instagram.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 16),
              Container(height: 1, color: const Color(0xFF2C2C2E)),
              const SizedBox(height: 12),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              else ...[
                if (_instagram != null && _instagram!.isNotEmpty)
                  _buildInstagramUnlockRow(),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              (_displayName != null && _displayName!.isNotEmpty
                      ? _displayName![0]
                      : 'U')
                  .toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (_displayName ?? 'User'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              if (_department != null || _year != null) ...[
                if (_department != null)
                  _buildInfoRow(
                    icon: Icons.school_rounded,
                    label: _department!,
                  ),
                if (_year != null) const SizedBox(height: 6),
                if (_year != null)
                  _buildInfoRow(
                    icon: Icons.calendar_month_rounded,
                    label: _year!,
                  ),
              ],
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF3A3A3C), width: 0.8),
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A3A3C), width: 0.8),
          ),
          child: Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstagramUnlockRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3C), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.systemRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _instagramUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              color: AppColors.systemRed,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _instagramUnlocked
                      ? 'Instagram unlocked'
                      : 'Unlock Instagram',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _instagramUnlocked
                      ? '@${_instagram!}'
                      : 'Watch a short ad to view their Instagram',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _instagramUnlocked || _isAdLoading ? null : _unlockInstagram,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.systemRed, const Color(0xFFB91C1C)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isAdLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _instagramUnlocked ? 'View' : 'Unlock',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
