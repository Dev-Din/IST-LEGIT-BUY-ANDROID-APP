# Firestore Setup Instructions

## Step 1: Configure Firestore Security Rules

1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project: **IST-FLUTTER-ANDROID-APP**
3. Navigate to: **Firestore Database** → **Rules** tab
4. Replace the default rules with the following:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null && (request.auth.uid == userId || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow write: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
    }
    
    // Products collection
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if request.auth != null && (resource.data.userId == request.auth.uid || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update: if request.auth != null && (resource.data.userId == request.auth.uid || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

5. Click **"Publish"** button

## Step 2: Create Firestore Collections

1. In Firebase Console, go to: **Firestore Database** → **Data** tab
2. Click **"+ Start collection"** for each collection:

### Collection: `users`
- Collection ID: `users`
- Click **"Next"**
- Click **"Cancel"** (no initial document needed - app will create documents)
- Collection will appear empty, which is correct

### Collection: `products`
- Collection ID: `products`
- Click **"Next"**
- Click **"Cancel"** (no initial document needed - app will create documents)
- Collection will appear empty, which is correct

### Collection: `orders`
- Collection ID: `orders`
- Click **"Next"**
- Click **"Cancel"** (no initial document needed - app will create documents)
- Collection will appear empty, which is correct

## Step 3: Enable Firebase Authentication

1. In Firebase Console, go to: **Authentication** → **Get Started** (if first time)
2. Click on **"Sign-in method"** tab
3. Click on **"Email/Password"**
4. Toggle **"Enable"** to ON
5. Click **"Save"**

## Verification

After completing all steps, you should have:
- ✅ Security rules published
- ✅ Three empty collections: `users`, `products`, `orders`
- ✅ Email/Password authentication enabled

Your Firestore database is now ready for the LegitBuy app!
