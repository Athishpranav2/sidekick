import 'package:cloud_firestore/cloud_firestore.dart';

class Confession {
  final String id;
  final String text;
  final bool isAnonymous;
  final String? userId;
  final String? username;
  final String? userProfilePic;
  final DateTime timestamp;
  final String status; // 'pending', 'approved', 'rejected'
  final int hearts;
  final int comments;
  final String? category; // 'positive', 'negative', 'sensitive', etc.
  final bool? reported;

  Confession({
    required this.id,
    required this.text,
    required this.isAnonymous,
    this.userId,
    this.username,
    this.userProfilePic,
    required this.timestamp,
    required this.status,
    this.hearts = 0,
    this.comments = 0,
    this.category,
    this.reported,
  });

  factory Confession.fromMap(Map<String, dynamic> data, String docId) {
    return Confession(
      id: docId,
      text: data['text'] ?? '',
      isAnonymous: data['isAnonymous'] ?? true,
      userId: data['userId'],
      username: data['username'],
      userProfilePic: data['userProfilePic'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      hearts: data['hearts'] ?? 0,
      comments: data['comments'] ?? 0,
      category: data['category'],
      reported: data['reported'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isAnonymous': isAnonymous,
      'userId': userId,
      'username': username,
      'userProfilePic': userProfilePic,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'hearts': hearts,
      'comments': comments,
      'category': category,
      'reported': reported,
    };
  }
}
