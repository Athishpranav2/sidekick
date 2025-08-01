import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;
  final int _characterLimit = 280;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: AppAnimations.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (_textController.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot post an empty confession.',
            style: AppTypography.callout.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.systemRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      String? username;
      if (!_isAnonymous) {
        // In a real app, you'd get the username from your user profile data
        // For now, we'll use a placeholder or leave it null if anonymous
        username = user.displayName ?? 'PublicUser';
      }

      await FirebaseFirestore.instance.collection('confessions').add({
        'text': _textController.text.trim(),
        'isAnonymous': _isAnonymous,
        'userId': user.uid,
        'username': username,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [], // Array of user IDs who liked this post
        'comments': [], // Array of comment objects
        'status': 'approved', // Or 'pending' for moderation
        'hearts': 0, // Redundant count for legacy compatibility
      });

      // Navigate back to the previous screen
      if (mounted) {
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your confession has been posted!',
              style: AppTypography.callout.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.systemGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to post confession: ${e.toString()}',
              style: AppTypography.callout.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.systemRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'CREATE POST',
          style: AppTypography.headline.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: AppColors.separator),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.layoutMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compose area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusCard,
                      ),
                      border: Border.all(
                        color: AppColors.separator,
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      maxLength: _characterLimit,
                      autofocus: true,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What\'s on your mind?',
                        hintStyle: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        counterStyle: AppTypography.footnote.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (text) {
                        setState(
                          () {},
                        ); // To update UI based on text changes if needed
                      },
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Anonymous toggle card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                    border: Border.all(color: AppColors.separator, width: 0.5),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      'Post Anonymously',
                      style: AppTypography.callout.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Your identity will be hidden from other users.',
                      style: AppTypography.footnote.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _isAnonymous,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isAnonymous = value;
                      });
                    },
                    activeColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Premium post button
                Container(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isLoading
                          ? [AppColors.separator, AppColors.separator]
                          : [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusButton,
                    ),
                    boxShadow: _isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusButton,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusButton,
                      ),
                      onTap: _isLoading
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              _submitPost();
                            },
                      child: Center(
                        child: _isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.textPrimary,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'POST',
                                    style: AppTypography.callout.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
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
}
