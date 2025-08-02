import * as admin from 'firebase-admin';
import { onCall, CallableRequest } from 'firebase-functions/v2/https';

const db = admin.firestore();

// Track post view
export const trackPostView = onCall(async (request: CallableRequest) => {
  try {
    if (!request.auth || !request.auth.uid) {
      throw new Error('User must be authenticated');
    }

    const { postId } = request.data;
    
    if (!postId) {
      throw new Error('Post ID is required');
    }

    // Increment view count
    await db.collection('confessions').doc(postId).update({
      views: admin.firestore.FieldValue.increment(1)
    });

    // Log analytics event
    await db.collection('analytics').add({
      event: 'post_view',
      postId,
      userId: request.auth.uid,
      timestamp: admin.firestore.Timestamp.now(),
      userAgent: 'mobile-app',
    });

    return { success: true };
  } catch (error) {
    console.error('Track view error:', error);
    throw new Error('Failed to track view');
  }
});

// Share tracking removed - not needed for this app

// Get feed analytics (admin only)
export const getFeedAnalytics = onCall(async (request: CallableRequest) => {
  try {
    if (!request.auth || !request.auth.uid) {
      throw new Error('User must be authenticated');
    }

    // Check if user is admin
    const userEmail = request.auth.token?.email;
    const adminEmails = ['admin@sidekick.com', 'moderator@sidekick.com']; // Same as client
    
    if (!adminEmails.includes(userEmail || '')) {
      throw new Error('Admin access required');
    }

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const yesterday = new Date(today.getTime() - 24 * 60 * 60 * 1000);
    const weekAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);

    // Get various analytics
    const [
      totalPosts,
      postsToday,
      postsThisWeek,
      totalViews,
      totalComments,
      totalLikes,
      activeUsers,
    ] = await Promise.all([
      // Total posts
      db.collection('confessions').count().get(),
      
      // Posts today
      db.collection('confessions')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(today))
        .count().get(),
        
      // Posts this week
      db.collection('confessions')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(weekAgo))
        .count().get(),
        
      // Total views (sum of all post views)
      db.collection('confessions').get().then(snapshot => {
        return snapshot.docs.reduce((sum, doc) => sum + (doc.data().views || 0), 0);
      }),
      
      // Total comments count
      db.collection('confessions').get().then(snapshot => {
        return snapshot.docs.reduce((sum, doc) => {
          const comments = doc.data().comments;
          return sum + (Array.isArray(comments) ? comments.length : (comments || 0));
        }, 0);
      }),
      
      // Total likes
      db.collection('confessions').get().then(snapshot => {
        return snapshot.docs.reduce((sum, doc) => sum + (doc.data().likes || 0), 0);
      }),
      
      // Active users today
      db.collection('analytics')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(today))
        .get().then(snapshot => {
          const uniqueUsers = new Set(snapshot.docs.map(doc => doc.data().userId));
          return uniqueUsers.size;
        }),
    ]);

    // Get top posts by engagement
    const topPostsSnapshot = await db.collection('confessions')
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(weekAgo))
      .orderBy('engagementScore', 'desc')
      .limit(10)
      .get();

    const topPosts = topPostsSnapshot.docs.map(doc => ({
      id: doc.id,
      content: doc.data().content?.substring(0, 100) + '...',
      engagementScore: doc.data().engagementScore || 0,
      likes: doc.data().likes || 0,
      comments: Array.isArray(doc.data().comments) ? doc.data().comments.length : (doc.data().comments || 0),
      views: doc.data().views || 0,
    }));

    return {
      summary: {
        totalPosts: totalPosts.data().count,
        postsToday: postsToday.data().count,
        postsThisWeek: postsThisWeek.data().count,
        totalViews,
        totalComments,
        totalLikes,
        activeUsers,
        engagementRate: totalLikes > 0 ? (totalViews / totalLikes).toFixed(2) : '0',
      },
      topPosts,
      generatedAt: admin.firestore.Timestamp.now(),
    };

  } catch (error) {
    console.error('Analytics error:', error);
    throw new Error('Failed to get analytics');
  }
});

// Get trending hashtags/topics
export const getTrendingTopics = onCall(async (request: CallableRequest) => {
  try {
    if (!request.auth || !request.auth.uid) {
      throw new Error('User must be authenticated');
    }

    const { timeframe = 24 } = request.data; // hours
    const timeLimit = admin.firestore.Timestamp.fromMillis(
      Date.now() - (timeframe * 60 * 60 * 1000)
    );

    // Get recent posts
    const snapshot = await db.collection('confessions')
      .where('timestamp', '>', timeLimit)
      .where('status', '==', 'approved')
      .get();

    // Extract and count hashtags
    const hashtagCounts: { [key: string]: number } = {};
    
    snapshot.docs.forEach(doc => {
      const content = doc.data().content || '';
      const hashtags = content.match(/#\w+/g) || [];
      
      hashtags.forEach(tag => {
        const normalizedTag = tag.toLowerCase();
        hashtagCounts[normalizedTag] = (hashtagCounts[normalizedTag] || 0) + 1;
      });
    });

    // Sort by count and return top 10
    const trendingTopics = Object.entries(hashtagCounts)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 10)
      .map(([hashtag, count]) => ({ hashtag, count }));

    return {
      topics: trendingTopics,
      timeframe: `${timeframe} hours`,
      generatedAt: admin.firestore.Timestamp.now(),
    };

  } catch (error) {
    console.error('Trending topics error:', error);
    throw new Error('Failed to get trending topics');
  }
});