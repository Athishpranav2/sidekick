import 'package:flutter/material.dart';

class Post {
  final String id;
  final String content;
  final bool isAnonymous;
  final String? username;
  final String? gender; // 'male', 'female', or null for anonymous
  final String timestamp;
  int likes; // Made mutable for like functionality
  final int comments;
  final Color cardColor;

  Post({
    required this.id,
    required this.content,
    required this.isAnonymous,
    this.username,
    this.gender,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.cardColor,
  });
}
