import CoreData
import Foundation
import UIKit

// MARK: - Booking Repository (Core Data + Firebase)
final class BookingRepository {
    static let shared = BookingRepository()
    private let coreDataStack = CoreDataStack.shared

    private init() {}

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
        receiptNumber: String,
        paymentMethod: String,
        amountPaid: Double,
        firestoreID: String? = nil,
        signatureImage: UIImage? = nil
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
        booking.receiptNumber = receiptNumber
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
    }

    func fetchBookingsFromCore(userId: String) throws -> [CDBooking] {
        let request: NSFetchRequest<CDBooking> = CDBooking.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBooking.date, ascending: false)]
        return try coreDataStack.context.fetch(request)
    }

    func fetchAllBookingsFromCore() throws -> [CDBooking] {
        let request: NSFetchRequest<CDBooking> = CDBooking.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBooking.date, ascending: false)]
        return try coreDataStack.context.fetch(request)
    }

    func updateBookingStatus(_ bookingId: UUID, status: String) throws {
        let request: NSFetchRequest<CDBooking> = CDBooking.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", bookingId as CVarArg)

        if let booking = try coreDataStack.context.fetch(request).first {
            booking.status = status
            booking.updatedAt = Date()
            try coreDataStack.save()
        }
    }

    func addReviewToCore(bookingId: UUID, rating: Int, comment: String, reviewerName: String) throws {
        let request: NSFetchRequest<CDBooking> = CDBooking.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", bookingId as CVarArg)

        if let booking = try coreDataStack.context.fetch(request).first {
            let review = CDReview(context: coreDataStack.context)
            review.id = UUID()
            review.rating = Int16(rating)
            review.comment = comment
            review.date = Date()
            review.reviewerName = reviewerName
            booking.review = review
            try coreDataStack.save()
        }
    }

    func deleteBookingFromCore(_ bookingId: UUID) throws {
        let request: NSFetchRequest<CDBooking> = CDBooking.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", bookingId as CVarArg)

        if let booking = try coreDataStack.context.fetch(request).first {
            coreDataStack.context.delete(booking)
            try coreDataStack.save()
        }
    }

    func syncBookingWithFirebase(_ cdBooking: CDBooking, firestoreID: String) async throws {
        cdBooking.firestoreID = firestoreID
        cdBooking.updatedAt = Date()
        try coreDataStack.save()
    }

    func convertCDBookingToBooking(_ cdBooking: CDBooking) -> Booking? {
        let salon = SalonCatalog.shared.salon(named: cdBooking.salonName)
        let service = salon.services.first(where: { $0.name == cdBooking.serviceName })
            ?? SalonService(
                name: cdBooking.serviceName,
                icon: "sparkles",
                duration: "",
                price: cdBooking.servicePrice,
                category: ""
            )

        let paymentMethod = PaymentMethodType(rawValue: cdBooking.paymentMethod) ?? .card
        let status: BookingStatus = {
            switch cdBooking.status {
            case "upcoming": return .upcoming
            case "completed": return .completed
            case "cancelled": return .cancelled
            default: return .upcoming
            }
        }()

        let review = cdBooking.review.map {
            BookingReview(
                rating: Int($0.rating),
                comment: $0.comment,
                date: $0.date,
                reviewerName: $0.reviewerName
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

// MARK: - Notification Repository
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
        let notification = CDNotification(context: coreDataStack.context)
        notification.id = UUID()
        notification.title = title
        notification.subtitle = subtitle
        notification.icon = icon
        notification.type = type
        notification.createdAt = Date()
        notification.isRead = false
        notification.userId = userId
        try coreDataStack.save()
    }

    func fetchNotificationsFromCore(userId: String? = nil) throws -> [CDNotification] {
        let request: NSFetchRequest<CDNotification> = CDNotification.fetchRequest()
        if let userId {
            request.predicate = NSPredicate(format: "userId == %@", userId)
        }
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDNotification.createdAt, ascending: false)]
        return try coreDataStack.context.fetch(request)
    }

    func markNotificationAsRead(_ notificationId: UUID) throws {
        let request: NSFetchRequest<CDNotification> = CDNotification.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", notificationId as CVarArg)

        if let notification = try coreDataStack.context.fetch(request).first {
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
        skinType: String? = nil,
        dateOfBirth: String? = nil,
        avatarBase64: String? = nil,
        profileImage: UIImage? = nil
    ) throws {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)

        let profile: CDUserProfile
        if let existing = try coreDataStack.context.fetch(request).first {
            profile = existing
        } else {
            profile = CDUserProfile(context: coreDataStack.context)
            profile.userId = userId
            profile.createdAt = Date()
        }

        profile.email = email
        profile.name = name
        profile.phone = phone
        if let skinType { profile.skinType = skinType }
        if let dateOfBirth { profile.dateOfBirth = dateOfBirth }
        if let avatarBase64 { profile.avatarBase64 = avatarBase64 }
        if let profileImage { profile.profileImageData = profileImage.jpegData(compressionQuality: 0.8) }
        profile.updatedAt = Date()

        try coreDataStack.save()
    }

    func fetchProfile(userId: String) throws -> CDUserProfile? {
        let request: NSFetchRequest<CDUserProfile> = CDUserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", userId)
        return try coreDataStack.context.fetch(request).first
    }
}

