import 'package:flutter/material.dart';

class Post {
  final String id;
  final String content;
  final bool isAnonymous;
  final String? username;
  final String timestamp;
  final int likes;
  final int comments;
  final Color cardColor;

  Post({
    required this.id,
    required this.content,
    required this.isAnonymous,
    this.username,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.cardColor,
  });
}
