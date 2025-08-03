import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ad_model.dart';
import '../../core/constants/app_colors.dart';

class AdCard extends StatelessWidget {
  final AdModel ad;
  final VoidCallback? onTap;

  const AdCard({super.key, required this.ad, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _handleAdTap(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with sponsor info
                Row(
                  children: [
                    if (ad.sponsorLogoUrl != null) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(ad.sponsorLogoUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ad.sponsorName != null)
                            Text(
                              ad.sponsorName!,
                              style: AppTypography.footnote.copyWith(
                                color: const Color(0xFF8E8E93),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Row(
                            children: [
                              Text(
                                'Sponsored',
                                style: AppTypography.caption1.copyWith(
                                  color: AppColors.systemRed.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.info_outline,
                                color: AppColors.systemRed.withOpacity(0.8),
                                size: 12,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_horiz,
                      color: const Color(0xFF8E8E93),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Ad content
                if (ad.imageUrl != null) ...[
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(ad.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                Text(
                  ad.title,
                  style: AppTypography.title2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  ad.description,
                  style: AppTypography.subheadline.copyWith(
                    color: const Color(0xFF8E8E93),
                    height: 1.4,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 16),

                // Call to action button
                if (ad.callToAction != null)
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.systemRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        ad.callToAction!,
                        style: AppTypography.callout.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAdTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }

    if (ad.targetUrl != null) {
      _launchUrl(ad.targetUrl!);
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }
}
