import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String otherUserId;
  final String meetingTime; // Add meeting time parameter

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.meetingTime, // e.g., "03:20 PM"
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FocusNode _textFieldFocus = FocusNode();

  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isTyping = false;
  Timer? _typingTimer;
  Timer? _countdownTimer;

  // Chat timing states
  ChatState _chatState = ChatState.locked;
  Duration _remainingTime = Duration.zero;
  DateTime? _meetingDateTime;
  DateTime? _chatUnlockTime;
  DateTime? _chatEndTime;

  // Premium color palette
  static const Color primaryRed = Color(0xFFFF3B30);
  static const Color darkRed = Color(0xFFD70015);
  static const Color backgroundBlack = Color(0xFF000000);
  static const Color cardBackground = Color(0xFF1C1C1E);
  static const Color inputBackground = Color(0xFF2C2C2E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color bubbleReceived = Color(0xFF3A3A3C);
  static const Color divider = Color(0xFF38383A);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeChatTiming();
    _messageController.addListener(_onTextChanged);
    _scrollToBottom();
  }

  void _setupAnimations() {
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sendButtonAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.elasticOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initializeChatTiming() {
    // Parse meeting time (assuming today's date)
    final now = DateTime.now();
    final meetingTime = _parseMeetingTime(widget.meetingTime);

    _meetingDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      meetingTime.hour,
      meetingTime.minute,
    );

    // If meeting time has passed today, assume it's tomorrow
    if (_meetingDateTime!.isBefore(now)) {
      _meetingDateTime = _meetingDateTime!.add(const Duration(days: 1));
    }

    _chatUnlockTime = _meetingDateTime!.subtract(const Duration(minutes: 5));
    _chatEndTime = _meetingDateTime!.add(const Duration(minutes: 30));

    _updateChatState();
    _startCountdownTimer();
  }

  DateTime _parseMeetingTime(String timeString) {
    // Parse time format like "03:20 PM"
    final parts = timeString.split(' ');
    final timePart = parts[0];
    final period = parts[1];

    final timeParts = timePart.split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    if (period.toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    } else if (period.toUpperCase() == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(
      2000,
      1,
      1,
      hour,
      minute,
    ); // Year/month/day don't matter here
  }

  void _updateChatState() {
    final now = DateTime.now();

    if (now.isBefore(_chatUnlockTime!)) {
      _chatState = ChatState.locked;
      _remainingTime = _chatUnlockTime!.difference(now);
    } else if (now.isBefore(_chatEndTime!)) {
      _chatState = ChatState.active;
      _remainingTime = _chatEndTime!.difference(now);
    } else {
      _chatState = ChatState.expired;
      _remainingTime = Duration.zero;
      _deleteAllMessages(); // Auto-delete messages after 30 minutes
    }
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateChatState();
        });
      }
    });
  }

  Future<void> _deleteAllMessages() async {
    try {
      final messagesRef = _firestore
          .collection('matches')
          .doc(widget.matchId)
          .collection('messages');

      final snapshot = await messagesRef.get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Update match document to indicate chat has expired
      await _firestore.collection('matches').doc(widget.matchId).update({
        'chatExpired': true,
        'chatExpiredAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting messages: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _textFieldFocus.dispose();
    _sendButtonController.dispose();
    _pulseController.dispose();
    _typingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_chatState != ChatState.active) return;

    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_chatState != ChatState.active) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _messageController.clear();
    _textFieldFocus.unfocus();
    HapticFeedback.lightImpact();

    try {
      await _firestore
          .collection('matches')
          .doc(widget.matchId)
          .collection('messages')
          .add({
            'senderId': currentUser.uid,
            'text': text,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'text',
          });

      await _firestore.collection('matches').doc(widget.matchId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUser.uid,
      });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to send message');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: textPrimary)),
        backgroundColor: primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ${duration.inMinutes % 60}m';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      appBar: _buildAppBar(),
      body: _chatState == ChatState.locked
          ? _buildLockedState()
          : _chatState == ChatState.expired
          ? _buildExpiredState()
          : Column(
              children: [
                if (_chatState == ChatState.active) _buildCountdownHeader(),
                Expanded(child: _buildMessagesList()),
                _buildMessageInput(),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: backgroundBlack,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(widget.otherUserId).get(),
        builder: (context, snapshot) {
          String displayName = 'Loading...';
          String initial = '?';

          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            displayName = userData['displayName'] ?? 'User';
            initial = displayName.isNotEmpty
                ? displayName[0].toUpperCase()
                : '?';
          }

          return Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryRed, darkRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCountdownHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryRed.withOpacity(0.8), darkRed.withOpacity(0.8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_outlined, color: textPrimary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Chat expires in ${_formatDuration(_remainingTime)}',
            style: const TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryRed.withOpacity(0.2),
                      darkRed.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: textPrimary,
                  size: 50,
                ),
              ),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Chat Unlocks in',
              style: TextStyle(
                color: textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDuration(_remainingTime),
              style: const TextStyle(
                color: textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chat opens 5 minutes before your meeting at ${widget.meetingTime}',
              style: TextStyle(color: textSecondary, fontSize: 16, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: textSecondary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                color: textSecondary,
                size: 50,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Chat Expired',
              style: TextStyle(
                color: textSecondary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This chat session has ended and all messages have been automatically deleted for privacy.',
              style: TextStyle(color: textSecondary, fontSize: 16, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_chatState != ChatState.active) {
      return const SizedBox();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('matches')
          .doc(widget.matchId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryRed),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryRed.withOpacity(0.3),
                        darkRed.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: textPrimary,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Start the conversation',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index].data() as Map<String, dynamic>;
            final isCurrentUser = message['senderId'] == _auth.currentUser?.uid;
            final showTimeStamp = _shouldShowTimestamp(messages, index);

            return Column(
              children: [
                if (showTimeStamp)
                  _buildTimestamp(message['timestamp'] as Timestamp?),
                _buildMessageBubble(message, isCurrentUser),
              ],
            );
          },
        );
      },
    );
  }

  bool _shouldShowTimestamp(List<QueryDocumentSnapshot> messages, int index) {
    if (index == 0) return true;

    final currentMessage = messages[index].data() as Map<String, dynamic>;
    final previousMessage = messages[index - 1].data() as Map<String, dynamic>;

    final currentTime = currentMessage['timestamp'] as Timestamp?;
    final previousTime = previousMessage['timestamp'] as Timestamp?;

    if (currentTime == null || previousTime == null) return false;

    final timeDiff = currentTime.seconds - previousTime.seconds;
    return timeDiff > 300;
  }

  Widget _buildTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return const SizedBox();

    final date = timestamp.toDate();
    final now = DateTime.now();
    final isToday =
        date.day == now.day && date.month == now.month && date.year == now.year;

    String formattedTime;
    if (isToday) {
      formattedTime =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      formattedTime =
          '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: inputBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            formattedTime,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? LinearGradient(
                        colors: [primaryRed, darkRed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isCurrentUser ? null : bubbleReceived,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isCurrentUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isCurrentUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: isCurrentUser
                    ? [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                message['text'] ?? '',
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final bool canSendMessage = _chatState == ChatState.active;

    return Container(
      decoration: BoxDecoration(
        color: backgroundBlack,
        border: Border(top: BorderSide(color: divider, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.camera_alt_rounded,
                  color: canSendMessage
                      ? textSecondary
                      : textSecondary.withOpacity(0.3),
                  size: 24,
                ),
                onPressed: canSendMessage
                    ? () => HapticFeedback.lightImpact()
                    : null,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: canSendMessage
                        ? inputBackground
                        : inputBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _textFieldFocus.hasFocus && canSendMessage
                          ? primaryRed.withOpacity(0.3)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _textFieldFocus,
                    enabled: canSendMessage,
                    keyboardAppearance: Brightness.dark,
                    style: TextStyle(
                      color: canSendMessage ? textPrimary : textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: canSendMessage ? 'Message' : 'Chat is locked',
                      hintStyle: TextStyle(
                        color: textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: 5,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: canSendMessage ? (_) => _sendMessage() : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedBuilder(
                animation: _sendButtonAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _sendButtonAnimation.value,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: _isTyping && canSendMessage
                            ? LinearGradient(
                                colors: [primaryRed, darkRed],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _isTyping && canSendMessage
                            ? null
                            : inputBackground.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_upward_rounded,
                          color: _isTyping && canSendMessage
                              ? textPrimary
                              : textSecondary.withOpacity(0.5),
                          size: 20,
                        ),
                        onPressed: _isTyping && canSendMessage
                            ? _sendMessage
                            : null,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ChatState {
  locked, // Chat is locked until 5 minutes before meeting
  active, // Chat is active (5 minutes before to 30 minutes after meeting)
  expired, // Chat has expired and messages are deleted
}
