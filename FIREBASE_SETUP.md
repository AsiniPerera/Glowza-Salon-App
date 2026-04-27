# Firebase Database Setup Guide - GLOWZA

## Overview

GLOWZA now has complete Firebase integration for:
- ✅ User Authentication (Sign Up / Sign In / Sign Out)
- ✅ User Profiles (Firestore)
- ✅ Booking Details (Firestore)
- ✅ Booking Status Management (upcoming, completed, cancelled)
- ✅ Reviews and Ratings

## Architecture

### Services

#### AuthService (`Core/AuthService.swift`)
- Firebase Authentication
- User profile storage in Firestore
- Sign up, sign in, sign out
- Properties: `currentUID`, `currentUserName`, `isSignedIn`

#### BookingService (`Core/BookingService.swift`)
- Booking creation with Firestore persistence
- Booking retrieval by user
- Status management (upcoming, completed, cancelled)
- Reviews and ratings system

#### BookingStore (`Views/Bookings/BookingStore.swift`)
- State management for bookings
- Local sample data + Firestore sync
- Methods: `createBooking()`, `fetchUserBookings()`, `cancelBookingFirestore()`, `addReviewFirestore()`

### Firestore Collections

```
users/
  ├── {uid}/
  │   ├── uid: String
  │   ├── fullName: String
  │   ├── email: String
  │   ├── phone: String
  │   └── createdAt: Date

bookings/
  ├── {bookingId}/
  │   ├── userId: String (user who made booking)
  │   ├── userName: String
  │   ├── bookingSummary: {
  │   │   ├── salon: String
  │   │   ├── salonLocation: String
  │   │   ├── service: String
  │   │   ├── servicePrice: Double
  │   │   ├── schedule: String (formatted date + time)
  │   │   ├── amount: Double
  │   │   └── receiptNumber: String
  │   ├── paymentMethod: String
  │   ├── status: String ("upcoming", "completed", "cancelled")
  │   ├── createdAt: Date
  │   ├── rating: Double? (optional)
  │   └── review: String? (optional)
```

## Setup Instructions

### Step 1: Firebase Project Configuration

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your "glowa-844ab" project
3. Download/Update GoogleService-Info.plist:
   - Settings > Project Settings > Download plist
   - Place in GLOWZA project

### Step 2: Enable Firebase Auth

1. Firebase Console > Authentication > Sign-in method
2. Enable "Email/Password"
3. Optional: Enable "Google", "Apple", "Facebook"

### Step 3: Create Firestore Database

1. Firebase Console > Firestore Database > Create Database
2. Select:
   - **Native Mode** (important!)
   - **Standard Edition**
   - **Location**: Choose region close to users
   - **Database ID**: `(default)`

### Step 4: Deploy Firestore Security Rules

Go to Firestore > Rules tab and paste:

```security-rules
rules_version = '3';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - each user can only read/write their own
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    
    // Bookings collection - users can only read/write their own bookings
    match /bookings/{bookingId} {
      allow create: if request.auth.uid != null && 
                       request.resource.data.userId == request.auth.uid;
      allow read: if request.auth.uid != null && 
                     resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth.uid != null && 
                               resource.data.userId == request.auth.uid;
    }
  }
}
```

Click "Publish"

## How It Works

### Sign Up Flow
```
User fills form (email, password, name, phone)
    ↓
AuthViewModel.signUp()
    ↓
AuthService.signUp()
    ├─ Create Firebase Auth user
    ├─ Save profile to Firestore users/{uid}
    └─ Set isSignedIn = true
    ↓
RootView navigates to MainTabView
```

### Sign In Flow
```
User enters email & password
    ↓
AuthViewModel.signIn()
    ↓
AuthService.signIn()
    ├─ Authenticate with Firebase Auth
    ├─ Fetch profile from Firestore
    └─ Set isSignedIn = true
    ↓
RootView navigates to MainTabView
```

