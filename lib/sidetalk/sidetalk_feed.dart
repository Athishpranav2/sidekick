import 'package:flutter/material.dart';
import 'post_card.dart';
import 'filter_button.dart';
import 'filter_modal.dart';
import '../models/post.dart';
import '../models/filter_options.dart';
import '../views/compose/compose_screen.dart';

class SidetalkFeed extends StatefulWidget {
  const SidetalkFeed({super.key});

  @override
  State<SidetalkFeed> createState() => _SidetalkFeedState();
}

class _SidetalkFeedState extends State<SidetalkFeed> {
  String selectedFilter = 'All'; // Keep for backward compatibility
  FilterState currentFilter = const FilterState();
  
  // Simple tracking of liked posts
  Set<String> likedPosts = <String>{};
  
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
    List<Post> filtered = List.from(posts);
    
    // Filter by post type
    switch (currentFilter.postType) {
      case PostType.anonymous:
        filtered = filtered.where((post) => post.isAnonymous).toList();
        break;
      case PostType.public:
        filtered = filtered.where((post) => !post.isAnonymous).toList();
        break;
      case PostType.all:
        // Keep all posts
        break;
    }
    
    // Filter by category (placeholder logic - you can expand this based on post content analysis)
    switch (currentFilter.category) {
      case CategoryFilter.positive:
        // Example: filter posts with positive sentiment (implement sentiment analysis)
        break;
      case CategoryFilter.negative:
        // Example: filter posts with negative sentiment
        break;
      case CategoryFilter.sensitive:
        // Example: filter posts marked as sensitive
        break;
      case CategoryFilter.others:
        // Example: filter other category posts
        break;
      case CategoryFilter.all:
        // Keep all posts
        break;
    }
    
    // Filter by user's own posts (placeholder - requires user identification)
    if (currentFilter.showMyPostsOnly) {
      // filtered = filtered.where((post) => post.userId == currentUserId).toList();
      // For now, we'll just show posts with username (as example)
      filtered = filtered.where((post) => !post.isAnonymous).toList();
    }
    
    // Sort posts
    switch (currentFilter.sortBy) {
      case SortOption.recent:
        // Keep default order (most recent first)
        break;
      case SortOption.mostLiked:
        filtered.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case SortOption.mostCommented:
        filtered.sort((a, b) => b.comments.compareTo(a.comments));
        break;
    }
    
    return filtered;
  }

  // Handle filter changes
  void _onFilterChanged(FilterState newFilter) {
    setState(() {
      currentFilter = newFilter;
      // Update legacy selectedFilter for backward compatibility
      switch (newFilter.postType) {
        case PostType.all:
          selectedFilter = 'All';
          break;
        case PostType.anonymous:
          selectedFilter = 'Anonymous';
          break;
        case PostType.public:
          selectedFilter = 'Public';
          break;
      }
    });
  }

  // Show filter modal
  void _showFilterModal() {
    print('Filter modal button tapped!'); // Debug print
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FilterModal(
        currentFilter: currentFilter,
        onFilterChanged: _onFilterChanged,
      ),
    );
  }

  // Check if any filters are active
  bool _hasActiveFilters() {
    return currentFilter.postType != PostType.all ||
           currentFilter.category != CategoryFilter.all ||
           currentFilter.sortBy != SortOption.recent ||
           currentFilter.showMyPostsOnly;
  }

  // Check if advanced filters (beyond post type) are active
  bool _hasActiveAdvancedFilters() {
    return currentFilter.category != CategoryFilter.all ||
           currentFilter.sortBy != SortOption.recent ||
           currentFilter.showMyPostsOnly;
  }

  // Simple like toggle functionality
  void _toggleLike(String postId) {
    setState(() {
      final postIndex = posts.indexWhere((post) => post.id == postId);
      if (postIndex == -1) return;
      
      if (likedPosts.contains(postId)) {
        // Unlike: remove from set and decrease count
        likedPosts.remove(postId);
        posts[postIndex].likes--;
      } else {
        // Like: add to set and increase count
        likedPosts.add(postId);
        posts[postIndex].likes++;
      }
    });
  }

  // Build empty state widget with dynamic message
  Widget _buildEmptyState() {
    String message;
    String emoji = '📭';
    
    if (!_hasActiveFilters()) {
      message = 'No posts yet. Be the first to share something!';
      emoji = '✨';
    } else {
      // Generate message based on active filters
      List<String> filterDescriptions = [];
      
      if (currentFilter.postType != PostType.all) {
        filterDescriptions.add(currentFilter.postType.displayName.toLowerCase());
      }
      if (currentFilter.showMyPostsOnly) {
        filterDescriptions.add('your own');
      }
      if (currentFilter.category != CategoryFilter.all) {
        filterDescriptions.add(currentFilter.category.displayName.toLowerCase());
      }
      
      if (filterDescriptions.isNotEmpty) {
        message = 'No ${filterDescriptions.join(' ')} posts found.\nTry adjusting your filters.';
      } else {
        message = 'No posts match your current filters.\nTry adjusting your search criteria.';
      }
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 16), // Consistent padding
              child: Center(
                child: Text(
                  'SIDETALK',
                  style: TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            
            // Enhanced Filter Row with quick filters and comprehensive filter access
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Quick filter chips
                  Container(
                    height: 50,
                    child: Row(
                      children: [
                        // Post Type filters: All, Anonymous, Public
                        FilterButton(
                          text: 'ALL',
                          isSelected: currentFilter.postType == PostType.all,
                          onTap: () => _onFilterChanged(currentFilter.copyWith(postType: PostType.all)),
                        ),
                        const SizedBox(width: 8),
                        FilterButton(
                          text: 'ANONYMOUS',
                          isSelected: currentFilter.postType == PostType.anonymous,
                          onTap: () => _onFilterChanged(currentFilter.copyWith(postType: PostType.anonymous)),
                        ),
                        const SizedBox(width: 8),
                        FilterButton(
                          text: 'PUBLIC',
                          isSelected: currentFilter.postType == PostType.public,
                          onTap: () => _onFilterChanged(currentFilter.copyWith(postType: PostType.public)),
                        ),
                        const Spacer(),
                        // All Filters button
                        InkWell(
                          onTap: _showFilterModal,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _hasActiveAdvancedFilters() ? const Color(0xFFDC2626) : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _hasActiveAdvancedFilters() ? const Color(0xFFDC2626) : const Color(0xFF444444),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.tune,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Filters',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Posts Feed with Empty State
            Expanded(
              child: filteredPosts.isEmpty 
                ? _buildEmptyState() 
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Consistent 16px padding
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final currentPost = filteredPosts[index];
                      
                      return PostCard(
                        post: currentPost,
                        likedByMe: likedPosts.contains(currentPost.id),
                        onLike: () {
                          _toggleLike(currentPost.id);
                        },
                        onReport: () {
                          // Handle report functionality
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      
      // Improved Floating Action Button (Red + in bottom right)
      floatingActionButton: Semantics(
        label: 'New Post',
        child: Container(
          margin: const EdgeInsets.all(16), // 16px margin from edges as specified
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626), // Keep the red color
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                // Navigate to compose screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComposeScreen(),
                    settings: const RouteSettings(name: '/sidetalk/compose'),
                  ),
                );
              },
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}