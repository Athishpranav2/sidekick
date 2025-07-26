// Firestore structure and notes for Vent Corner (Confessions)
// Place this file in your docs/ or lib/core/ directory for reference.

/*
Firestore Collections:

1. confessions/
   - Stores all confessions (approved and visible to users)
   - Document fields:
     - text: String
     - isAnonymous: bool
     - userId: String (nullable if anonymous)
     - username: String (nullable if anonymous)
     - userProfilePic: String (nullable if anonymous)
     - timestamp: Timestamp
     - status: String ('approved', 'rejected', 'pending')
     - hearts: int
     - comments: int
     - category: String? ('positive', 'negative', 'sensitive')
     - reported: bool (optional)

2. pending_confessions/
   - Stores confessions waiting for moderation
   - Same fields as above, but status is always 'pending'
   - On approval, move to confessions/ and set status to 'approved'
   - On rejection, set status to 'rejected' or delete

3. comments/
   - Subcollection under each confession document
   - confessions/{confessionId}/comments/{commentId}
   - Fields: text, userId, username, timestamp

4. users/
   - User profiles, onboarding status, etc.

5. reports/
   - Optionally, store reported posts for admin review

*/

// Next step: implement the Confession model in Dart.
