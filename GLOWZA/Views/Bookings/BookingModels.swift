import Foundation
import SwiftUI
import UIKit

// MARK: - Salon Service
struct SalonService: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let icon: String
    let duration: String
    let price: Double
    let category: String
    let benefits: [String]

    init(name: String, icon: String, duration: String, price: Double,
         category: String, benefits: [String] = []) {
        self.name = name; self.icon = icon; self.duration = duration
        self.price = price; self.category = category; self.benefits = benefits
    }
}

// MARK: - Salon (full model)
struct Salon: Identifiable {
    let id: UUID
    let name: String
    let location: String
    let distance: String
    let rating: Double
    let reviewCount: Int
    let score: Double
    let services: [SalonService]
    let about: String
    let phone: String
    let openHours: String

    init(id: UUID = UUID(), name: String, location: String, distance: String,
         rating: Double, reviewCount: Int, score: Double,
         services: [SalonService], about: String, phone: String, openHours: String) {
        self.id = id; self.name = name; self.location = location
        self.distance = distance; self.rating = rating
        self.reviewCount = reviewCount; self.score = score
        self.services = services; self.about = about
        self.phone = phone; self.openHours = openHours
    }
}

// MARK: - Payment Method
enum PaymentMethodType: String, CaseIterable {
    case card   = "Credit / Debit Card"
    case cash   = "Pay at Salon"
    case online = "Online Banking"

    var icon: String {
        switch self {
        case .card:   return "creditcard.fill"
        case .cash:   return "banknote.fill"
        case .online: return "globe"
        }
    }
}

// MARK: - Booking Draft (mutable, flows through UI steps)
struct BookingDraft {
    var salon: Salon
    var service: SalonService?           = nil
    var date: Date                       = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    var timeSlot: String                 = ""
    var signatureImage: UIImage?         = nil
    var paymentMethod: PaymentMethodType = .card

    static let timeSlots: [(time: String, available: Bool)] = [
        ("9:00 AM", true),  ("9:30 AM", false), ("10:00 AM", true),
        ("10:30 AM", true), ("11:00 AM", false), ("11:30 AM", true),
        ("2:00 PM",  true), ("2:30 PM",  true),  ("3:00 PM",  false),
        ("3:30 PM",  true), ("4:00 PM",  true),  ("4:30 PM",  true), ("5:00 PM", true)
    ]
}

// MARK: - Booking (immutable record stored in BookingStore)
struct Booking: Identifiable {
    let id: UUID
    let salon: Salon
    let service: SalonService
    let date: Date
    let timeSlot: String
    let receiptNumber: String
    let paymentMethod: PaymentMethodType
    let amountPaid: Double
    let signatureImage: UIImage?
    var status: BookingStatus
    var review: BookingReview?

    static func generateReceiptNumber() -> String { "GLZ-\(Int.random(in: 10000...99999))" }
}

enum BookingStatus { case upcoming, completed, cancelled }

// MARK: - Review
struct BookingReview: Identifiable {
    let id = UUID()
    let rating: Int       // 1–5
    let comment: String
    let date: Date
    let reviewerName: String
}

// MARK: - Static Salon Catalog
struct SalonCatalog {
    static let shared = SalonCatalog()
    private init() {}

    let salons: [Salon] = [
        Salon(
            name: "Haley Avenue",
            location: "Moratuwa, Colombo",
            distance: "2 km",
            rating: 4.7, reviewCount: 312, score: 0.95,
            services: [
                SalonService(name: "Facial Treatment",    icon: "face.smiling",     duration: "60 min", price: 3500,  category: "Skin",      benefits: ["Hydration", "Glow", "Anti-aging"]),
                SalonService(name: "Chemical Peel",       icon: "sparkles",         duration: "45 min", price: 5500,  category: "Skin",      benefits: ["Exfoliation", "Brightening", "Acne care"]),
                SalonService(name: "Laser Hair Removal",  icon: "sun.max.fill",     duration: "30 min", price: 8000,  category: "Hair",      benefits: ["Smooth skin", "Permanent", "Fast"]),
                SalonService(name: "Hair Treatment",      icon: "leaf.fill",        duration: "90 min", price: 4500,  category: "Hair",      benefits: ["Repair", "Shine", "Nourishment"]),
                SalonService(name: "Manicure & Pedicure", icon: "hand.raised.fill", duration: "60 min", price: 2500,  category: "Nails",     benefits: ["Clean nails", "Relaxing", "Polish"]),
            ],
            about: "Haley Avenue is a premier aesthetic salon offering sophisticated beauty treatments in a serene, luxurious environment. Our certified specialists are committed to delivering transformative results tailored to every client.",
            phone: "+94 11 234 5678",
            openHours: "Mon–Sat: 9:00 AM – 7:00 PM"
        ),
        Salon(
            name: "Glow Studio",
            location: "Moratuwa, Colombo",
            distance: "3.5 km",
            rating: 4.7, reviewCount: 312, score: 0.88,
            services: [
                SalonService(name: "Facial Treatment",    icon: "face.smiling",     duration: "60 min", price: 3000,  category: "Skin",      benefits: ["Deep cleanse", "Moisture", "Radiance"]),
                SalonService(name: "Botox / Anti-Aging",  icon: "cross.case.fill",  duration: "45 min", price: 25000, category: "Aesthetic", benefits: ["Wrinkle-free", "Lift", "Youthful"]),
                SalonService(name: "Dermal Fillers",      icon: "syringe.fill",     duration: "60 min", price: 35000, category: "Aesthetic", benefits: ["Volume", "Contouring", "Plumpness"]),
                SalonService(name: "Manicure & Pedicure", icon: "hand.raised.fill", duration: "60 min", price: 2200,  category: "Nails",     benefits: ["Soft skin", "Colour", "Relaxation"]),
            ],
            about: "Glow Studio specialises in non-invasive aesthetic treatments and advanced skincare. We combine modern technology with holistic beauty principles for visible, lasting results.",
            phone: "+94 11 345 6789",
            openHours: "Mon–Sun: 8:00 AM – 8:00 PM"
        ),
        Salon(
            name: "Luxe Aesthetics",
            location: "Dehiwala, Colombo",
            distance: "5 km",
            rating: 4.5, reviewCount: 198, score: 0.82,
            services: [
                SalonService(name: "Chemical Peel",         icon: "sparkles",       duration: "45 min", price: 6000,  category: "Skin",      benefits: ["Resurfacing", "Even tone", "Clarity"]),
                SalonService(name: "Laser Hair Removal",    icon: "sun.max.fill",   duration: "30 min", price: 9000,  category: "Hair",      benefits: ["Precision", "Long-lasting", "Safe"]),
                SalonService(name: "Fairness Injections",   icon: "syringe.fill",   duration: "30 min", price: 12000, category: "Aesthetic", benefits: ["Skin glow", "Even skin", "Brightening"]),
                SalonService(name: "Dark Circle Treatment", icon: "eye.fill",       duration: "45 min", price: 8500,  category: "Aesthetic", benefits: ["Refreshed eyes", "Lightening", "Hydration"]),
            ],
            about: "Luxe Aesthetics is a boutique clinic focusing on premium aesthetic medicine and personalised beauty transformations. Every treatment is precisely crafted for your unique skin needs.",
            phone: "+94 11 456 7890",
            openHours: "Tue–Sun: 10:00 AM – 6:00 PM"
        )
    ]

    func salon(named name: String) -> Salon { salons.first { $0.name == name } ?? salons[0] }
}
