import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String otherUserId;
  final String meetingTime;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.meetingTime,
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

  // Cached user data to prevent AppBar reloading
  String? _otherUserName;
  String? _otherUserInitial;
  bool _userDataLoaded = false;

  // Chat messages cache for better performance
  final List<ChatMessage> _messages = [];
  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  bool _isTyping = false;
  Timer? _typingTimer;
  Timer? _countdownTimer;
  bool _isKeyboardVisible = false;

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
  static const Color inputBackground = Color(0xFF2C2C2E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color bubbleReceived = Color(0xFF3A3A3C);
  static const Color divider = Color(0xFF38383A);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
    _initializeChatTiming();
    _setupListeners();
    _startMessagesStream();
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

  void _setupListeners() {
    _messageController.addListener(_onTextChanged);
    _textFieldFocus.addListener(_onFocusChanged);

    // Listen to keyboard visibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;
      _isKeyboardVisible = bottomInset > 0;
    });
  }

  void _onFocusChanged() {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    if (_isKeyboardVisible != keyboardVisible) {
      setState(() {
        _isKeyboardVisible = keyboardVisible;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final displayName = userData['displayName'] ?? 'User';

        setState(() {
          _otherUserName = displayName;
          _otherUserInitial = displayName.isNotEmpty
              ? displayName[0].toUpperCase()
              : '?';
          _userDataLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _otherUserName = 'User';
          _otherUserInitial = 'U';
          _userDataLoaded = true;
        });
      }
    }
  }

  void _startMessagesStream() {
    _messagesSubscription = _firestore
        .collection('matches')
        .doc(widget.matchId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
          _onMessagesUpdate,
          onError: (error) {
            print('Messages stream error: $error');
          },
        );
  }

  void _onMessagesUpdate(QuerySnapshot snapshot) {
    if (!mounted) return;

    final newMessages = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ChatMessage(
        id: doc.id,
        senderId: data['senderId'] ?? '',
        text: data['text'] ?? '',
        timestamp: data['timestamp'] as Timestamp?,
        type: data['type'] ?? 'text',
      );
    }).toList();

    // Efficiently update messages list
    final oldLength = _messages.length;
    _messages.clear();
    _messages.addAll(newMessages);

    // Auto-scroll to bottom if new messages
    if (newMessages.length > oldLength) {
      _scrollToBottom();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _initializeChatTiming() {
    final now = DateTime.now();
    final meetingTime = _parseMeetingTime(widget.meetingTime);

    _meetingDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      meetingTime.hour,
      meetingTime.minute,
    );

    // Calculate potential chat end time for today
    final todaysChatEndTime = _meetingDateTime!.add(
      const Duration(minutes: 30),
    );

    // Only move to next day if the entire chat session (including 30-min buffer) has passed
    if (todaysChatEndTime.isBefore(now)) {
      _meetingDateTime = _meetingDateTime!.add(const Duration(days: 1));
    }

    _chatUnlockTime = _meetingDateTime!.subtract(const Duration(minutes: 5));
    _chatEndTime = _meetingDateTime!.add(const Duration(minutes: 30));

    _updateChatState();
    _startCountdownTimer();
  }

  DateTime _parseMeetingTime(String timeString) {
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

    return DateTime(2000, 1, 1, hour, minute);
  }

  void _updateChatState() {
    final now = DateTime.now();
    final previousState = _chatState;

    if (now.isBefore(_chatUnlockTime!)) {
      _chatState = ChatState.locked;
      _remainingTime = _chatUnlockTime!.difference(now);
    } else if (now.isBefore(_chatEndTime!)) {
      _chatState = ChatState.active;
      _remainingTime = _chatEndTime!.difference(now);
    } else {
      _chatState = ChatState.expired;
      _remainingTime = Duration.zero;
      // Only delete messages once when transitioning to expired state
      if (previousState != ChatState.expired) {
        _deleteAllMessages();
      }
    }

    // Debug information (remove in production)
    debugPrint('Chat State Debug:');
    debugPrint('Current time: $now');
    debugPrint('Meeting time: $_meetingDateTime');
    debugPrint('Unlock time: $_chatUnlockTime');
    debugPrint('End time: $_chatEndTime');
    debugPrint('Current state: $_chatState');
    debugPrint('Remaining time: $_remainingTime');
    debugPrint('---');
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
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

      await _firestore.collection('matches').doc(widget.matchId).update({
        'chatExpired': true,
        'chatExpiredAt': FieldValue.serverTimestamp(),
      });

      // Schedule next chat session
      _scheduleNextChatSession();
    } catch (e) {
      debugPrint('Error deleting messages: $e');
    }
  }

  void _scheduleNextChatSession() {
    // Move meeting to next day and recalculate timing
    _meetingDateTime = _meetingDateTime!.add(const Duration(days: 1));
    _chatUnlockTime = _meetingDateTime!.subtract(const Duration(minutes: 5));
    _chatEndTime = _meetingDateTime!.add(const Duration(minutes: 30));

    // Reset to locked state for next session
    _chatState = ChatState.locked;
    _updateChatState();

    debugPrint('Next chat session scheduled for: $_meetingDateTime');
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
    _messagesSubscription?.cancel();
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

    // Optimistic UI - clear input immediately
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
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to send message');
        // Restore text on error
        _messageController.text = text;
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
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlack,
      appBar: _buildOptimizedAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: _chatState == ChatState.locked
            ? _buildLockedState()
            : _chatState == ChatState.expired
            ? _buildExpiredState()
            : Column(
                children: [
                  if (_chatState == ChatState.active) _buildCountdownHeader(),
                  Expanded(child: _buildOptimizedMessagesList()),
                  _buildOptimizedMessageInput(),
                ],
              ),
      ),
    );
  }

  // Optimized AppBar that doesn't rebuild
  PreferredSizeWidget _buildOptimizedAppBar() {
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
      title: _userDataLoaded
          ? Row(
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
                      _otherUserInitial ?? '?',
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
                    _otherUserName ?? 'User',
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
            )
          : const Row(
              children: [
                SizedBox(
                  width: 35,
                  height: 35,
                  child: CircularProgressIndicator(
                    color: primaryRed,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.developer_mode, size: 18),
              label: const Text('Bypass Lock (Test)'),
              onPressed: () {
                _countdownTimer?.cancel();
                setState(() {
                  _chatState = ChatState.active;
                });
                HapticFeedback.heavyImpact();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: darkRed,
                foregroundColor: textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
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

  // Optimized messages list with better performance
  Widget _buildOptimizedMessagesList() {
    if (_chatState != ChatState.active) {
      return const SizedBox();
    }

    if (_messages.isEmpty) {
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isCurrentUser = message.senderId == _auth.currentUser?.uid;
        final showTimeStamp = _shouldShowTimestamp(index);

        return Column(
          children: [
            if (showTimeStamp) _buildTimestamp(message.timestamp),
            _buildOptimizedMessageBubble(message, isCurrentUser),
          ],
        );
      },
    );
  }

  bool _shouldShowTimestamp(int index) {
    if (index == 0) return true;

    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];

    final currentTime = currentMessage.timestamp;
    final previousTime = previousMessage.timestamp;

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

  Widget _buildOptimizedMessageBubble(ChatMessage message, bool isCurrentUser) {
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
                message.text,
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

  Widget _buildOptimizedMessageInput() {
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

enum ChatState { locked, active, expired }

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final Timestamp? timestamp;
  final String type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.timestamp,
    required this.type,
  });
}
