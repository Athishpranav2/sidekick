import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'About App',
          style: TextStyle(
            fontSize: size.width * 0.045,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              SizedBox(height: size.height * 0.04),

              // App Logo/Icon
              Center(
                child: Container(
                  width: size.width * 0.25,
                  height: size.width * 0.25,
                  decoration: BoxDecoration(
                    color: AppColors.systemRed,
                    borderRadius: BorderRadius.circular(size.width * 0.06),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.systemRed.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.chat_bubble_2_fill,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.04),

              // App Name
              Center(
                child: Text(
                  'Sidekick',
                  style: TextStyle(
                    fontSize: size.width * 0.08,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.01),

              // App Tagline
              Center(
                child: Text(
                  'Connect, Share, Discover',
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8E8E93),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.06),

              // Version Info
              _buildInfoCard(
                size,
                title: 'Version',
                subtitle: '1.0.0',
                icon: CupertinoIcons.info_circle_fill,
              ),

              SizedBox(height: size.height * 0.02),

              // Build Info
              _buildInfoCard(
                size,
                title: 'Build',
                subtitle: '2025.1.0',
                icon: CupertinoIcons.gear_alt_fill,
              ),

              SizedBox(height: size.height * 0.06),

              // Features Section
              Text(
                'Features',
                style: TextStyle(
                  fontSize: size.width * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: size.height * 0.02),

              _buildFeatureCard(
                size,
                icon: CupertinoIcons.chat_bubble_2_fill,
                title: 'Side Talk',
                description:
                    'Share your thoughts anonymously with the campus community',
                color: AppColors.systemRed,
              ),

              SizedBox(height: size.height * 0.015),

              _buildFeatureCard(
                size,
                icon: CupertinoIcons.person_2_fill,
                title: 'Side Table',
                description:
                    'Connect with other students for meetups and conversations',
                color: const Color(0xFF10B981),
              ),

              SizedBox(height: size.height * 0.015),

              _buildFeatureCard(
                size,
                icon: CupertinoIcons.person_crop_circle_fill,
                title: 'Profile Management',
                description:
                    'Customize your profile and manage your information',
                color: const Color(0xFF3B82F6),
              ),

              SizedBox(height: size.height * 0.06),

              // Developer Info
              _buildModernSection(
                size,
                title: 'Developer',
                children: [
                  _buildDeveloperCard(
                    size,
                    name: 'Sidekick Team',
                    role: 'Development Team',
                    email: 'team@sidekick.app',
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.04),

              // Copyright
              Center(
                child: Text(
                  '© 2025 Sidekick. All rights reserved.',
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8E8E93),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    Size size, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(size.width * 0.04),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: size.width * 0.12,
            height: size.width * 0.12,
            decoration: BoxDecoration(
              color: AppColors.systemRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(size.width * 0.03),
            ),
            child: Icon(
              icon,
              color: AppColors.systemRed,
              size: size.width * 0.06,
            ),
          ),
          SizedBox(width: size.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF8E8E93),
                    fontSize: size.width * 0.035,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: size.height * 0.005),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    Size size, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(size.width * 0.04),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: size.width * 0.12,
            height: size.width * 0.12,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(size.width * 0.03),
            ),
            child: Icon(icon, color: color, size: size.width * 0.06),
          ),
          SizedBox(width: size.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: size.height * 0.005),
                Text(
                  description,
                  style: TextStyle(
                    color: const Color(0xFF8E8E93),
                    fontSize: size.width * 0.035,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection(
    Size size, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: size.width * 0.045,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: size.height * 0.02),
        ...children,
      ],
    );
  }

  Widget _buildDeveloperCard(
    Size size, {
    required String name,
    required String role,
    required String email,
  }) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(size.width * 0.04),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: size.width * 0.04,
                backgroundColor: AppColors.systemRed.withOpacity(0.1),
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: AppColors.systemRed,
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: size.width * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.04,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      role,
                      style: TextStyle(
                        color: const Color(0xFF8E8E93),
                        fontSize: size.width * 0.035,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.015),
          Row(
            children: [
              Icon(
                CupertinoIcons.mail_solid,
                color: AppColors.systemRed,
                size: size.width * 0.04,
              ),
              SizedBox(width: size.width * 0.02),
              Text(
                email,
                style: TextStyle(
                  color: const Color(0xFF8E8E93),
                  fontSize: size.width * 0.035,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
