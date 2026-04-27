# Core Data Setup Guide for GLOWZA

## Overview
The Core Data layer has been integrated to provide local persistence alongside Firebase. All booking, profile, and notification data is now stored in both Core Data (local) and Firebase (cloud).

## Files Created

### Core Data Infrastructure
- **CoreDataStack.swift** - Manages Core Data container, context, and persistence
- **CoreDataEntities.swift** - NSManagedObject subclasses for all entities
- **DataRepositories.swift** - Repository pattern for CRUD operations
- **DataSyncManager.swift** - Utilities for syncing between Core Data and Firebase

### Modified Files
- **GLOWZAApp.swift** - Initializes CoreDataStack before Firebase
- **BookingStore.swift** - Saves bookings to Core Data when created
- **NotificationManager.swift** - Saves notifications to Core Data

## Setting Up the Core Data Model File (.xcdatamodeld)

The Core Data model file needs to be created in Xcode. Follow these steps:

### Step 1: Create New Data Model
1. Open GLOWZA.xcodeproj in Xcode
2. File → New → File
3. Select "Data Model" template
4. Name it "GLOWZA"
5. Choose the GLOWZA target
6. Click Create

### Step 2: Add Entities to the Model

Open GLOWZA.xcdatamodeld and add these entities:

#### Entity 1: CDBooking
- **Attributes:**
  - id (UUID) - Required
  - userId (String) - Required
  - userName (String) - Required
  - salonName (String) - Required
  - salonLocation (String) - Required
  - serviceName (String) - Required
  - servicePrice (Double) - Optional
  - date (Date) - Required
  - timeSlot (String) - Required
  - receiptNumber (String) - Required
  - paymentMethod (String) - Required
  - amountPaid (Double) - Optional
  - status (String) - Required
  - signatureImageData (Binary) - Optional
  - userId (String) - Required
  - firestoreID (String) - Optional
  - createdAt (Date) - Required
  - updatedAt (Date) - Required
- **Relationships:**
  - review → CDReview (one-to-one)

#### Entity 2: CDReview
- **Attributes:**
  - id (UUID) - Required
  - rating (Int16) - Required
  - comment (String) - Required
  - date (Date) - Required
  - reviewerName (String) - Required
- **Relationships:**
  - booking → CDBooking (one-to-one, inverse: review)

#### Entity 3: CDNotification
- **Attributes:**
  - id (UUID) - Required
  - title (String) - Required
  - subtitle (String) - Required
  - icon (String) - Optional
  - type (String) - Required (success, info, error, warning)
  - createdAt (Date) - Required
  - isRead (Boolean) - Default: false
  - userId (String) - Optional

#### Entity 4: CDUserProfile
- **Attributes:**
  - userId (String) - Required
  - email (String) - Required
  - name (String) - Required
  - phone (String) - Optional
  - profileImageData (Binary) - Optional
  - createdAt (Date) - Required
  - updatedAt (Date) - Required

#### Entity 5: CDSalon (Optional - for offline reference)
- **Attributes:**
  - id (UUID) - Required
  - name (String) - Required
  - location (String) - Required
  - distance (String) - Optional
  - rating (Double) - Optional
  - reviewCount (Int32) - Optional
  - score (Double) - Optional
  - about (String) - Optional
  - phone (String) - Optional
  - openHours (String) - Optional

#### Entity 6: CDSalonService
- **Attributes:**
  - id (UUID) - Required
  - name (String) - Required
  - icon (String) - Optional
  - duration (String) - Optional
  - price (Double) - Optional
  - category (String) - Optional
  - benefits (String) - Optional

## Data Flow Architecture

```
┌─────────────────┐
│   App Views     │
│   (SwiftUI)     │
└────────┬────────┘
         │
         ↓
┌─────────────────────────┐
│   BookingStore          │
│   NotificationManager   │
│   (Observable)          │
└────────┬────────────────┘
         │
    ┌────┴────┐
    ↓         ↓
┌──────────┐  ┌──────────────┐
│Core Data │  │Firebase      │
│(Local)   │  │(Cloud)       │
└──────────┘  └──────────────┘
    │            │
    └────┬───────┘
         ↓
    ┌──────────┐
    │User Data │
    │Persisted │
    └──────────┘
```

## Usage Examples

### Saving a Booking
```swift
// Automatically saved to Core Data AND Firebase
await BookingStore.shared.createBooking(
    salonName: "Haley Avenue",
    salonLocation: "Moratuwa",
    serviceName: "Facial Treatment",
    servicePrice: 3500,
    date: Date(),
    timeSlot: "2:00 PM",
    paymentMethod: "card",
    amountPaid: 3500
)
```

### Fetching Bookings
```swift
let bookings = try BookingRepository.shared.fetchBookingsFromCore(userId: userID)
let cdBookings = try BookingRepository.shared.fetchAllBookingsFromCore()
```

### Adding a Review
```swift
try BookingRepository.shared.addReviewToCore(
    bookingId: bookingID,
    rating: 5,
    comment: "Excellent service!",
    reviewerName: "John Doe"
)
```

### Syncing Data
```swift
await DataSyncManager.shared.syncCoreDataToFirebase(userId: userID)
```

## Key Features

✅ **Dual Persistence**: Data stored in both Core Data (local) and Firebase (cloud)
✅ **Automatic Sync**: New bookings automatically saved to both stores
✅ **Offline Support**: Core Data allows app to work without internet
✅ **Type Safety**: Strong typing with NSManagedObject subclasses
✅ **Transaction Support**: Save operations are atomic and consistent

## Firebase Integration

The Core Data layer works alongside existing Firebase services:
- **Bookings**: Synced to `users/{userId}/bookings` in Firestore
- **Reviews**: Stored in `bookings/{bookingId}/reviews` in Firestore
- **Profiles**: Synced to `users/{userId}` document

## Troubleshooting

### Issue: "NSPersistentContainer not loading"
- Ensure GLOWZA.xcdatamodeld exists in project
- Verify it's added to GLOWZA target
- Check console for Core Data initialization errors

### Issue: "Migration conflicts"
- Delete app from simulator: `xcrun simctl erase all`
- Rebuild and run clean

### Issue: "Data not syncing to Firebase"
- Check Firebase permissions in Firestore rules
- Verify network connectivity
- Ensure user is authenticated

## Next Steps

1. Create GLOWZA.xcdatamodeld in Xcode (see instructions above)
2. Build and run the project
3. Test booking creation - should save to both Core Data and Firebase
4. Monitor console for ✅ and ❌ messages
5. Check device settings > GLOWZA > Data & Privacy to verify Core Data storage

## Performance Tips

- Core Data queries are indexed on `userId` and `date` for fast lookups
- Batch operations use `batchSize` parameter for memory efficiency
- Background saves use `asyncAfter` to avoid UI blocking
- Notification saves are non-blocking to prevent animation jank

## Security Considerations

- Sensitive data (signature images) is compressed to 80% JPEG quality
- All user data is linked to authenticated `userId`
- Notifications are stored per-user
- Consider encrypting Core Data in production using `NSPersistentStoreDescription`