// MARK: - Salon Repository (Core Data offline cache)
final class SalonRepository {
    static let shared = SalonRepository()
    private let coreDataStack = CoreDataStack.shared

    private init() {}

    func upsertSalon(_ salon: Salon) throws {
        let context = coreDataStack.context
        let request: NSFetchRequest<CDSalon> = CDSalon.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", salon.name)

        let cdSalon: CDSalon
        if let existing = try context.fetch(request).first {
            cdSalon = existing
            if let oldServices = cdSalon.services as? Set<CDSalonService> {
                oldServices.forEach { context.delete($0) }
            }
        } else {
            cdSalon = CDSalon(context: context)
            cdSalon.id = UUID()
        }

        cdSalon.name = salon.name
        cdSalon.location = salon.location
        cdSalon.distance = salon.distance
        cdSalon.rating = salon.rating
        cdSalon.reviewCount = Int32(salon.reviewCount)
        cdSalon.score = salon.score
        cdSalon.about = salon.about
        cdSalon.phone = salon.phone
        cdSalon.openHours = salon.openHours

        for service in salon.services {
            let cdService = CDSalonService(context: context)
            cdService.id = UUID()
            cdService.name = service.name
            cdService.icon = service.icon
            cdService.duration = service.duration
            cdService.price = service.price
            cdService.category = service.category
            cdService.benefits = (try? JSONSerialization.data(withJSONObject: service.benefits))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
            cdService.salon = cdSalon
        }

        try coreDataStack.save()
    }

    func upsertSalons(_ salons: [Salon]) throws {
        for salon in salons { try upsertSalon(salon) }
    }

    func fetchAllSalons() throws -> [Salon] {
        let request: NSFetchRequest<CDSalon> = CDSalon.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDSalon.name, ascending: true)]

        return try coreDataStack.context.fetch(request).map { cd in
            let services = ((cd.services as? Set<CDSalonService>) ?? [])
                .sorted { $0.name < $1.name }
                .map { svc -> SalonService in
                    let benefits: [String]
                    if let data = svc.benefits.data(using: .utf8),
                       let arr = try? JSONSerialization.jsonObject(with: data) as? [String] {
                        benefits = arr
                    } else {
                        benefits = []
                    }
                    return SalonService(
                        name: svc.name,
                        icon: svc.icon,
                        duration: svc.duration,
                        price: svc.price,
                        category: svc.category,
                        benefits: benefits
                    )
                }

            return Salon(
                id: cd.id,
                name: cd.name,
                location: cd.location,
                distance: cd.distance,
                rating: cd.rating,
                reviewCount: Int(cd.reviewCount),
                score: cd.score,
                services: services,
                about: cd.about,
                phone: cd.phone,
                openHours: cd.openHours
            )
        }
    }
}
