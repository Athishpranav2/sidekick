import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Support Section
              _buildSection(
                title: 'Get in Touch',
                children: [
                  _buildContactCard(
                    icon: CupertinoIcons.mail_solid,
                    title: 'Email Support',
                    subtitle: 'Get help via email',
                    contact: 'sidekickk.official@gmail.com',
                    onTap: () => _sendEmail(context),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // FAQ Section
              _buildSection(
                title: 'Frequently Asked Questions',
                children: [
                  _buildFAQTile(
                    question: 'How does the matching system work?',
                    answer:
                        'Our algorithm matches you based on your preferences, interests, and compatibility factors.',
                  ),
                  _buildFAQTile(
                    question: 'Can I delete my account?',
                    answer:
                        'Yes, you can delete your account from Profile > Settings > Delete Account. This action is permanent.',
                  ),
                  _buildFAQTile(
                    question: 'How do I report inappropriate content?',
                    answer:
                        'Use the report button on any post or message. Our team reviews all reports within 24 hours.',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // App Info Section
              _buildSection(
                title: 'App Information',
                children: [
                  _buildInfoTile(
                    icon: CupertinoIcons.device_phone_portrait,
                    title: 'App Version',
                    value: '1.0.0',
                  ),
                  _buildInfoTile(
                    icon: CupertinoIcons.doc_text_fill,
                    title: 'Terms of Service',
                    value: 'View terms and conditions',
                    onTap: () => _openTermsOfService(),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Emergency Note
              _buildEmergencyNote(size),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String contact,
    VoidCallback? onTap,
    bool isInfo = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.systemRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.systemRed, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        contact,
                        style: TextStyle(
                          color: isInfo
                              ? const Color(0xFF8E8E93)
                              : AppColors.systemRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isInfo)
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: Color(0xFF8E8E93),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQTile({required String question, required String answer}) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        expansionTileTheme: const ExpansionTileThemeData(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: AppColors.systemRed,
        collapsedIconColor: const Color(0xFF8E8E93),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              answer,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.systemRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.systemRed, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: Color(0xFF8E8E93),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyNote(Size size) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9500), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: Color(0xFFFF9500),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Emergency Support',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'If you\'re experiencing a mental health emergency or crisis, please contact your local emergency services or a mental health crisis hotline immediately.',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'sidekickk.official@gmail.com',
      queryParameters: {
        'subject': 'Sidekick App - Help Request',
        'body':
            'Hi Sidekick Team,\n\nI need help with:\n\n[Please describe your issue here]\n\nThanks!',
      },
    );

    try {
      HapticFeedback.lightImpact();
      await launchUrl(emailUri);
    } catch (e) {
      if (context.mounted) {
        // Copy email to clipboard as fallback
        await Clipboard.setData(
          const ClipboardData(text: 'sidekickk.official@gmail.com'),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email address copied to clipboard'),
            backgroundColor: AppColors.systemRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openTermsOfService() async {
    // TODO: Add your terms of service URL
    HapticFeedback.lightImpact();
  }
}
