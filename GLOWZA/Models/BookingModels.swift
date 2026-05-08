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
        ("9:00 AM",  true),  ("9:45 AM",  true),  ("10:30 AM", true),
        ("11:15 AM", true),  ("12:00 PM", true),  ("12:45 PM", true),
        ("1:30 PM",  true),  ("2:15 PM",  true),  ("3:00 PM",  true),
        ("3:45 PM",  true),  ("4:30 PM",  true),  ("5:15 PM",  true),
        ("6:00 PM",  true),  ("6:45 PM",  true),  ("7:30 PM",  true),
        ("8:15 PM",  true),  ("9:00 PM",  true),  ("9:45 PM",  true),
        ("10:00 PM", true)
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
                SalonService(name: "Microneedling",       icon: "syringe",          duration: "75 min", price: 12000, category: "Skin",      benefits: ["Collagen boost", "Scar reduction"]),
                SalonService(name: "HydraFacial",         icon: "drop.fill",        duration: "60 min", price: 15000, category: "Skin",      benefits: ["Deep hydration", "Pore cleaning"]),
                SalonService(name: "Body Scrub",          icon: "bubbles.and.sparkles", duration: "60 min", price: 6500, category: "Body",      benefits: ["Smooth skin", "Detox"]),
                SalonService(name: "Deep Tissue Massage", icon: "figure.walk",      duration: "90 min", price: 7500,  category: "Body",      benefits: ["Muscle relief", "Stress reduction"]),
                SalonService(name: "Eyelash Extensions",  icon: "eye.fill",         duration: "120 min", price: 8500, category: "Eyes",      benefits: ["Long lashes", "Full volume"]),
                SalonService(name: "Eyebrow Threading",   icon: "scissors",         duration: "15 min", price: 800,   category: "Face",      benefits: ["Defined brows", "Quick"]),
                SalonService(name: "Teeth Whitening",     icon: "mouth.fill",       duration: "45 min", price: 18000, category: "Aesthetic", benefits: ["Brighter smile", "Fast results"]),
                SalonService(name: "Aromatherapy",        icon: "wind",             duration: "60 min", price: 5000,  category: "Body",      benefits: ["Relaxation", "Healing"]),
                SalonService(name: "Nail Art",            icon: "paintpalette.fill", duration: "45 min", price: 3500,  category: "Nails",     benefits: ["Creative design", "Unique"]),
                SalonService(name: "Bridal Makeup",       icon: "star.fill",        duration: "180 min", price: 45000, category: "Makeup",    benefits: ["Perfect look", "Long-lasting"])
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
                SalonService(name: "Microblading",        icon: "pencil",           duration: "150 min", price: 28000, category: "Eyes",      benefits: ["Perfect brows", "Semi-permanent"]),
                SalonService(name: "Lip Filler",          icon: "mouth",            duration: "45 min", price: 22000, category: "Aesthetic", benefits: ["Fuller lips", "Definition"]),
                SalonService(name: "Carbon Peel",         icon: "cloud.fill",       duration: "60 min", price: 12000, category: "Skin",      benefits: ["Clear skin", "Oil control"]),
                SalonService(name: "Oxygen Facial",       icon: "wind",             duration: "60 min", price: 9500,  category: "Skin",      benefits: ["Plumping", "Brightening"]),
                SalonService(name: "Vampire Facial",      icon: "drop.triangle",    duration: "90 min", price: 32000, category: "Aesthetic", benefits: ["Skin rejuvenation", "Youth"]),
                SalonService(name: "PRP for Hair",        icon: "heart.text.square", duration: "60 min", price: 25000, category: "Hair",      benefits: ["Hair regrowth", "Strength"]),
                SalonService(name: "Chemical Peel",       icon: "sparkles",         duration: "45 min", price: 5000,  category: "Skin",      benefits: ["Refining", "Glowing"]),
                SalonService(name: "Swedish Massage",     icon: "figure.mind.and.body", duration: "60 min", price: 6000,  category: "Body",      benefits: ["Stress relief", "Relaxation"]),
                SalonService(name: "Gel Manicure",        icon: "hand.point.up.fill", duration: "45 min", price: 3200,  category: "Nails",     benefits: ["Shiny", "Long-lasting"]),
                SalonService(name: "Skin Tightening",     icon: "bolt.fill",        duration: "60 min", price: 18000, category: "Aesthetic", benefits: ["Firm skin", "Lifting"]),
                SalonService(name: "Eyelash Lift",        icon: "eye",              duration: "60 min", price: 4500,  category: "Eyes",      benefits: ["Curled lashes", "Natural look"])
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
                SalonService(name: "IV Drip Therapy",       icon: "ivfluid.bag",    duration: "60 min", price: 15000, category: "Wellness",  benefits: ["Energy boost", "Skin glow", "Immunity"]),
                SalonService(name: "HIFU Lifting",          icon: "waveform.path",  duration: "90 min", price: 45000, category: "Aesthetic", benefits: ["V-shape face", "Lifting"]),
                SalonService(name: "Micro-Needling",        icon: "square.grid.3x3.fill", duration: "60 min", price: 13500, category: "Skin",      benefits: ["Pore refining", "Texture"]),
                SalonService(name: "Luxury Facial",         icon: "crown.fill",     duration: "90 min", price: 12000, category: "Skin",      benefits: ["Ultimate glow", "Deep relaxation"]),
                SalonService(name: "Dandruff Treatment",    icon: "snow",           duration: "45 min", price: 3500,  category: "Hair",      benefits: ["Scalp health", "Clean hair"]),
                SalonService(name: "Foot Reflexology",      icon: "shoeprints.fill", duration: "45 min", price: 4500,  category: "Wellness",  benefits: ["Better sleep", "Detox"]),
                SalonService(name: "Detox Body Wrap",       icon: "bandage.fill",   duration: "75 min", price: 8000,  category: "Body",      benefits: ["Weight loss", "Skin toning"]),
                SalonService(name: "Chin Contouring",       icon: "faceid",         duration: "45 min", price: 28000, category: "Aesthetic", benefits: ["Sharp jawline", "Fat reduction"]),
                SalonService(name: "Acne Scar Removal",     icon: "dot.circle.and.hand.point.up.fill", duration: "60 min", price: 11000, category: "Skin",      benefits: ["Smooth skin", "Confidence"]),
                SalonService(name: "Hair Coloring",         icon: "paintbrush.pointed.fill", duration: "120 min", price: 12500, category: "Hair",      benefits: ["Vibrant color", "Shiny"]),
                SalonService(name: "Paraffin Wax",          icon: "drop.fill",      duration: "30 min", price: 3800,  category: "Nails",     benefits: ["Soft hands", "Moisture"])
            ],
            about: "Luxe Aesthetics is a boutique clinic focusing on premium aesthetic medicine and personalised beauty transformations. Every treatment is precisely crafted for your unique skin needs.",
            phone: "+94 11 456 7890",
            openHours: "Tue–Sun: 10:00 AM – 6:00 PM"
        )
    ]

    func salon(named name: String) -> Salon {
        if let matched = salons.first(where: { $0.name == name }) {
            return matched
        }

        // Fallback keeps the selected salon name instead of silently defaulting to Haley Avenue.
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
            openHours: "Mon–Sun: 9:00 AM – 7:00 PM"
        )
    }
}
