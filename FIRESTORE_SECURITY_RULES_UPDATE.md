# Firestore Security Rules Update - Super-Admin Support

## Issue
The Firestore security rules only checked for `role == 'admin'` but didn't include `'superadmin'`, causing permission denied errors when super-admin users tried to:
- View all users (Manage Users screen)
- View all orders (Manage Orders screen)
- Manage products

## Solution
Updated security rules to include both `'admin'` and `'superadmin'` roles using a helper function.

## Updated Security Rules

Go to Firebase Console → Firestore Database → Rules tab and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is admin or superadmin
    function isAdminOrSuperAdmin() {
      return request.auth != null && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'superadmin'];
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && (request.auth.uid == userId || isAdminOrSuperAdmin());
      allow write: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
      allow update: if request.auth != null && (request.auth.uid == userId || isAdminOrSuperAdmin());
    }
    
    // Products collection
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && isAdminOrSuperAdmin();
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if request.auth != null && (resource.data.userId == request.auth.uid || isAdminOrSuperAdmin());
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update: if request.auth != null && (resource.data.userId == request.auth.uid || isAdminOrSuperAdmin());
    }
  }
}
```

## Changes Made
1. Added `isAdminOrSuperAdmin()` helper function that checks for both 'admin' and 'superadmin' roles
2. Updated all admin checks to use this helper function
3. Added `allow update` rule for users collection to allow admins/superadmins to update user roles

## After Updating Rules
1. Click **"Publish"** button in Firebase Console
2. Wait a few seconds for rules to propagate
3. Refresh the app and try accessing:
   - Manage Users screen
   - Manage Orders screen
   - Product management features

## Verification
After updating the rules, you should be able to:
- ✅ View all users as super-admin
- ✅ View all orders as super-admin
- ✅ Add/edit/delete products as super-admin
- ✅ Change user roles as super-admin
