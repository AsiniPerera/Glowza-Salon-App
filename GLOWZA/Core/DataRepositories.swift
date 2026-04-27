import CoreData
import Foundation
import UIKit

// MARK: - Booking Repository (Core Data + Firebase)
final class BookingRepository {
    static let shared = BookingRepository()
    private let coreDataStack = CoreDataStack.shared
    
    private init() {}
    
    // MARK: - Core Data Operations
    
    func saveBookingToCore(
        id: UUID = UUID(),
        userId: String,
        userName: String,
        salonName: String,
        salonLocation: String,
        serviceName: String,
        servicePrice: Double,
        date: Date,
        timeSlot: String,
        paymentMethod: String,
        amountPaid: Double,
        signatureImage: UIImage? = nil,
        firestoreID: String? = nil
    ) throws {
        let context = coreDataStack.context
        let booking = CDBooking(context: context)
        
        booking.id = id
        booking.userId = userId
        booking.userName = userName
        booking.salonName = salonName
        booking.salonLocation = salonLocation
        booking.serviceName = serviceName
        booking.servicePrice = servicePrice
        booking.date = date
        booking.timeSlot = timeSlot
        booking.receiptNumber = "GLZ-\(Int.random(in: 10000...99999))"
        booking.paymentMethod = paymentMethod
        booking.amountPaid = amountPaid
        booking.status = "upcoming"
        booking.createdAt = Date()
        booking.updatedAt = Date()
        booking.firestoreID = firestoreID
        
        if let image = signatureImage {
            booking.signatureImageData = image.jpegData(compressionQuality: 0.8)
        }
        
        try coreDataStack.save()
        print("✅ Booking saved to Core Data: \(booking.receiptNumber)")
    }
    
    func fetchBookingsFromCore(userId: String) throws -> [CDBooking] {
        let context = coreDataStack.context
        let request: NSFetchRequest<CDBooking> = CDBooking.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBooking.date, ascending: false)]
        
        return try context.fetch(request)
    }
    
    func fetchAllBookingsFromCore() throws -> [CDBooking] {
        let context = coreDataStack.context
        let request: NSFetchRequest<CDBooking> = CDBooking.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBooking.date, ascending: false)]
        return try context.fetch(request)
    }
    
    func updateBookingStatus(_ bookingId: UUID, status: String) throws {
        let context = coreDataStack.context
        let request: NSFetchRequest<CDBooking> = CDBooking.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", bookingId as CVarArg)
        
        if let booking = try context.fetch(request).first {
            booking.status = status
            booking.updatedAt = Date()
            try coreDataStack.save()
            print("✅ Booking status updated: \(status)")
        }
    }
    
    func addReviewToCore(bookingId: UUID, rating: Int, comment: String, reviewerName: String) throws {
        let context = coreDataStack.context
        let request: NSFetchRequest<CDBooking> = CDBooking.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", bookingId as CVarArg)
        
        if let booking = try context.fetch(request).first {
            let review = CDReview(context: context)
            review.id = UUID()
            review.rating = Int16(rating)
            review.comment = comment
            review.date = Date()
            review.reviewerName = reviewerName
            
            booking.review = review
            try coreDataStack.save()
            print("✅ Review added to Core Data")
        }
    }
    
    func deleteBookingFromCore(_ bookingId: UUID) throws {
        let context = coreDataStack.context
        let request: NSFetchRequest<CDBooking> = CDBooking.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", bookingId as CVarArg)
        
        if let booking = try context.fetch(request).first {
            context.delete(booking)
            try coreDataStack.save()
            print("✅ Booking deleted from Core Data")
        }
    }
    
    // MARK: - Sync with Firebase
    
    func syncBookingWithFirebase(
        _ cdBooking: CDBooking,
        firestoreID: String
    ) async throws {
        cdBooking.firestoreID = firestoreID
        cdBooking.updatedAt = Date()
        try coreDataStack.save()
        print("✅ Booking synced with Firebase: \(firestoreID)")
    }
    
    func convertCDBookingToBooking(_ cdBooking: CDBooking) -> Booking? {
        guard let salon = SalonCatalog.shared.salons.first(where: { $0.name == cdBooking.salonName }),
              let service = salon.services.first(where: { $0.name == cdBooking.serviceName }) else {
            return nil
        }
        
        let paymentMethod = PaymentMethodType(rawValue: cdBooking.paymentMethod) ?? .card
        let status: BookingStatus = {
            switch cdBooking.status {
            case "upcoming": return .upcoming
            case "completed": return .completed
            case "cancelled": return .cancelled
            default: return .upcoming
            }
        }()
        
        var review: BookingReview? = nil
        if let cdReview = cdBooking.review {
            review = BookingReview(
                rating: Int(cdReview.rating),
                comment: cdReview.comment,
                date: cdReview.date,
                reviewerName: cdReview.reviewerName
            )
        }
        
        return Booking(
            id: cdBooking.id,
            salon: salon,
            service: service,
            date: cdBooking.date,
            timeSlot: cdBooking.timeSlot,
            receiptNumber: cdBooking.receiptNumber,
            paymentMethod: paymentMethod,
            amountPaid: cdBooking.amountPaid,
            signatureImage: nil,
            status: status,
            review: review
        )
    }
}

