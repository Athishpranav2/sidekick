import * as admin from 'firebase-admin';
import { onCall, CallableRequest } from 'firebase-functions/v2/https';

// Initialize Firebase Admin if not already done
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

interface Post {
  id: string;
  content: string;
  isAnonymous: boolean;
  username?: string;
  gender?: string;
  timestamp: FirebaseFirestore.Timestamp;
  likes: number;
  comments: number;
  views: number;
  tags: string[];
  isPinned: boolean;
  isHidden: boolean;
  status: string;
  reportCount: number;
  isPromoted: boolean;
  engagementScore: number;
  authorId?: string;
}

enum FeedMode {
  ALGORITHMIC = 'algorithmic',
  CHRONOLOGICAL = 'chronological', 
  TRENDING = 'trending'
}

interface FeedRequest {
  userId: string;
  mode: FeedMode;
  pageSize?: number;
  lastPostId?: string;
  forceRefresh?: boolean;
}

// Main cloud function for feed algorithm (Firebase Functions v2)
export const getFeed = onCall(async (request: CallableRequest) => {
  try {
    // In Firebase Functions v2, auth is available on request.auth
    console.log('Firebase v2 auth debug:', {
      hasAuth: !!request.auth,
      authUid: request.auth?.uid,
      authToken: !!request.auth?.token
    });

    if (!request.auth || !request.auth.uid) {
      console.error('Authentication failed in v2 function');
      throw new Error('User must be authenticated');
    }

    const authUid = request.auth.uid;

    const { userId, mode, pageSize = 20, lastPostId, forceRefresh } = request.data;
    
    // Use the authenticated user's ID from request if userId not provided
    const actualUserId = userId || authUid;
    
    // Check cache first (Redis in production)
    const cacheKey = `feed:${actualUserId}:${mode}`;
    // Implement caching logic here
    
    let posts: Post[] = [];
    
    switch (mode) {
      case FeedMode.ALGORITHMIC:
        console.log('🧠 Using AI Algorithmic Feed');
        posts = await getAlgorithmicFeed(actualUserId, pageSize, lastPostId);
        break;
      case FeedMode.CHRONOLOGICAL:
        console.log('📅 Using Chronological Feed');
        posts = await getChronologicalFeed(pageSize, lastPostId);
        break;
      case FeedMode.TRENDING:
        console.log('🔥 Using Trending Feed');
        posts = await getTrendingFeed(pageSize);
        break;
      default:
        throw new Error('Invalid feed mode');
    }

    // Skip personalization to avoid additional complex queries
    const personalizedPosts = posts;
    
    // Apply spam filtering
    const filteredPosts = applySpamFiltering(personalizedPosts);
    
    // Cache results
    // await cacheResults(cacheKey, filteredPosts);
    
    // Convert posts to Flutter-compatible format with proper timestamp serialization
    const flutterPosts = filteredPosts.map(post => {
      // FIXED: Proper timestamp handling for Flutter compatibility
      let timestampMillis: number;
      if (post.timestamp && typeof post.timestamp === 'object') {
        // If it's a Firestore Timestamp object
        if (post.timestamp.toMillis) {
          timestampMillis = post.timestamp.toMillis();
        } else {
          // If it's a plain object with seconds/nanoseconds, convert
          const tsData = post.timestamp as any;
          timestampMillis = (tsData.seconds || 0) * 1000 + (tsData.nanoseconds || 0) / 1000000;
        }
      } else {
        // Default to current time
        timestampMillis = Date.now();
      }
      
      // Handle likes and comments as arrays (Flutter expects this format)
      const likesArray = Array.isArray(post.likes) ? post.likes : [];
      const commentsArray = Array.isArray(post.comments) ? post.comments : [];
      
      return {
        id: post.id,
        // Keep original data structure but ensure required fields
        text: (post as any).content || (post as any).text || '',
        // FIXED: Send timestamp as milliseconds (number) instead of Firestore Timestamp object
        timestamp: timestampMillis,
        likes: likesArray,
        comments: commentsArray,
        isAnonymous: post.isAnonymous ?? true,
        username: post.username || null,
        gender: post.gender || null,
        // Include other fields that Flutter expects
        views: post.views || 0,
        tags: post.tags || [],
        isPinned: post.isPinned ?? false,
        isHidden: post.isHidden ?? false,
        status: post.status || 'approved',
        reportCount: post.reportCount || 0,
        isPromoted: post.isPromoted ?? false,
        engagementScore: post.engagementScore || 0.0,
        authorId: post.authorId || null,
      };
    });

    console.log(`Returning ${flutterPosts.length} posts to Flutter app`);

    return {
      posts: flutterPosts,
      hasMore: filteredPosts.length >= pageSize,
      lastPostId: filteredPosts[filteredPosts.length - 1]?.id,
      algorithm: 'cloud-v2.0', // Version tracking
    };

  } catch (error) {
    console.error('Feed algorithm error:', error);
    throw new Error('Feed generation failed');
  }
});

