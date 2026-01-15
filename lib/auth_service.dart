import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Current user getter
  User? get currentUser => _auth.currentUser;

  // Firebase Auth stream to listen to auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // First check if there's already a signed-in user and clear it
      if (_googleSignIn.currentUser != null) {
        await _googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Allow only PSG email domains
      if (!googleUser.email.endsWith('@psgtech.ac.in')) {
        await _googleSignIn.signOut();
        throw Exception('Sorry, only for PSG students for now.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception: ${e.code} - ${e.message}");

      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception(
            'An account already exists with a different sign-in method.',
          );
        case 'invalid-credential':
          throw Exception('Invalid credentials. Please try again.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'network-request-failed':
          throw Exception('Network error. Please check your connection.');
        default:
          throw Exception('Authentication failed. Please try again.');
      }
    } catch (e) {
      print("Other Auth Error: $e");

      // Clean up Google Sign-In state on any error
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        print("Error cleaning up Google Sign-In: $signOutError");
      }

      rethrow;
    }
  }

  // Sign in with Apple
  Future<User?> signInWithApple() async {
    try {
      // On web or Android, use Firebase OAuth provider directly (popup or redirect)
      // Android can't do native Apple Sign-In; sign_in_with_apple uses a web redirect
      // which triggers sessionStorage issues. Use Firebase linkWithPopup/signInWithCredential instead.
      final bool useFirebaseOAuth = kIsWeb || defaultTargetPlatform == TargetPlatform.android;

      print("signInWithApple: useFirebaseOAuth=$useFirebaseOAuth, platform=$defaultTargetPlatform");

      if (useFirebaseOAuth) {
        // For web, set persistence to LOCAL
        if (kIsWeb) {
          try {
            await _auth.setPersistence(Persistence.LOCAL);
          } catch (_) {}
        }

        final provider = OAuthProvider("apple.com");
        provider.addScope('email');
        provider.addScope('name');

        print("signInWithApple: Calling Firebase signInWithProvider for Apple...");

        UserCredential cred;
        if (kIsWeb) {
          // Prefer popup on web
          try {
            cred = await _auth.signInWithPopup(provider);
          } on FirebaseAuthException catch (e) {
            if (e.code == 'popup-blocked' || e.code == 'popup-closed-by-user') {
              await _auth.signInWithRedirect(provider);
              return null; // Will complete on redirect result
            }
            rethrow;
          }
        } else {
          // On Android, signInWithProvider opens system browser / Chrome Custom Tab
          cred = await _auth.signInWithProvider(provider);
        }

        print("signInWithApple: Got credential, user=${cred.user?.uid}, email=${cred.user?.email}");

        final user = cred.user;
        if (user != null && user.email != null && !user.email!.endsWith('@psgtech.ac.in')) {
          await _auth.signOut();
          throw Exception('Sorry, only for PSG students for now.');
        }
        return user;
      }

      // Native iOS/macOS flow using sign_in_with_apple package
      // Check if Apple Sign In is available
      if (!await SignInWithApple.isAvailable()) {
        throw Exception('Apple Sign In is not available on this device.');
      }

      // Generate and use a nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credentials from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.sidekick.campus.service',
          // For mobile this is ignored; for web we use Firebase popup above
          redirectUri: Uri.parse('https://sidekicker-4ef1b.firebaseapp.com/__/auth/handler'),
        ),
      );

      // Create OAuth provider for Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      // Sign in with Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        oauthCredential,
      );

      // Handle display name if it's the first time signing in
      final user = userCredential.user;
      if (user != null && user.displayName == null) {
        final appleDisplayName =
            appleCredential.givenName != null &&
                appleCredential.familyName != null
            ? '${appleCredential.givenName} ${appleCredential.familyName}'
            : null;

        if (appleDisplayName != null) {
          await user.updateDisplayName(appleDisplayName);
        }
      }

      // Apply the same email domain restriction as Google sign-in
      if (user?.email != null && !user!.email!.endsWith('@psgtech.ac.in')) {
        await _auth.signOut();
        throw Exception('Sorry, only for PSG students for now.');
      }

      return user;
    } on SignInWithAppleAuthorizationException catch (e) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          // User cancelled the sign-in
          return null;
        case AuthorizationErrorCode.failed:
          throw Exception('Apple Sign In failed. Please try again.');
        case AuthorizationErrorCode.invalidResponse:
          throw Exception('Invalid response from Apple. Please try again.');
        case AuthorizationErrorCode.notHandled:
          throw Exception('Apple Sign In not handled properly.');
        case AuthorizationErrorCode.unknown:
        default:
          throw Exception('An unknown error occurred during Apple Sign In.');
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Exception for Apple Sign-In: code=${e.code}, message=${e.message}");
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception(
            'An account already exists with a different sign-in method.',
          );
        case 'invalid-credential':
          // Log full details for debugging
          print("Invalid credential details: ${e.credential}, plugin=${e.plugin}");
          throw Exception('Invalid credentials. Please try again.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'network-request-failed':
          throw Exception('Network error. Please check your connection.');
        default:
          print("Unhandled Firebase Auth error code: ${e.code}");
          throw Exception('Authentication failed: ${e.message ?? e.code}');
      }
    } catch (e) {
      print("Apple Auth Error (non-Firebase): $e");
      rethrow;
    }
  }

  // Utils for generating a cryptographically secure nonce for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check if Apple Sign In is available on this platform
  Future<bool> isAppleSignInAvailable() async {
    if (kIsWeb) return true; // Firebase popup/redirect
    if (defaultTargetPlatform == TargetPlatform.android) return true; // Firebase signInWithProvider
    // On iOS/macOS, check native availability
    return await SignInWithApple.isAvailable();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from all services (Google and Apple are handled by Firebase Auth)
      await Future.wait([_googleSignIn.signOut(), _auth.signOut()]);
    } catch (e) {
      print("Error during sign out: $e");
      // Even if there's an error, try to sign out from individual services
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await _auth.signOut();
      } catch (_) {}

      throw Exception('Error during sign out. Please try again.');
    }
  }

  // Disconnect Google account completely (useful for testing)
  Future<void> disconnectGoogle() async {
    try {
      await Future.wait([_googleSignIn.disconnect(), _auth.signOut()]);
    } catch (e) {
      print("Error disconnecting Google: $e");
      throw Exception('Error disconnecting Google account.');
    }
  }

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;

  // Get current user display name
  String? get currentUserDisplayName => _auth.currentUser?.displayName;

  // Get current user photo URL
  String? get currentUserPhotoURL => _auth.currentUser?.photoURL;
}
