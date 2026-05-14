import Foundation
import SwiftUI
import UIKit
import CoreLocation

// MARK: - Salon Service
// Represents a specific service offered by a salon (e.g., "Facial Treatment").
// It conforms to Identifiable so it can be used in SwiftUI lists easily!
// It conforms to Equatable so we can compare two services!
struct SalonService: Identifiable, Equatable {
    let id = UUID() // Automatically generates a unique ID!
    let name: String
    let icon: String // SF Symbol name.
    let duration: String // e.g., "60 min"
    let price: Double
    let category: String // e.g., "Skin", "Hair"
    let benefits: [String] // Bullet points of what this service does.

    init(name: String, icon: String, duration: String, price: Double,
         category: String, benefits: [String] = []) {
        self.name = name; self.icon = icon; self.duration = duration
        self.price = price; self.category = category; self.benefits = benefits
    }
}

// MARK: - Salon (full model)
// Represents a salon with all its details.
struct Salon: Identifiable {
    let id: UUID
    let name: String
    let location: String
    let distance: String // Distance from the user.
    let rating: Double // Star rating (e.g., 4.7)
    let reviewCount: Int
    let score: Double // Internal reputation score.
    let services: [SalonService] // List of services offered!
    let about: String
    let phone: String
    let openHours: String
    let imageName: String // Image asset name!
    let coordinate: CLLocationCoordinate2D // NEW: Geographical location!

    init(id: UUID = UUID(), name: String, location: String, distance: String,
         rating: Double, reviewCount: Int, score: Double,
         services: [SalonService], about: String, phone: String, openHours: String, imageName: String,
         coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)) {
        self.id = id; self.name = name; self.location = location
        self.distance = distance; self.rating = rating
        self.reviewCount = reviewCount; self.score = score
        self.services = services; self.about = about
        self.phone = phone; self.openHours = openHours
        self.imageName = imageName; self.coordinate = coordinate
    }
}

// MARK: - Payment Method
// Enum for the available payment methods in the app.
enum PaymentMethodType: String, CaseIterable {
    case card   = "Credit / Debit Card"
    case cash   = "Pay at Salon"
    case online = "Online Banking"

    // Returns a SF Symbol name for each payment method!
    var icon: String {
        switch self {
        case .card:   return "creditcard"
        case .cash:   return "banknote"
        case .online: return "globe"
        }
    }
}

// MARK: - Booking Draft
// This is used to hold the state while the user is filling out the booking form!
// It is mutable (var) because the user changes these values step-by-step.
struct BookingDraft {
    var salon: Salon
    var service: SalonService?           = nil
    var date: Date                       = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    var timeSlot: String                 = ""
    var signatureImage: UIImage?         = nil // Digital signature!
    var agreedConsent: String            = ""  // The legal text agreed upon!
    var paymentMethod: PaymentMethodType = .card

    // Hardcoded time slots for the demo.
    static let timeSlots: [(time: String, available: Bool)] = [
        ("9:00 AM",  true),  ("9:45 AM",  true),  ("10:30 AM", true),
        ("11:15 AM", true),  ("12:00 PM", true),  ("12:45 PM", true),
        ("1:30 PM",  true),  ("2:15 PM",  true),  ("3:00 PM",  true),
        ("3:45 PM",  true),  ("4:30 PM",  true),  ("5:15 PM",  true),
        ("6:00 PM",  true),  ("6:45 PM",  true),  ("7:30 PM",  true),
        ("8:15 PM",  true),  ("9:00 PM",  true),  ("9:45 PM",  true),
        ("10:00 PM", true)
    ]
}

// MARK: - Booking
// This represents a completed booking.
// It is immutable (let) because once a booking is made, its core details shouldn't change!
struct Booking: Identifiable {
    let id: UUID
    let salon: Salon
    let service: SalonService
    let date: Date
    let timeSlot: String
    let receiptNumber: String // e.g., "GLZ-12345"
    let paymentMethod: PaymentMethodType
    let amountPaid: Double
    let signatureImage: UIImage?
    let agreedConsent: String // The terms the user signed!
    var status: BookingStatus // Can be updated (upcoming, completed, cancelled).
    var review: BookingReview? // Optional review added by the user!

    // Helper to generate a random receipt number!
    static func generateReceiptNumber() -> String { "GLZ-\(Int.random(in: 10000...99999))" }
}

enum BookingStatus { case upcoming, completed, cancelled }

// MARK: - Review
// Represents a review left by a user for a booking.
struct BookingReview: Identifiable {
    let id = UUID()
    let rating: Int       // 1–5 stars.
    let comment: String
    let date: Date
    let reviewerName: String
}