// Algorithmic feed with engagement-based ranking
async function getAlgorithmicFeed(userId: string, pageSize: number, lastPostId?: string): Promise<Post[]> {
  try {
    console.log('🧠 AI Feed: Starting algorithmic ranking...');
    
    // Get all posts (we'll filter and rank client-side to avoid complex indexes)
    const snapshot = await db.collection('confessions')
      .orderBy('timestamp', 'desc')
      .limit(pageSize * 5) // Get more posts for better ranking
      .get();
    
    console.log(`AI Feed: Retrieved ${snapshot.docs.length} posts for ranking`);
    
    // Convert to Post objects and filter
    const allPosts = snapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() } as Post))
      .filter(post => {
        const data = post as any;
        return data.status === 'approved' && data.isHidden !== true;
      });
    
    console.log(`AI Feed: After filtering, ${allPosts.length} posts available for ranking`);
    
    // Calculate engagement scores for each post
    const postsWithScores = allPosts.map(post => ({
      ...post,
      calculatedScore: calculateEngagementScore(post)
    }));
    
    // Sort by engagement score (pinned posts first, then by score)
    postsWithScores.sort((a, b) => {
      // Pinned posts always come first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // Then sort by calculated engagement score
      return b.calculatedScore - a.calculatedScore;
    });
    
    const topPosts = postsWithScores.slice(0, pageSize);
    console.log(`AI Feed: Returning top ${topPosts.length} posts with scores:`, 
      topPosts.map(p => ({ id: p.id, score: p.calculatedScore, likes: p.likes, comments: p.comments })));
    
    return topPosts;
  } catch (error) {
    console.error('Algorithmic feed error:', error);
    throw error;
  }
}

// Calculate engagement score using advanced algorithm
function calculateEngagementScore(post: Post): number {
  const now = Date.now();
  const postTime = post.timestamp.toMillis();
  const ageInHours = (now - postTime) / (1000 * 60 * 60);
  
  // Handle likes and comments as either arrays or numbers
  const likesCount = Array.isArray(post.likes) ? post.likes.length : (post.likes || 0);
  const commentsCount = Array.isArray(post.comments) ? post.comments.length : (post.comments || 0);
  const viewsCount = post.views || 0;
  
  // Base engagement from interactions (weighted) - only likes and comments
  const interactionScore = (likesCount * 3.0) + 
                          (commentsCount * 5.0) + 
                          (viewsCount * 0.1);
  
  // Time decay factor (newer posts get boost)
  const timeFactor = ageInHours < 1 ? 2.0 : 
                    ageInHours < 24 ? 1.5 : 
                    ageInHours < 168 ? 1.0 : 0.5;
  
  // Quality factors - handle both 'content' and 'text' fields
  const content = (post as any).content || (post as any).text || '';
  const qualityFactor = content.length > 50 ? 1.2 : 
                       content.length < 20 ? 0.8 : 1.0;
  
  // Administrative boosts
  const adminFactor = post.isPinned ? 10.0 : 
                     post.isPromoted ? 3.0 : 1.0;
  
  // Report penalty
  const reportPenalty = post.reportCount > 0 ? 
    Math.max(0.1, 1.0 - (post.reportCount * 0.1)) : 1.0;
  
  return interactionScore * timeFactor * qualityFactor * adminFactor * reportPenalty;
}

