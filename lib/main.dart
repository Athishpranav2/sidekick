import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'views/splash/splash_screen.dart';
import 'views/login/login_screen.dart';
// REMOVE THE OLD HOME SCREEN IMPORT
// import 'views/home/home_screen.dart';
import 'views/onboarding/onboarding_screen.dart';
import 'providers/user_provider.dart';
// ADD THE NEW NAVIGATION CONTAINER IMPORT
import 'views/navigation/navigation_container.dart';
import 'auth_service.dart'; // Keep this import if it's used elsewhere

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style to prevent grey glitch
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF000000),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    // You need to provide your AuthService here if ProfileScreen uses it.
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Sidekick',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000000),
          primarySwatch: Colors.red,
          primaryColor: const Color(0xFFDC2626),
          useMaterial3: true,
          // Fix page transitions to prevent grey background
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          // Set app bar theme
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF000000),
            foregroundColor: Colors.white,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1C1C1E),
            selectedItemColor: Color(0xFFDC2626),
            unselectedItemColor: Color(0xFF8E8E93),
            type: BottomNavigationBarType.fixed,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF1C1C1E),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            contentTextStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
            bodySmall: TextStyle(color: Color(0xFF8E8E93)),
            headlineLarge: TextStyle(color: Colors.white),
            headlineMedium: TextStyle(color: Colors.white),
            headlineSmall: TextStyle(color: Colors.white),
            titleLarge: TextStyle(color: Colors.white),
            titleMedium: TextStyle(color: Colors.white),
            titleSmall: TextStyle(color: Colors.white),
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFDC2626),
            secondary: Color(0xFFDC2626),
            surface: Color(0xFF1C1C1E),
            background: Colors.black,
            error: Color(0xFFFF3B30),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
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
      print('Error checking user status: $e');
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

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
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            bool isNewUser = onboardingSnapshot.data ?? true;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<UserProvider>().fetchUserData(user.uid);
            });

            if (isNewUser) {
              return const OnboardingScreen();
            } else {
              // THIS IS THE LINE TO CHANGE
              return const NavigationContainer();
            }
          },
        );
      },
    );
  }
}