// MARK: - Static Salon Catalog
// This acts as a mock database of salons for the app.
// It uses the Singleton pattern (`shared`) so it can be accessed anywhere!
struct SalonCatalog {
    static let shared = SalonCatalog()
    private init() {} // Prevents creating other instances!

    // Hardcoded list of salons with their services!
    let salons: [Salon] = [
        Salon(name: "Golden Avenue",   location: "Moratuwa, Colombo",     distance: "2 km",   rating: 4.7, reviewCount: 312, score: 0.95, services: SalonCatalog.mockServices(), about: "Premier aesthetic salon offering sophisticated beauty treatments.", phone: "+94 11 234 5678", openHours: "Mon–Sat: 9:00 AM – 7:00 PM", imageName: "Salon1",  coordinate: CLLocationCoordinate2D(latitude: 6.7730, longitude: 79.8820)),
        Salon(name: "Glow Studio",     location: "Moratuwa, Colombo",     distance: "3.5 km", rating: 4.7, reviewCount: 312, score: 0.88, services: SalonCatalog.mockServices(), about: "Specializes in non-invasive aesthetic treatments and advanced skincare.", phone: "+94 11 345 6789", openHours: "Mon–Sun: 8:00 AM – 8:00 PM", imageName: "salon2",  coordinate: CLLocationCoordinate2D(latitude: 6.8900, longitude: 79.9100)),
        Salon(name: "Luxe Aesthetics", location: "Dehiwala, Colombo",     distance: "5 km",   rating: 4.5, reviewCount: 198, score: 0.82, services: SalonCatalog.mockServices(), about: "Boutique clinic focusing on premium aesthetic medicine and transformations.", phone: "+94 11 456 7890", openHours: "Tue–Sun: 10:00 AM – 6:00 PM", imageName: "salon3",  coordinate: CLLocationCoordinate2D(latitude: 6.8500, longitude: 79.8700)),
        Salon(name: "Velvet Touch",    location: "Nugegoda, Colombo",     distance: "1.5 km", rating: 4.6, reviewCount: 180, score: 0.90, services: SalonCatalog.mockServices(), about: "Exquisite touch for your skin and hair needs.", phone: "+94 11 567 8901", openHours: "Mon–Sat: 9:00 AM – 8:00 PM", imageName: "salon4",  coordinate: CLLocationCoordinate2D(latitude: 6.8655, longitude: 79.8991)),
        Salon(name: "Aura Beauty Bar", location: "Mount Lavinia, Colombo", distance: "4 km",   rating: 4.4, reviewCount: 90,  score: 0.85, services: SalonCatalog.mockServices(), about: "Relaxing atmosphere with top-tier beauty services.", phone: "+94 11 678 9012", openHours: "Daily: 10:00 AM – 7:00 PM", imageName: "salon5",  coordinate: CLLocationCoordinate2D(latitude: 6.8300, longitude: 79.8600)),
        Salon(name: "Silk & Shine",    location: "Battaramulla, Colombo", distance: "2.5 km", rating: 4.3, reviewCount: 120, score: 0.80, services: SalonCatalog.mockServices(), about: "Leading salon for hair transformations and shine.", phone: "+94 11 789 0123", openHours: "Mon–Sat: 9:30 AM – 7:30 PM", imageName: "salon6",  coordinate: CLLocationCoordinate2D(latitude: 6.8901, longitude: 79.8812)),
        Salon(name: "Prime Beauty",    location: "Wattala, Colombo",      distance: "3 km",   rating: 4.9, reviewCount: 400, score: 0.98, services: SalonCatalog.mockServices(), about: "The gold standard of beauty in the city.", phone: "+94 11 890 1234", openHours: "Daily: 9:00 AM – 9:00 PM", imageName: "salon7",  coordinate: CLLocationCoordinate2D(latitude: 6.9907, longitude: 79.8910)),
        Salon(name: "Elegance Salon",  location: "Malabe, Colombo",       distance: "6 km",   rating: 4.2, reviewCount: 80,  score: 0.75, services: SalonCatalog.mockServices(), about: "Elegance and class in every treatment.", phone: "+94 11 901 2345", openHours: "Tue–Sun: 10:00 AM – 7:00 PM", imageName: "salon8",  coordinate: CLLocationCoordinate2D(latitude: 6.9062, longitude: 79.9582)),
        Salon(name: "Crystal Beauty",  location: "Maharagama, Colombo",   distance: "7 km",   rating: 4.1, reviewCount: 60,  score: 0.70, services: SalonCatalog.mockServices(), about: "Crystal clear results for your skin and nails.", phone: "+94 11 012 3456", openHours: "Mon–Sat: 9:00 AM – 6:00 PM", imageName: "salon9",  coordinate: CLLocationCoordinate2D(latitude: 6.8500, longitude: 79.9200)),
        Salon(name: "Radiant Aesthetic", location: "Bambalapitiya, Colombo", distance: "1 km",   rating: 5.0, reviewCount: 500, score: 1.00, services: SalonCatalog.mockServices(), about: "Radiate confidence with our expert aesthetic care.", phone: "+94 11 123 4567", openHours: "Mon–Sun: 8:00 AM – 9:00 PM", imageName: "salon10", coordinate: CLLocationCoordinate2D(latitude: 6.8800, longitude: 79.8900)),
        Salon(name: "Glow Palace",     location: "Colombo 03",            distance: "4.5 km", rating: 4.5, reviewCount: 140, score: 0.87, services: SalonCatalog.mockServices(), about: "Feel like royalty at the Glow Palace.", phone: "+94 11 234 5670", openHours: "Daily: 9:00 AM – 8:00 PM", imageName: "salon11", coordinate: CLLocationCoordinate2D(latitude: 6.8400, longitude: 79.9000)),
        Salon(name: "Pure Skin Lab",   location: "Colombo 07",            distance: "5.5 km", rating: 4.6, reviewCount: 160, score: 0.89, services: SalonCatalog.mockServices(), about: "Scientific approach to pure, healthy skin.", phone: "+94 11 345 6781", openHours: "Mon–Fri: 10:00 AM – 7:00 PM", imageName: "salon12", coordinate: CLLocationCoordinate2D(latitude: 6.9070, longitude: 79.8959)),
        Salon(name: "The Hair Lounge", location: "Colombo 04",            distance: "2 km",   rating: 4.4, reviewCount: 110, score: 0.84, services: SalonCatalog.mockServices(), about: "The ultimate destination for hair styling and care.", phone: "+94 11 456 7892", openHours: "Mon–Sat: 9:00 AM – 7:00 PM", imageName: "salon13", coordinate: CLLocationCoordinate2D(latitude: 6.8747, longitude: 79.8602)),
        Salon(name: "Serene Spa",      location: "Colombo 05",            distance: "8 km",   rating: 4.3, reviewCount: 70,  score: 0.78, services: SalonCatalog.mockServices(), about: "Peaceful retreat with luxury spa treatments.", phone: "+94 11 567 8903", openHours: "Daily: 10:00 AM – 10:00 PM", imageName: "salon14", coordinate: CLLocationCoordinate2D(latitude: 6.8792, longitude: 79.8768)),
        Salon(name: "Urban Nails",     location: "Colombo 06",            distance: "3.5 km", rating: 4.7, reviewCount: 220, score: 0.91, services: SalonCatalog.mockServices(), about: "Modern nail art and premium care in the city.", phone: "+94 11 678 9014", openHours: "Mon–Sat: 10:00 AM – 8:00 PM", imageName: "salon15", coordinate: CLLocationCoordinate2D(latitude: 6.8760, longitude: 79.8583)),
        Salon(name: "Divine Beauty",   location: "Colombo 08",            distance: "4.2 km", rating: 4.5, reviewCount: 130, score: 0.86, services: SalonCatalog.mockServices(), about: "Divine care for your skin, hair, and soul.", phone: "+94 11 789 0125", openHours: "Mon–Sat: 9:00 AM – 7:00 PM", imageName: "salon16", coordinate: CLLocationCoordinate2D(latitude: 6.9123, longitude: 79.8673)),
        Salon(name: "Bloom Studio",    location: "Colombo 01",            distance: "2.8 km", rating: 4.6, reviewCount: 170, score: 0.89, services: SalonCatalog.mockServices(), about: "Let your beauty bloom with our expert stylists.", phone: "+94 11 890 1236", openHours: "Daily: 9:00 AM – 7:00 PM", imageName: "salon17", coordinate: CLLocationCoordinate2D(latitude: 6.9142, longitude: 79.8774)),
        Salon(name: "Infinity Glow",   location: "Colombo 10",            distance: "6.5 km", rating: 4.3, reviewCount: 95,  score: 0.81, services: SalonCatalog.mockServices(), about: "Infinite possibilities for a glowing you.", phone: "+94 11 901 2347", openHours: "Tue–Sun: 10:00 AM – 8:00 PM", imageName: "salon18", coordinate: CLLocationCoordinate2D(latitude: 6.9272, longitude: 79.8503)),
        Salon(name: "Skin Deep",       location: "Colombo 02",            distance: "1.8 km", rating: 4.8, reviewCount: 240, score: 0.93, services: SalonCatalog.mockServices(), about: "Understanding your skin's needs at a deeper level.", phone: "+94 11 012 3458", openHours: "Daily: 9:00 AM – 9:00 PM", imageName: "salon19", coordinate: CLLocationCoordinate2D(latitude: 6.9350, longitude: 79.8447)),
        Salon(name: "The Beauty Room", location: "Colombo 09",            distance: "3.2 km", rating: 4.4, reviewCount: 115, score: 0.83, services: SalonCatalog.mockServices(), about: "Intimate and professional beauty services for all.", phone: "+94 11 123 4569", openHours: "Mon–Sat: 9:30 AM – 6:30 PM", imageName: "salon20", coordinate: CLLocationCoordinate2D(latitude: 6.8959, longitude: 79.8743))
    ]