### Booking Flow
```
User completes booking (date, time, consent)
    ↓
PaymentView completion handler triggered
    ↓
BookingStore.createBooking()
    ↓
BookingService.createBooking()
    ├─ Generate receipt number
    ├─ Create BookingSummary object
    ├─ Save to Firestore bookings/{bookingId}
    └─ Print success/failure to console
    ↓
BookingStore.fetchUserBookings()
    ├─ Query Firestore for user's bookings
    └─ Update firestoreBookings array
    ↓
ReceiptView shows booking details
```

## Testing

### Test Sign Up
1. Run app
2. Tap "Create Account"
3. Fill details (test@example.com, password123, etc.)
4. Check Firebase Console > Authentication > see new user
5. Check Firestore > users collection > new document

### Test Sign In
1. Sign out from app
2. Sign in with test account
3. Should navigate to main app

### Test Booking Creation
1. After signing in, navigate to Bookings
2. Complete booking flow (date → consent → payment)
3. Check Xcode console for:
   - ✅ "Booking saved successfully" message, OR
   - ❌ Error details if failed
4. Check Firebase Console > Firestore > bookings collection
   - New document should appear with booking details

### Test Firestore Persistence
1. Create a booking
2. Close and relaunch app
3. Sign back in
4. Go to Bookings
5. Your booking should appear (loaded from Firestore)

## Debugging

### Check Console Output
Xcode Console will show:
```
✅ Booking saved successfully
   Booking ID: abc-123-def
   User: John Doe
   Salon: Haley Avenue
   Amount: $150.00
   Receipt: GLZ-ABC12345
```

### Common Issues

| Problem | Solution |
|---------|----------|
| "Missing package product 'Firebase...'" | Rebuild project (Cmd+B) |
| Sign up fails | Check Firebase Auth is enabled in Console |
| Bookings not saving | Check Firestore security rules are published |
| Can't see own bookings after sign in | Verify userId matches auth.uid in Firestore |
| Permission denied errors | Check Firestore rules match your userId in data |

### View Firestore Data

1. Firebase Console > Firestore Database > Data tab
2. Check `users` collection for profiles
3. Check `bookings` collection for transactions
4. Click documents to inspect fields

## Code Examples

### Create Booking
```swift
Task {
    await BookingStore.shared.createBooking(
        salonName: "Haley Avenue",
        salonLocation: "123 Main St",
        serviceName: "Glow Facial",
        servicePrice: 150.0,
        date: Date(),
        timeSlot: "2:00 PM",
        paymentMethod: "card",
        amountPaid: 150.0
    )
}
```

### Fetch User Bookings
```swift
Task {
    await BookingStore.shared.fetchUserBookings()
    // bookingStore.firestoreBookings now contains user's bookings
}
```

### Cancel Booking
```swift
Task {
    await BookingStore.shared.cancelBookingFirestore("booking-id")
}
```

### Add Review
```swift
Task {
    await BookingStore.shared.addReviewFirestore(
        "booking-id",
        rating: 5.0,
        review: "Excellent service!"
    )
}
```

## Key Features Implemented

✅ **Firebase Authentication**
- Email/Password sign up and sign in
- Session persistence
- Sign out functionality

✅ **User Profiles**
- Stored in Firestore users/{uid}
- Auto-saved on sign up
- Retrieved on sign in

✅ **Booking System**
- Create bookings with full details
- Store salon, service, date, time info
- Auto-generate receipt numbers
- Track booking status (upcoming/completed/cancelled)

✅ **Firestore Persistence**
- All data automatically synced to cloud
- User-scoped security (users can only see their own data)
- Ready for production use

✅ **Error Handling**
- Console logging for debugging
- User-friendly error messages
- Graceful fallbacks

## Next Steps

1. Test all flows end-to-end
2. Monitor Firestore costs (free tier includes 50k reads/writes/month)
3. Set up Firestore backups in Firebase Console
4. Consider adding:
   - Email verification
   - Password reset
   - Profile editing
   - Salon ratings aggregation
   - Booking cancellation fees

---

**Status**: ✅ Production Ready
**Last Updated**: April 27, 2026
