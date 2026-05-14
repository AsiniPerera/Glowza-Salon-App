// TestHelpers.swift
// GLOWZATests
//
// Shared factory helpers for building test fixtures without Firebase or UIKit dependencies.

import Foundation
@testable import GLOWZA

// MARK: - Fixture Factory

enum Fixtures {

    // MARK: SalonService

    static func makeSalonService(
        name: String = "Test Facial",
        icon: String = "face.smiling",
        duration: String = "60 min",
        price: Double = 3500,
        category: String = "Skin",
        benefits: [String] = ["Hydration", "Glow"]
    ) -> SalonService {
        SalonService(
            name: name,
            icon: icon,
            duration: duration,
            price: price,
            category: category,
            benefits: benefits
        )
    }

    // MARK: Salon

    static func makeSalon(
        name: String = "Test Salon",
        location: String = "Colombo",
        distance: String = "1 km",
        rating: Double = 4.5,
        reviewCount: Int = 100,
        score: Double = 0.9
    ) -> Salon {
        Salon(
            name: name,
            location: location,
            distance: distance,
            rating: rating,
            reviewCount: reviewCount,
            score: score,
            services: [makeSalonService()],
            about: "A lovely test salon.",
            phone: "+94 11 234 5678",
            openHours: "9 AM – 6 PM",
            imageName: "Salon1" // Added for model compatibility!
        )
    }

    // MARK: Booking

    static func makeBooking(
        salon: Salon? = nil,
        service: SalonService? = nil,
        date: Date = Date().addingTimeInterval(86_400),   // tomorrow
        timeSlot: String = "10:00 AM",
        status: BookingStatus = .upcoming,
        paymentMethod: PaymentMethodType = .card
    ) -> Booking {
        let resolvedSalon = salon ?? makeSalon()
        let resolvedService = service ?? makeSalonService()
        return Booking(
            id: UUID(),
            salon: resolvedSalon,
            service: resolvedService,
            date: date,
            timeSlot: timeSlot,
            receiptNumber: Booking.generateReceiptNumber(),
            paymentMethod: paymentMethod,
            amountPaid: resolvedService.price,
            signatureImage: nil,
            agreedConsent: "I agree to the terms.", // Added for model compatibility!
            status: status
        )
    }

    // MARK: BookingReview

    static func makeReview(
        rating: Int = 5,
        comment: String = "Excellent!",
        reviewerName: String = "Test User"
    ) -> BookingReview {
        BookingReview(
            rating: rating,
            comment: comment,
            date: Date(),
            reviewerName: reviewerName
        )
    }
}
