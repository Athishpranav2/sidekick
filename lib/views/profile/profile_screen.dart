import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../auth_service.dart';
import 'edit_profile_screen.dart';

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
                _buildModernSliverAppBar(context, user, size),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildPremiumUserCard(user, size),
                      const SizedBox(height: 32),
                      _buildModernStatsSection(user, size),
                      const SizedBox(height: 40),
                      _buildModernProfileSections(context, user, size),
                      const SizedBox(height: 120),
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

  Widget _buildModernSliverAppBar(
    BuildContext context,
    UserModel user,
    Size size,
  ) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.black,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      _buildModernActionButton(
                        icon: CupertinoIcons.ellipsis_circle,
                        onTap: () => _showOptionsBottomSheet(context, size),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildPremiumUserCard(UserModel user, Size size) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
      ),
      child: Column(
        children: [
          // Avatar and basic info
          Row(
            children: [
              _buildPremiumAvatar(user, size),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (user.department != null) ...[
                      Text(
                        user.departmentShort,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      user.year ?? 'Academic Year Not Set',
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildVerificationBadge(),
            ],
          ),
          const SizedBox(height: 20),
          // Contact info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.mail_solid,
                    color: Color(0xFFDC2626),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAvatar(UserModel user, Size size) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDC2626), width: 3),
      ),
      padding: const EdgeInsets.all(3),
      child: CircleAvatar(
        radius: 32,
        backgroundColor: const Color(0xFF2C2C2E),
        backgroundImage: user.photoURL != null
            ? NetworkImage(user.photoURL!)
            : null,
        child: user.photoURL == null
            ? Text(
                user.initials,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildVerificationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF34C759).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF34C759).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            CupertinoIcons.checkmark_seal_fill,
            color: Color(0xFF34C759),
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: Color(0xFF34C759),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatsSection(UserModel user, Size size) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: FutureBuilder<int>(
              future: _getMatchesCount(user.uid),
              builder: (context, snapshot) {
                return _buildModernStatCard(
                  title: 'Matches',
                  value: snapshot.data?.toString() ?? '0',
                  icon: CupertinoIcons.person_2_alt,
                  color: const Color(0xFFDC2626),
                  size: size,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder<int>(
              future: _getConfessionsCount(user.uid),
              builder: (context, snapshot) {
                return _buildModernStatCard(
                  title: 'Confessions',
                  value: snapshot.data?.toString() ?? '0',
                  icon: CupertinoIcons.chat_bubble_text_fill,
                  color: const Color(0xFFDC2626),
                  size: size,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Size size,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProfileSections(
    BuildContext context,
    UserModel user,
    Size size,
  ) {
    return Column(
      children: [
        _buildModernSection(
          title: 'Quick Actions',
          children: [
            _buildModernOptionTile(
              icon: CupertinoIcons.pencil_circle_fill,
              title: 'Edit Profile',
              subtitle: 'Update your information',
              color: const Color(0xFFDC2626),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
            ),
            _buildModernOptionTile(
              icon: CupertinoIcons.bell_circle_fill,
              title: 'Notifications',
              subtitle: 'Manage your preferences',
              color: const Color(0xFFDC2626),
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Navigate to notifications
              },
            ),
            _buildModernOptionTile(
              icon: CupertinoIcons.shield_lefthalf_fill,
              title: 'Privacy & Security',
              subtitle: 'Control your data',
              color: const Color(0xFFDC2626),
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Navigate to privacy
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildModernSection(
          title: 'Support & Info',
          children: [
            _buildModernOptionTile(
              icon: CupertinoIcons.question_circle_fill,
              title: 'Help & Support',
              subtitle: 'Get assistance',
              color: const Color(0xFFDC2626),
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Navigate to help
              },
            ),
            _buildModernOptionTile(
              icon: CupertinoIcons.info_circle_fill,
              title: 'About',
              subtitle: 'App information',
              color: const Color(0xFFDC2626),
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Navigate to about
              },
            ),
            _buildModernOptionTile(
              icon: CupertinoIcons.power,
              title: 'Sign Out',
              subtitle: 'Logout from your account',
              color: const Color(0xFFFF3B30),
              onTap: () {
                HapticFeedback.lightImpact();
                _showSignOutDialog(context, size);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
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
      ),
    );
  }

  Widget _buildModernOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
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
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
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

  Future<int> _getMatchesCount(String userId) async {
    try {
      final matchesSnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .where('participants', arrayContains: userId)
          .get();
      return matchesSnapshot.docs.length;
    } catch (e) {
      print('Error getting matches count: $e');
      return 0;
    }
  }

  Future<int> _getConfessionsCount(String userId) async {
    try {
      final confessionsSnapshot = await FirebaseFirestore.instance
          .collection('confessions')
          .where('userId', isEqualTo: userId)
          .get();
      return confessionsSnapshot.docs.length;
    } catch (e) {
      print('Error getting confessions count: $e');
      return 0;
    }
  }

  void _showOptionsBottomSheet(BuildContext context, Size size) {
    showCupertinoModalPopup(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  CupertinoIcons.pencil_circle,
                  color: Color(0xFFDC2626),
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
              _showSignOutDialog(context, size);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.power, color: Color(0xFFFF3B30), size: 18),
                SizedBox(width: 8),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Color(0xFFFF3B30),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
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

  void _showDeleteAccountDialog(BuildContext context, Size size) async {
    final TextEditingController deleteController = TextEditingController();
    bool isDeleting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: const Color(0xFFFF453A),
                size: size.width * 0.06,
              ),
              SizedBox(width: size.width * 0.03),
              Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: size.width * 0.045,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: size.width * 0.8,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This action cannot be undone. All your data will be permanently deleted, including:',
                    style: TextStyle(
                      color: const Color(0xFF8E8E93),
                      fontSize: size.width * 0.038,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  ...[
                    '• Profile information',
                    '• Match history',
                    '• Messages and conversations',
                    '• All app data',
                  ].map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: size.height * 0.005),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: const Color(0xFF8E8E93),
                          fontSize: size.width * 0.035,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  Text(
                    'Type "DELETE" to confirm:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width * 0.04,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  TextField(
                    controller: deleteController,
                    keyboardAppearance: Brightness.dark,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width * 0.04,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type DELETE here',
                      hintStyle: TextStyle(
                        color: const Color(0xFF8E8E93),
                        fontSize: size.width * 0.038,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                        vertical: size.height * 0.015,
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: size.height * 0.015,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDeleting ? const Color(0xFF48484A) : Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: size.width * 0.04,
                ),
              ),
            ),
            TextButton(
              onPressed:
                  (isDeleting || deleteController.text.trim() != 'DELETE')
                  ? null
                  : () async {
                      setState(() => isDeleting = true);

                      try {
                        await _deleteUserAccount(context);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        setState(() => isDeleting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete account: $e'),
                              backgroundColor: const Color(0xFFFF453A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: size.height * 0.015,
                ),
              ),
              child: isDeleting
                  ? SizedBox(
                      width: size.width * 0.04,
                      height: size.width * 0.04,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFFFF453A)),
                      ),
                    )
                  : Text(
                      'Delete Forever',
                      style: TextStyle(
                        color: deleteController.text.trim() == 'DELETE'
                            ? const Color(0xFFFF453A)
                            : const Color(0xFF48484A),
                        fontWeight: FontWeight.w600,
                        fontSize: size.width * 0.04,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUserAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userProvider = context.read<UserProvider>();
    final firestore = FirebaseFirestore.instance;

    try {
      // Show haptic feedback
      HapticFeedback.mediumImpact();

      // Delete user data from all collections
      final batch = firestore.batch();

      // Delete user profile
      batch.delete(firestore.collection('users').doc(user.uid));

      // Delete all matching queue entries
      final queueDocs = await firestore
          .collection('matchingQueue')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (final doc in queueDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete all matches (where user is a participant)
      final matchesDocs = await firestore
          .collection('matches')
          .where('users', arrayContains: user.uid)
          .get();
      for (final doc in matchesDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete all comments by this user
      final commentsDocs = await firestore
          .collection('comments')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (final doc in commentsDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete all confessions by this user
      final confessionsDocs = await firestore
          .collection('confessions')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (final doc in confessionsDocs.docs) {
        batch.delete(doc.reference);
      }

      // Delete all posts by this user
      final postsDocs = await firestore
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (final doc in postsDocs.docs) {
        batch.delete(doc.reference);
      }

      // Commit all deletions
      await batch.commit();

      // Clear user provider
      userProvider.clearUser();

      // Delete Firebase Auth account (this will sign out automatically)
      await user.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deleted successfully'),
            backgroundColor: const Color(0xFF32D74B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // If Firebase Auth deletion fails, the user might need to re-authenticate
      if (e.toString().contains('requires-recent-login')) {
        throw Exception(
          'Please sign out and sign back in, then try deleting your account again.',
        );
      }
      throw Exception('Failed to delete account: $e');
    }
  }
}
