import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../splash/splash_screen.dart';
import '../login/login_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../navigation/navigation_container.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  /// Checks if the user is new (hasn't completed onboarding)
  Future<bool> _isNewUser(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return true;
      }

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      return userData?['onboardingCompleted'] != true;
    } catch (e) {
      debugPrint('Error checking user status: $e');
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash screen while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // No user signed in - show login screen
        if (!snapshot.hasData || snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.read<UserProvider>().user != null) {
              context.read<UserProvider>().clearUser();
            }
          });
          return const LoginScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder<bool>(
          future: _isNewUser(user.uid),
          builder: (context, onboardingSnapshot) {
            // Show splash screen while checking onboarding status
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            bool isNewUser = onboardingSnapshot.data ?? true;

            // Fetch user data for provider
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<UserProvider>().fetchUserData(user.uid);
            });

            // Route to appropriate screen based on onboarding status
            if (isNewUser) {
              return const OnboardingScreen();
            } else {
              return const NavigationContainer();
            }
          },
        );
      },
    );
  }
}
