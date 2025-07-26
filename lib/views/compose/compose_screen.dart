import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Using the same color constants
const Color kPrimaryRed = Color(0xFFDC2626);
const Color kBackgroundBlack = Color(0xFF000000);
const Color kCardBackground = Color(0xFF1E1E1E);
const Color kDividerColor = Color(0xFF2A2A2A);
const Color kTextPrimary = Colors.white;
const Color kTextSecondary = Color(0xFF8E8E93);

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _textController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;
  final int _characterLimit = 280;

  Future<void> _submitPost() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot post an empty confession.')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      String? username;
      if (!_isAnonymous) {
        // In a real app, you'd get the username from your user profile data
        // For now, we'll use a placeholder or leave it null if anonymous
        username = user.displayName ?? 'PublicUser';
      }

      await FirebaseFirestore.instance.collection('confessions').add({
        'text': _textController.text.trim(),
        'isAnonymous': _isAnonymous,
        'userId': user.uid,
        'username': username,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'comments': [],
        'status': 'approved', // Or 'pending' for moderation
      });

      // Pop until Sidetalk/VentCornerScreen is visible
      bool popped = false;
      Navigator.of(context).popUntil((route) {
        if (!popped && route.settings.name != null && route.settings.name!.contains('vent_corner')) {
          popped = true;
          return true;
        }
        return false;
      });
      if (!popped) {
        Navigator.of(context).maybePop(); // fallback if no named route
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your confession has been posted!'),
          backgroundColor: kPrimaryRed,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post confession: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: const Text(
          'NEW CONFESSION',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: kBackgroundBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                maxLength: _characterLimit,
                autofocus: true,
                style: const TextStyle(color: kTextPrimary, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind?',
                  hintStyle: const TextStyle(color: kTextSecondary),
                  border: InputBorder.none,
                  counterStyle: const TextStyle(color: kTextSecondary),
                ),
                onChanged: (text) {
                  setState(() {}); // To update UI based on text changes if needed
                },
              ),
            ),
            const Divider(color: kDividerColor),
            SwitchListTile(
              title: const Text(
                'Post Anonymously',
                style: TextStyle(color: kTextPrimary),
              ),
              subtitle: const Text(
                'Your identity will be hidden.',
                style: TextStyle(color: kTextSecondary),
              ),
              value: _isAnonymous,
              onChanged: (value) {
                setState(() {
                  _isAnonymous = value;
                });
              },
              activeColor: kPrimaryRed,
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryRed,
                    disabledBackgroundColor: kDividerColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'POST',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.1,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