// MARK: - Notification Repository (Core Data + Events)
final class NotificationRepository {
    static let shared = NotificationRepository()
    private let coreDataStack = CoreDataStack.shared
    
    private init() {}
    
    func saveNotificationToCore(
        title: String,
        subtitle: String,
        icon: String,
        type: String,
        userId: String? = nil
    ) throws {
        let context = coreDataStack.context
        let notification = CDNotification(context: context)
        
        notification.id = UUID()
        notification.title = title
        notification.subtitle = subtitle
        notification.icon = icon
        notification.type = type
        notification.createdAt = Date()
        notification.isRead = false
        notification.userId = userId
        
        try coreDataStack.save()
        print("✅ Notification saved to Core Data")
    }
    
    func fetchNotificationsFromCore(userId: String? = nil) throws -> [CDNotification] {
        let context = coreDataStack.context
        let request: NSFetchRequest<CDNotification> = CDNotification.fetchRequest()
        
        if let userId = userId {
            request.predicate = NSPredicate(format: "userId == %@", userId)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDNotification.createdAt, ascending: false)]
        return try context.fetch(request)
    }
    
    func markNotificationAsRead(_ notificationId: UUID) throws {
        let context = coreDataStack.context
        let request: NSFetchRequest<CDNotification> = CDNotification.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", notificationId as CVarArg)
        
        if let notification = try context.fetch(request).first {
            notification.isRead = true
            try coreDataStack.save()
        }
    }
}

// MARK: - User Profile Repository
final class UserProfileRepository {
    static let shared = UserProfileRepository()
    private let coreDataStack = CoreDataStack.shared
    
    private init() {}
    
    func saveOrUpdateProfile(
        userId: String,
        email: String,
        name: String,
        phone: String? = nil,
        profileImage: UIImage? = nil
    ) throws {
        let context = coreDataStack.context
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        
        let profile: CDUserProfile
        if let existingProfile = try context.fetch(request).first {
            profile = existingProfile
        } else {
            profile = CDUserProfile(context: context)
            profile.userId = userId
            profile.createdAt = Date()
        }
        
        profile.email = email
        profile.name = name
        profile.phone = phone
        profile.updatedAt = Date()
        
        if let image = profileImage {
            profile.profileImageData = image.jpegData(compressionQuality: 0.8)
        }
        
        try coreDataStack.save()
        print("✅ User profile saved to Core Data")
    }
    
    func fetchProfile(userId: String) throws -> CDUserProfile? {
        let context = coreDataStack.context
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        return try context.fetch(request).first
    }
}
