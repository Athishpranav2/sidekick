import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from both services
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
