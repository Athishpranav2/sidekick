// Create this file: providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSignedIn => _user != null;

  // Initialize user data when app starts
  Future<void> initializeUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await fetchUserData(firebaseUser.uid);
    }
  }

  // Fetch user data from Firestore
  Future<void> fetchUserData(String uid) async {
    try {
      _setLoading(true);
      _clearError();

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        _user = UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          uid,
        );
      } else {
        // Create user document if it doesn't exist
        await _createUserDocument(uid);
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new user document
  Future<void> _createUserDocument(String uid) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    final newUser = UserModel(
      uid: uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      onboardingCompleted: false,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(uid).set(newUser.toFirestore());
    _user = newUser;
  }

  // Update user data
  Future<void> updateUser(UserModel updatedUser) async {
    try {
      _setLoading(true);
      _clearError();

      await _firestore
          .collection('users')
          .doc(updatedUser.uid)
          .update(updatedUser.toFirestore());

      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update user: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding({
    String? department,
    String? year,
    String? rollNumber,
  }) async {
    if (_user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final updatedUser = _user!.copyWith(
        onboardingCompleted: true,
        department: department,
        year: year,
        rollNumber: rollNumber,
      );

      await updateUser(updatedUser);
    } catch (e) {
      _setError('Failed to complete onboarding: $e');
    }
  }

  // Update profile
  Future<void> updateProfile({
    String? displayName,
    String? department,
    String? year,
    String? rollNumber,
  }) async {
    if (_user == null) return;

    try {
      _setLoading(true);
      _clearError();

      final updatedUser = _user!.copyWith(
        displayName: displayName,
        department: department,
        year: year,
        rollNumber: rollNumber,
      );

      await updateUser(updatedUser);
    } catch (e) {
      _setError('Failed to update profile: $e');
    }
  }

  // Update last login time
  Future<void> updateLastLogin() async {
    if (_user == null) return;

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      _user = _user!.copyWith(lastLoginAt: DateTime.now());
      notifyListeners();
    } catch (e) {
      print('Failed to update last login: $e');
      // Don't show error to user for this non-critical operation
    }
  }

  // Clear user data (on logout)
  void clearUser() {
    _user = null;
    _clearError();
    notifyListeners();
  }

  // Stream user data changes in real-time
  Stream<UserModel?> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        final userData = UserModel.fromFirestore(doc.data()!, uid);
        _user = userData;
        notifyListeners();
        return userData;
      }
      return null;
    });
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Refresh user data
  Future<void> refresh() async {
    if (_user != null) {
      await fetchUserData(_user!.uid);
    }
  }
}
