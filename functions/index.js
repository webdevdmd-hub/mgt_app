const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Ensure you initialize the Admin SDK if it hasn't been done automatically
// in your main index file (e.g., if you are exporting multiple functions).
// In many new projects, this line is not needed if the SDK auto-initializes.
admin.initializeApp(); 

exports.adminCreateUser = functions.https.onCall(async (data, context) => {
    // 1. 🔒 Authentication & Authorization Check
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'The user must be logged in.');
    }
    
    // 💡 Security Check: Only allow 'admin' role to call this function
    const callerRole = context.auth.token.role; 
    if (callerRole !== 'admin') { 
        throw new functions.https.HttpsError('permission-denied', 'Only authorized users can create new accounts.');
    }

    const { email, name, role, isActive, password, sendInvite } = data;

    try {
        // --- STEP 1: Create User in Firebase Authentication ---
        const authArgs = {
            email: email,
            emailVerified: false,
            displayName: name,
            disabled: !isActive,
        };
        
        if (password && !sendInvite) {
            authArgs.password = password;
        }

        const userRecord = await admin.auth().createUser(authArgs);
        const uid = userRecord.uid;

        // --- STEP 2: Set Custom Claims (Role) in Authentication ---
        await admin.auth().setCustomUserClaims(uid, { role: role });

        // --- STEP 3: Save Profile in Firestore ---
        await admin.firestore().collection('users').doc(uid).set({
            email: email,
            name: name,
            role: role,
            isActive: isActive,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // --- STEP 4: Send Invite/Reset Email if required ---
        if (sendInvite) {
             const link = await admin.auth().generatePasswordResetLink(email);
             console.log(`Password reset link for ${email}: ${link}`);
        }
        
        // --- STEP 5: Return Success ---
        return { success: true, uid: uid };

    } catch (error) {
        console.error('Error creating new user:', error);
        throw new functions.https.HttpsError('internal', error.message || 'Failed to create user.');
    }
});