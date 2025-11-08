# Migration Script: Update Old "sales" Role to "sales executive"

## Issue
After renaming "sales" to "sales executive", users with the old "sales" role in Firestore may cause dropdown errors.

## Solution
Run this script in Firebase Console or using a Cloud Function to update all existing users.

## Option 1: Firebase Console (Firestore)

1. Go to Firebase Console → Firestore Database
2. Navigate to the `users` collection
3. For each document with `role: "sales"`:
   - Edit the document
   - Change `role` field from `"sales"` to `"sales executive"`
   - Save

## Option 2: Cloud Function (Automated)

Create a one-time Cloud Function to migrate all users:

```javascript
const admin = require('firebase-admin');
admin.initializeApp();

exports.migrateOldSalesRole = functions.https.onRequest(async (req, res) => {
  const db = admin.firestore();

  try {
    // Find all users with old "sales" role
    const usersSnapshot = await db.collection('users')
      .where('role', '==', 'sales')
      .get();

    if (usersSnapshot.empty) {
      return res.send('No users found with old "sales" role.');
    }

    // Update each user
    const batch = db.batch();
    usersSnapshot.forEach((doc) => {
      batch.update(doc.ref, {
        role: 'sales executive',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await batch.commit();

    return res.send(`Successfully migrated ${usersSnapshot.size} users from "sales" to "sales executive"`);
  } catch (error) {
    console.error('Migration error:', error);
    return res.status(500).send('Migration failed: ' + error.message);
  }
});
```

## Option 3: Manual Query (if you have few users)

If you have only a few users, you can manually update them through the app:
1. Login as admin
2. Go to User Management
3. For each user with "sales" role:
   - Click the user
   - Click "Change role"
   - Select "sales executive"
   - Save

## Verification

After migration, verify:
- No users have `role: "sales"` in Firestore
- All dropdowns work without assertion errors
- Users can login and see their assigned items

---

**Note:** The app already has backward compatibility code that automatically maps "sales" → "sales executive" when loading users, but it's better to clean up the database for consistency.
