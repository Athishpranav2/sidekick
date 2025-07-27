class Comment {
  final String id;
  final String content;
  final String username;
  final bool isAnonymous;
  final String timestamp;

  Comment({
    required this.id,
    required this.content,
    required this.username,
    required this.isAnonymous,
    required this.timestamp,
  });
}
