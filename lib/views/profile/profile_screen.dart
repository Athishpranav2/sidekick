import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          // Fetch user data if it's not already loaded or loading
          if (userProvider.user == null && !userProvider.isLoading) {
            final firebaseUser = FirebaseAuth.instance.currentUser;
            if (firebaseUser != null) {
              // Use a post-frame callback to avoid calling setState during a build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<UserProvider>().fetchUserData(firebaseUser.uid);
              });
            }
          }

          if (userProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.0,
              ),
            );
          }

          final UserModel? user = userProvider.user;

          if (user == null) {
            return _buildErrorState(context, userProvider, size);
          }

          return RefreshIndicator(
            onRefresh: () => userProvider.fetchUserData(user.uid),
            backgroundColor: const Color(0xFF1C1C1E),
            color: Colors.white,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                _buildSliverAppBar(context, user, size),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.025),
                      _buildUserInfo(user, size),
                      SizedBox(height: size.height * 0.04),
                      _buildStatsSection(size),
                      SizedBox(height: size.height * 0.05),
                      _buildProfileSections(context, user, size),
                      SizedBox(height: size.height * 0.15),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, UserModel user, Size size) {
    return SliverAppBar(
      expandedHeight: size.height * 0.25,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      elevation: 0,
      automaticallyImplyLeading: false, // Removes back button
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          // The gradient has been removed and replaced with a solid color
          color: Colors.black,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: size.height * 0.05),
                _buildProfileAvatar(user, size),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(
            right: size.width * 0.04,
            top: size.height * 0.01,
          ),
          child: Material(
            color: const Color(0xFF1C1C1E).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showSignOutDialog(context, size),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.logout, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(UserModel user, Size size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: size.width * 0.15,
        backgroundColor: const Color(0xFF2C2C2E),
        backgroundImage: user.photoURL != null
            ? NetworkImage(user.photoURL!)
            : null,
        child: user.photoURL == null
            ? Text(
                user.initials,
                style: TextStyle(
                  fontSize: size.width * 0.12,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildUserInfo(UserModel user, Size size) {
    String displayName = user.displayName ?? 'No Name';
    if (displayName.length > 20) {
      displayName = '${displayName.substring(0, 18)}...';
    }

    return Column(
      children: [
        Text(
          displayName,
          style: TextStyle(
            fontSize: size.width * 0.07,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: size.height * 0.01),
        Text(
          '@${user.username ?? 'no_username'}',
          style: TextStyle(
            fontSize: size.width * 0.04,
            color: const Color(0xFF8E8E93),
            fontWeight: FontWeight.w400,
          ),
        ),
        if (user.department != null || user.year != null) ...[
          SizedBox(height: size.height * 0.015),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.007,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${user.departmentShort} • ${user.year ?? ''}'.trim(),
              style: TextStyle(
                fontSize: size.width * 0.035,
                color: const Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsSection(Size size) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
      padding: EdgeInsets.symmetric(vertical: size.height * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('0', 'Meetups', Icons.people_outline, size),
          Container(
            height: size.height * 0.05,
            width: 1,
            color: const Color(0xFF2C2C2E),
          ),
          _buildStatItem('0', 'Vents', Icons.chat_bubble_outline, size),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Size size) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFDC2626), // Changed to red theme
          size: size.width * 0.06,
        ),
        SizedBox(height: size.height * 0.01),
        Text(
          value,
          style: TextStyle(
            fontSize: size.width * 0.06,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: size.height * 0.005),
        Text(
          label,
          style: TextStyle(
            fontSize: size.width * 0.032,
            color: const Color(0xFF8E8E93),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSections(
    BuildContext context,
    UserModel user,
    Size size,
  ) {
    return Column(
      children: [
        _buildSection(
          size: size,
          title: 'Account Information',
          children: [
            _buildProfileOption(
              size: size,
              icon: Icons.mail_outline,
              title: 'Email',
              subtitle: user.email,
              showArrow: false,
            ),
            _buildProfileOption(
              size: size,
              icon: Icons.school_outlined,
              title: 'Department',
              subtitle: user.department ?? 'Not set',
              showArrow: false,
            ),
            _buildProfileOption(
              size: size,
              icon: Icons.calendar_today_outlined,
              title: 'Academic Year',
              subtitle: user.year ?? 'Not set',
              showArrow: false,
            ),
          ],
        ),
        SizedBox(height: size.height * 0.04),
        _buildSection(
          size: size,
          title: 'Settings',
          children: [
            _buildProfileOption(
              size: size,
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              subtitle: 'Update your information',
              showArrow: true,
              onTap: () {
                /* TODO: Navigate to edit profile screen */
              },
            ),
            _buildProfileOption(
              size: size,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage your preferences',
              showArrow: true,
              onTap: () {
                /* TODO: Navigate to notifications settings */
              },
            ),
            _buildProfileOption(
              size: size,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy',
              subtitle: 'Control your data',
              showArrow: true,
              onTap: () {
                /* TODO: Navigate to privacy settings */
              },
            ),
          ],
        ),
        SizedBox(height: size.height * 0.04),
        _buildSection(
          size: size,
          title: 'Support',
          children: [
            _buildProfileOption(
              size: size,
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get assistance',
              showArrow: true,
              onTap: () {
                /* TODO: Navigate to help */
              },
            ),
            _buildProfileOption(
              size: size,
              icon: Icons.logout_outlined,
              title: 'Sign Out',
              subtitle: 'Log out of your account',
              showArrow: false,
              isDestructive: true,
              onTap: () => _showSignOutDialog(context, size),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required Size size,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.01,
          ),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: size.width * 0.032,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8E8E93),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildProfileOption({
    required Size size,
    required IconData icon,
    required String title,
    required String subtitle,
    bool showArrow = false,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    final Color iconColor = isDestructive
        ? const Color(0xFFFF453A)
        : const Color(0xFFDC2626); // Changed to red theme

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.05,
            vertical: size.height * 0.02,
          ),
          child: Row(
            children: [
              Container(
                width: size.width * 0.08,
                height: size.width * 0.08,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: size.width * 0.045),
              ),
              SizedBox(width: size.width * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive ? iconColor : Colors.white,
                        fontSize: size.width * 0.04,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: size.height * 0.0025),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: const Color(0xFF8E8E93),
                        fontSize: size.width * 0.035,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showArrow)
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF8E8E93),
                  size: size.width * 0.05,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, Size size) async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: size.width * 0.045,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(
            color: const Color(0xFF8E8E93),
            fontSize: size.width * 0.038,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05,
                vertical: size.height * 0.015,
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white, // Changed from blue
                fontWeight: FontWeight.w500,
                fontSize: size.width * 0.04,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.05,
                vertical: size.height * 0.015,
              ),
            ),
            child: Text(
              'Sign Out',
              style: TextStyle(
                color: const Color(0xFFFF453A), // Kept a destructive red color
                fontWeight: FontWeight.w600,
                fontSize: size.width * 0.04,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await context.read<AuthService>().signOut();
        context.read<UserProvider>().clearUser();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: const Color(0xFFFF453A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildErrorState(
    BuildContext context,
    UserProvider userProvider,
    Size size,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size.width * 0.2,
            height: size.width * 0.2,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person_off_outlined,
              color: const Color(0xFF8E8E93),
              size: size.width * 0.1,
            ),
          ),
          SizedBox(height: size.height * 0.03),
          Text(
            'Unable to Load Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: size.width * 0.05,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            'Please check your connection and try again',
            style: TextStyle(
              color: const Color(0xFF8E8E93),
              fontSize: size.width * 0.038,
            ),
          ),
          SizedBox(height: size.height * 0.04),
          SizedBox(
            width: size.width * 0.3,
            height: size.height * 0.055,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFFDC2626,
                ), // Changed to red theme
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: () {
                final firebaseUser = FirebaseAuth.instance.currentUser;
                if (firebaseUser != null) {
                  userProvider.fetchUserData(firebaseUser.uid);
                }
              },
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: size.width * 0.04,
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
