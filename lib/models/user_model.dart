// Create this file: models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? username;
  final String? photoURL;
  final bool onboardingCompleted;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String? department;
  final String? year;
  final String? rollNumber;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.username,
    this.photoURL,
    this.onboardingCompleted = false,
    this.createdAt,
    this.lastLoginAt,
    this.department,
    this.year,
    this.rollNumber,
  });

  // Convert from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      username: data['username'],
      photoURL: data['photoURL'],
      onboardingCompleted: data['onboardingCompleted'] ?? false,
      createdAt: data['createdAt']?.toDate(),
      lastLoginAt: data['lastLoginAt']?.toDate(),
      department: data['department'],
      year: data['year'],
      rollNumber: data['rollNumber'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'username_lower': username?.toLowerCase(),
      'photoURL': photoURL,
      'onboardingCompleted': onboardingCompleted,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'department': department,
      'year': year,
      'rollNumber': rollNumber,
    };
  }

  // Create copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    String? photoURL,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? department,
    String? year,
    String? rollNumber,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoURL: photoURL ?? this.photoURL,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      department: department ?? this.department,
      year: year ?? this.year,
      rollNumber: rollNumber ?? this.rollNumber,
    );
  }

  String get firstName {
    if (displayName == null || displayName!.isEmpty) return 'User';
    return displayName!.split(' ').first;
  }

  String get departmentShort {
    if (department == null) return '';

    Map<String, String> deptMap = {
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

    return deptMap[department] ?? department!.substring(0, 3).toUpperCase();
  }

  // Get initials for avatar
  String get initials {
    if (displayName == null || displayName!.isEmpty) return 'U';
    List<String> names = displayName!.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return displayName![0].toUpperCase();
  }

  // Check if profile is complete
  bool get isProfileComplete {
    return department != null &&
        year != null &&
        rollNumber != null &&
        displayName != null;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, onboardingCompleted: $onboardingCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
