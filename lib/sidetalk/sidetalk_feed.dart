import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../widgets/filter_button.dart';
import '../models/post.dart';

class SidetalkFeed extends StatefulWidget {
  const SidetalkFeed({super.key});

  @override
  State<SidetalkFeed> createState() => _SidetalkFeedState();
}

class _SidetalkFeedState extends State<SidetalkFeed> {
  String selectedFilter = 'All';
  
  final List<Post> posts = [
    Post(
      id: '1',
      content: 'Sometimes I wonder if anyone really sees me\nfor who I am underneath all the masks\nI wear every single day',
      isAnonymous: true,
      username: null,
      timestamp: '2h',
      likes: 23,
      comments: 5,
      cardColor: const Color(0xFFF5F5DC), // Beige
    ),
    Post(
      id: '2',
      content: 'The weight of pretending everything is fine\nis heavier than the problems themselves\nWhy do we do this to ourselves?',
      isAnonymous: false,
      username: 'midnight_thoughts',
      timestamp: '4h',
      likes: 47,
      comments: 12,
      cardColor: const Color(0xFFFFFACD), // Light yellow
    ),
    Post(
      id: '3',
      content: 'I deleted all my social media today\nand for the first time in years\nI can hear my own thoughts clearly',
      isAnonymous: true,
      username: null,
      timestamp: '6h',
      likes: 89,
      comments: 23,
      cardColor: const Color(0xFFE6E6E6), // Muted gray
    ),
    Post(
      id: '4',
      content: 'Love feels like a foreign language\nthat everyone else learned in school\nwhile I was absent that day',
      isAnonymous: false,
      username: 'lost_in_translation',
      timestamp: '8h',
      likes: 156,
      comments: 34,
      cardColor: const Color(0xFFF5F5DC), // Beige
    ),
  ];

  List<Post> get filteredPosts {
    switch (selectedFilter) {
      case 'Anonymous':
        return posts.where((post) => post.isAnonymous).toList();
      case 'Public':
        return posts.where((post) => !post.isAnonymous).toList();
      default:
        return posts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24), // Spacer for centering
                  Text(
                    'SIDETALK',
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
            
            // Filter Button Row
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  FilterButton(
                    text: 'All',
                    isSelected: selectedFilter == 'All',
                    onTap: () => setState(() => selectedFilter = 'All'),
                  ),
                  const SizedBox(width: 12),
                  FilterButton(
                    text: 'Anonymous',
                    isSelected: selectedFilter == 'Anonymous',
                    onTap: () => setState(() => selectedFilter = 'Anonymous'),
                  ),
                  const SizedBox(width: 12),
                  FilterButton(
                    text: 'Public',
                    isSelected: selectedFilter == 'Public',
                    onTap: () => setState(() => selectedFilter = 'Public'),
                  ),
                ],
              ),
            ),
            
            // Posts Feed
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: PostCard(post: filteredPosts[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(35),
            onTap: () {
              // Navigate to compose screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Compose screen coming soon...'),
                  backgroundColor: Color(0xFFDC2626),
                ),
              );
            },
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}