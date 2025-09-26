import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth_service.dart';
import '../profile/terms_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoadingGoogle = false;
  bool _isLoadingApple = false;
  bool _isAppleSignInAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAppleSignInAvailability();
  }

  // Check if Apple Sign In is available
  Future<void> _checkAppleSignInAvailability() async {
    try {
      final isAvailable = await _authService.isAppleSignInAvailable();
      if (mounted) {
        setState(() {
          _isAppleSignInAvailable = isAvailable;
        });
      }
    } catch (e) {
      print('Error checking Apple Sign In availability: $e');
    }
  }

  // Method to create user document if it doesn't exist
  Future<void> _createUserDocumentIfNeeded(User user) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'onboardingCompleted': false,
        });
      }
    } catch (e) {
      print('Error creating user document: $e');
      // Don't throw here, just log - we don't want to break the sign-in flow
    }
  }

  // Method to handle Google sign-in
  Future<void> _handleGoogleSignIn() async {
    // Prevent multiple taps while loading
    if (_isLoadingGoogle || _isLoadingApple) return;

    setState(() {
      _isLoadingGoogle = true;
    });

    try {
      // Attempt to sign in with Google
      await _authService.signInWithGoogle();

      // After successful sign-in, create user document if needed
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _createUserDocumentIfNeeded(user);
      }

      // If successful, the AuthWrapper/SplashScreenWrapper will handle navigation
      // based on onboarding status
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }

    // Always reset loading state after the try-catch block
    if (mounted) {
      setState(() {
        _isLoadingGoogle = false;
      });
    }
  }

  // Method to handle Apple sign-in
  Future<void> _handleAppleSignIn() async {
    // Prevent multiple taps while loading
    if (_isLoadingGoogle || _isLoadingApple) return;

    setState(() {
      _isLoadingApple = true;
    });

    try {
      // Attempt to sign in with Apple
      await _authService.signInWithApple();

      // After successful sign-in, create user document if needed
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _createUserDocumentIfNeeded(user);
      }

      // If successful, the AuthWrapper/SplashScreenWrapper will handle navigation
      // based on onboarding status
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }

    // Always reset loading state after the try-catch block
    if (mounted) {
      setState(() {
        _isLoadingApple = false;
      });
    }
  }

  // Method to show error snackbar
  void _showErrorSnackBar(String errorMessage) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.fixed,
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E), // Dark grey
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3C3C3E), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF48484A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage.replaceFirst('Exception: ', ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
          child: Column(
            children: [
              // Top section (no changes here)
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFDC2626),
                          width: 1,
                        ),
                      ),
                      child: Image.asset(
                        'assets/logo.png', // Corrected path
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.school_rounded,
                            size: 32,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Sidekick',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Campus struggles are real',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFDC2626),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Connect with your college community',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom section with sign-in buttons
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Apple Sign-In Button (only show if available)
                    if (_isAppleSignInAvailable) ...[
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2C2C2E),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _handleAppleSignIn,
                            child: Center(
                              child: _isLoadingApple
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.apple_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Text(
                                          'Continue with Apple',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Google Sign-In Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFDC2626,
                            ).withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _handleGoogleSignIn,
                          child: Center(
                            child: _isLoadingGoogle
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'G',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    // Terms and Privacy (no changes here)
                    const Text(
                      'By continuing, you agree to our ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const TermsScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Terms of Service',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                        const Text(
                          ' and ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E8E93),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const TermsScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
