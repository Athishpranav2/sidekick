import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
      // Check if Apple Sign In is available
      if (!await SignInWithApple.isAvailable()) {
        throw Exception('Apple Sign In is not available on this device.');
      }

      // Request credentials from Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.sidekick.campus.service', // Your app's service ID
          redirectUri: Uri.parse(
            'https://sidekicker-4ef1b.firebaseapp.com/__/auth/handler',
          ),
        ),
      );

      // Create OAuth provider for Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
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
      print("Apple Auth Error: $e");
      rethrow;
    }
  }

  // Check if Apple Sign In is available on this platform
  Future<bool> isAppleSignInAvailable() async {
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