    // Helper function to provide a mock list of services for all salons to keep code clean.
    private static func mockServices() -> [SalonService] {
        return [
            SalonService(name: "Facial Treatment",    icon: "face.smiling",     duration: "60 min", price: 3500,  category: "Skin",      benefits: ["Hydration", "Glow", "Anti-aging"]),
            SalonService(name: "Chemical Peel",       icon: "sparkles",         duration: "45 min", price: 5500,  category: "Skin",      benefits: ["Exfoliation", "Brightening", "Acne care"]),
            SalonService(name: "Laser Hair Removal",  icon: "sun.max",          duration: "30 min", price: 8000,  category: "Hair",      benefits: ["Smooth skin", "Permanent", "Fast"]),
            SalonService(name: "Hair Treatment",      icon: "leaf",             duration: "90 min", price: 4500,  category: "Hair",      benefits: ["Repair", "Shine", "Nourishment"]),
            SalonService(name: "Manicure & Pedicure", icon: "hand.raised",      duration: "60 min", price: 2500,  category: "Nails",     benefits: ["Clean nails", "Relaxing", "Polish"]),
            SalonService(name: "Microneedling",       icon: "syringe",          duration: "75 min", price: 12000, category: "Skin",      benefits: ["Collagen boost", "Scar reduction"]),
            SalonService(name: "HydraFacial",         icon: "drop",             duration: "60 min", price: 15000, category: "Skin",      benefits: ["Deep hydration", "Pore cleaning"]),
            SalonService(name: "Body Scrub",          icon: "bubbles.and.sparkles", duration: "60 min", price: 6500, category: "Body",      benefits: ["Smooth skin", "Detox"]),
            SalonService(name: "Deep Tissue Massage", icon: "figure.walk",      duration: "90 min", price: 7500,  category: "Body",      benefits: ["Muscle relief", "Stress reduction"]),
            SalonService(name: "Eyelash Extensions",  icon: "eye",              duration: "120 min", price: 8500, category: "Eyes",      benefits: ["Long lashes", "Full volume"]),
            SalonService(name: "Eyebrow Threading",   icon: "scissors",         duration: "15 min", price: 800,   category: "Face",      benefits: ["Defined brows", "Quick"]),
            SalonService(name: "Teeth Whitening",     icon: "mouth",            duration: "45 min", price: 18000, category: "Aesthetic", benefits: ["Brighter smile", "Fast results"]),
            SalonService(name: "Aromatherapy",        icon: "wind",             duration: "60 min", price: 5000,  category: "Body",      benefits: ["Relaxation", "Healing"]),
            SalonService(name: "Nail Art",            icon: "paintpalette",     duration: "45 min", price: 3500,  category: "Nails",     benefits: ["Creative design", "Unique"]),
            SalonService(name: "Bridal Makeup",       icon: "star",             duration: "180 min", price: 45000, category: "Makeup",    benefits: ["Perfect look", "Long-lasting"])
        ]
    }

    // Helper function to find a salon by name!
    func salon(named name: String) -> Salon {
        if let matched = salons.first(where: { $0.name == name }) {
            return matched
        }

        // Fallback keeps the selected salon name instead of silently defaulting to Golden Avenue.
        let template = salons.first!
        return Salon(
            name: name,
            location: "Colombo",
            distance: "-",
            rating: 4.5,
            reviewCount: 0,
            score: 0.80,
            services: template.services,
            about: "Premium beauty and aesthetic services tailored to your needs.",
            phone: "+94 11 000 0000",
            openHours: "Mon–Sun: 9:00 AM – 7:00 PM",
            imageName: "Salon1"
        )
    }
}