// Get posts from specific time window
async function getPostsFromTimeWindow(hours: number, limit: number): Promise<Post[]> {
  const timeLimit = admin.firestore.Timestamp.fromMillis(
    Date.now() - (hours * 60 * 60 * 1000)
  );
  
  const snapshot = await db.collection('confessions')
    .where('status', '==', 'approved')
    .where('isHidden', '==', false)
    .where('timestamp', '>', timeLimit)
    .orderBy('timestamp', 'desc')
    .limit(limit)
    .get();
    
  return snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  } as Post));
}

// Get chronological feed (super simplified - no composite index needed)
async function getChronologicalFeed(pageSize: number, lastPostId?: string): Promise<Post[]> {
  console.log('Using super simplified query (no composite index needed)');
  
  try {
    // Use ONLY timestamp orderBy - this should work with single field index
    let query = db.collection('confessions')
      .orderBy('timestamp', 'desc')
      .limit(pageSize * 3); // Get extra to filter client-side
      
    const snapshot = await query.get();
    console.log(`Raw query returned ${snapshot.docs.length} documents`);
    
    // Filter client-side to avoid composite index requirement
    const posts = snapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() } as Post))
      .filter(post => {
        // Client-side filtering
        const data = post as any;
        const isApproved = data.status === 'approved';
        const isVisible = data.isHidden !== true;
        return isApproved && isVisible;
      })
      .slice(0, pageSize); // Take only what we need
    
    console.log(`After filtering: ${posts.length} posts for feed`);
    return posts;
    
  } catch (error) {
    console.error('Simple query failed:', error);
    
    // Ultimate fallback - get all documents and filter
    const snapshot = await db.collection('confessions').limit(pageSize * 5).get();
    const posts = snapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() } as Post))
      .filter(post => {
        const data = post as any;
        return data.status === 'approved' && data.isHidden !== true;
      })
      .sort((a: any, b: any) => {
        const aTime = a.timestamp?.toDate?.() || new Date(a.timestamp);
        const bTime = b.timestamp?.toDate?.() || new Date(b.timestamp);
        return bTime.getTime() - aTime.getTime();
      })
      .slice(0, pageSize);
      
    console.log(`Fallback query returned ${posts.length} posts`);
    return posts;
  }
}

