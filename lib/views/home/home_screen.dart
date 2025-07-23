// This is your updated HomeScreen file: views/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../auth_service.dart';

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~ Main Host Screen with Navigation ~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // List of the pages that the navigation bar will switch between
  static const List<Widget> _pages = <Widget>[
    SideTablePage(), // Your main feature page
    VentCornerScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // The body will now display the selected page from the _pages list
      body: IndexedStack(index: _selectedIndex, children: _pages),
      // Attach the BottomNavigationBar to the Scaffold
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant_rounded),
            activeIcon: Icon(Icons.table_restaurant),
            label: 'Side Table',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Vent Corner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        // --- Professional Styling ---
        backgroundColor: const Color(0xFF121212), // Very dark grey
        type:
            BottomNavigationBarType.fixed, // Ensures labels are always visible
        selectedItemColor: const Color(0xFFDC2626), // Your app's theme color
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12.0,
        unselectedFontSize: 12.0,
        elevation: 20,
        iconSize: 26,
      ),
    );
  }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~ Feature & Placeholder Pages ~~~~~~~~~~~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

/// The main "Side Table" feature page (Home Tab)
class SideTablePage extends StatelessWidget {
  const SideTablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Side Table'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.coffee_rounded,
                size: 80,
                color: const Color(0xFFDC2626).withOpacity(0.8),
              ),
              const SizedBox(height: 32),
              const Text(
                'Ready for a Mystery Meetup?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No names, no profiles. Just a conversation. Tap below to find a random person to meet in the canteen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement matching logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Find a Match',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Vent Corner" feature page
class VentCornerScreen extends StatelessWidget {
  const VentCornerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Vent Corner'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 60,
              color: Colors.white70,
            ),
            SizedBox(height: 16),
            Text(
              'Vent Corner Coming Soon',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}

/// The User Profile Page
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              // Show confirmation dialog before logging out
              final bool? shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1C1E),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Are you sure you want to sign out?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(color: Color(0xFFDC2626)),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                try {
                  // Use the AuthService for a clean sign out
                  await context.read<AuthService>().signOut();
                  // Clear user data in the provider
                  if (context.mounted) {
                    context.read<UserProvider>().clearUser();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final UserModel? user = userProvider.user;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Could not load user data.',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      final firebaseUser = FirebaseAuth.instance.currentUser;
                      if (firebaseUser != null) {
                        userProvider.fetchUserData(firebaseUser.uid);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  backgroundColor: Colors.grey[800],
                  child: user.photoURL == null
                      ? Text(
                          user.initials,
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.displayName ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '@${user.username ?? 'no_username'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(
                  Icons.email_outlined,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Email',
                  style: TextStyle(color: Colors.white70),
                ),
                subtitle: Text(
                  user.email,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.school_outlined,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Department',
                  style: TextStyle(color: Colors.white70),
                ),
                subtitle: Text(
                  user.department ?? 'Not set',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Year',
                  style: TextStyle(color: Colors.white70),
                ),
                subtitle: Text(
                  user.year ?? 'Not set',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
