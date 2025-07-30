import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingLogic {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // PSG Tech departments
  static const List<String> departments = [
    'Computer Science and Engineering',
    'Electronics and Communication Engineering',
    'Electrical and Electronics Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Aeronautical Engineering',
    'Automobile Engineering',
    'Biomedical Engineering',
    'Chemical Engineering',
    'Information Technology',
    'Production Engineering',
    'Textile Technology',
    'Applied Electronics and Instrumentation',
    'Fashion Design and Technology',
    'Computer Applications (MCA)',
    'Business Administration (MBA)',
  ];

  static const List<String> years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
  ];

  // Genders
  static const List<String> genders = ['Male', 'Female'];

  // Check if username is available
  static Future<bool> isUsernameAvailable(String username) async {
    if (username.trim().isEmpty) return false;

    try {
      // Convert to lowercase for consistent checking
      final normalizedUsername = username.trim().toLowerCase();

      // Query Firestore for existing usernames
      final querySnapshot = await _firestore
          .collection('users')
          .where('username_lower', isEqualTo: normalizedUsername)
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      throw Exception('Unable to check username availability');
    }
  }

  // Validate username format
  static String? validateUsername(String username) {
    if (username.trim().isEmpty) {
      return 'Username is required';
    }

    final trimmed = username.trim();

    if (trimmed.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (trimmed.length > 20) {
      return 'Username must be less than 20 characters';
    }

    // Check for valid characters (alphanumeric, underscore, dot)
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(trimmed)) {
      return 'Username can only contain letters, numbers, dots, and underscores';
    }

    // Can't start or end with dot or underscore
    if (trimmed.startsWith('.') ||
        trimmed.startsWith('_') ||
        trimmed.endsWith('.') ||
        trimmed.endsWith('_')) {
      return 'Username cannot start or end with . or _';
    }

    // Can't have consecutive dots or underscores
    if (trimmed.contains('..') ||
        trimmed.contains('__') ||
        trimmed.contains('._') ||
        trimmed.contains('_.')) {
      return 'Username cannot have consecutive special characters';
    }

    return null; // Valid username
  }

  // Generate username suggestions based on display name
  static List<String> generateUsernameSuggestions(String displayName) {
    if (displayName.trim().isEmpty) return [];

    final name = displayName.trim().toLowerCase().replaceAll(' ', '');
    final suggestions = <String>[];

    // Basic name variations
    suggestions.add(name);
    suggestions.add('${name}123');
    suggestions.add('${name}_psg');

    // Add random numbers
    for (int i = 0; i < 3; i++) {
      final randomNum = (100 + (DateTime.now().millisecondsSinceEpoch % 900));
      suggestions.add('$name$randomNum');
    }

    // First name + last initial if available
    final nameParts = displayName.trim().split(' ');
    if (nameParts.length > 1) {
      final firstLast =
          '${nameParts[0].toLowerCase()}${nameParts.last[0].toLowerCase()}';
      suggestions.add(firstLast);
      suggestions.add('${firstLast}123');
    }

    return suggestions.take(5).toList();
  }

  // Complete onboarding process
  static Future<void> completeOnboarding({
    required String username,
    required String department,
    required String year,
    required String gender, // Added gender parameter
    String? displayName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    try {
      // Double-check username availability
      if (!await isUsernameAvailable(username)) {
        throw Exception('Username is no longer available');
      }

      // Create user document
      final userData = {
        'username': username.trim(),
        'username_lower': username.trim().toLowerCase(),
        'displayName': displayName?.trim() ?? user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'department': department,
        'year': year,
        'gender': gender, // Storing gender in Firestore
        'onboardingCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).set(userData);
    } catch (e) {
      print('Error completing onboarding: $e');
      rethrow;
    }
  }

  // Get department abbreviation
  static String getDepartmentAbbreviation(String department) {
    const Map<String, String> deptMap = {
      'Computer Science and Engineering': 'CSE',
      'Electronics and Communication Engineering': 'ECE',
      'Electrical and Electronics Engineering': 'EEE',
      'Mechanical Engineering': 'MECH',
      'Civil Engineering': 'CIVIL',
      'Aeronautical Engineering': 'AERO',
      'Automobile Engineering': 'AUTO',
      'Biomedical Engineering': 'BME',
      'Chemical Engineering': 'CHEM',
      'Information Technology': 'IT',
      'Production Engineering': 'PROD',
      'Textile Technology': 'TEXTILE',
      'Applied Electronics and Instrumentation': 'AEI',
      'Fashion Design and Technology': 'FDT',
      'Computer Applications (MCA)': 'MCA',
      'Business Administration (MBA)': 'MBA',
    };

    return deptMap[department] ?? department.substring(0, 3).toUpperCase();
  }

  // Check if user has completed onboarding
  static Future<bool> hasCompletedOnboarding(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      return data?['onboardingCompleted'] == true;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }
}