// Get trending feed
async function getTrendingFeed(pageSize: number): Promise<Post[]> {
  try {
    console.log('🔥 Trending Feed: Finding most engaging posts...');
    
    // Get recent posts (last 7 days worth)
    const timeLimit = admin.firestore.Timestamp.fromMillis(
      Date.now() - (7 * 24 * 60 * 60 * 1000)
    );
    
    const snapshot = await db.collection('confessions')
      .orderBy('timestamp', 'desc')
      .limit(pageSize * 10) // Get more posts to find trending ones
      .get();
    
    console.log(`Trending Feed: Retrieved ${snapshot.docs.length} posts for trending analysis`);
    
    // Convert and filter posts
    const allPosts = snapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() } as Post))
      .filter(post => {
        const data = post as any;
        const isRecent = data.timestamp && data.timestamp.toMillis() > timeLimit.toMillis();
        const isApproved = data.status === 'approved';
        const isVisible = data.isHidden !== true;
        return isRecent && isApproved && isVisible;
      });
    
    console.log(`Trending Feed: After filtering, ${allPosts.length} recent posts available`);
    
    // Calculate trending scores (engagement + velocity)
    const postsWithTrendingScores = allPosts.map(post => {
      // Handle likes and comments as either arrays or numbers
      const likesCount = Array.isArray(post.likes) ? post.likes.length : (post.likes || 0);
      const commentsCount = Array.isArray(post.comments) ? post.comments.length : (post.comments || 0);
      
      const engagement = likesCount + (commentsCount * 2); // Comments worth more
      const ageInHours = (Date.now() - post.timestamp.toMillis()) / (1000 * 60 * 60);
      const velocity = engagement / Math.max(1, ageInHours); // Engagement per hour
      
      return {
        ...post,
        trendingScore: engagement + (velocity * 10) // Weight velocity heavily
      };
    });
    
    // Sort by trending score
    postsWithTrendingScores.sort((a, b) => b.trendingScore - a.trendingScore);
    
    const trendingPosts = postsWithTrendingScores.slice(0, pageSize);
    console.log(`Trending Feed: Returning top ${trendingPosts.length} trending posts:`, 
      trendingPosts.map(p => ({ 
        id: p.id, 
        trendingScore: p.trendingScore, 
        likes: p.likes, 
        comments: p.comments 
      })));
    
    return trendingPosts;
  } catch (error) {
    console.error('Trending feed error:', error);
    throw error;
  }
}

// Apply personalization based on user behavior
async function applyPersonalization(posts: Post[], userId: string): Promise<Post[]> {
  try {
    // Get user interaction history from their likes
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data() || {};
    
    // Get posts the user has liked to understand preferences
    const likedPostsQuery = await db.collection('confessions')
      .where('likes', 'array-contains', userId)
      .limit(50)
      .get();
      
    const likedCategories = new Set<string>();
    const likedAuthors = new Set<string>();
    
    likedPostsQuery.docs.forEach(doc => {
      const data = doc.data();
      if (data.authorId) likedAuthors.add(data.authorId);
      if (data.tags) data.tags.forEach((tag: string) => likedCategories.add(tag));
    });
    
    // Boost posts from similar categories or authors
    const personalizedPosts = posts.map(post => ({
      ...post,
      personalityBoost: (likedAuthors.has(post.authorId || '') ? 1.2 : 1.0) *
                       (post.tags.some(tag => likedCategories.has(tag)) ? 1.3 : 1.0)
    }));
    
    return personalizedPosts;
  } catch (error) {
    console.error('Personalization error:', error);
    return posts;
  }
}

// Apply anti-spam filtering (with safety checks)
function applySpamFiltering(posts: Post[]): Post[] {
  console.log(`Spam filtering: Input ${posts.length} posts`);
  
  const filtered = posts.filter(post => {
    // Safety checks
    if (!post || typeof post !== 'object') {
      console.log('Filtered out: Invalid post object');
      return false;
    }
    
    // Filter out posts with high report count
    if (post.reportCount && post.reportCount > 5) {
      console.log('Filtered out: High report count');
      return false;
    }
    
    // Get content from either 'content' or 'text' field (Firestore compatibility)
    const content = (post as any).content || (post as any).text || '';
    console.log(`Post content length: ${content.length}, content: "${content.substring(0, 50)}..."`);
    
    // Filter very short posts (likely spam) - with safety check (reduced threshold)
    if (content.length < 5) {  // Reduced from 10 to 5
      console.log('Filtered out: Content too short');
      return false;
    }
    
    // Filter posts with excessive caps - with safety check
    if (content.length > 20) {
      const capsCount = content.replace(/[^A-Z]/g, '').length;
      const capsRatio = capsCount / content.length;
      if (capsRatio > 0.7) {
        console.log('Filtered out: Too many caps');
        return false;
      }
    }
    
    console.log('Post passed spam filtering');
    return true;
  });
  
  console.log(`Spam filtering: Output ${filtered.length} posts`);
  return filtered;
}