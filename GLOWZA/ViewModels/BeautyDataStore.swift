// MARK: - Beauty Data Store
// All treatment and product data lives here as hardcoded JSON!
// To add, remove, or edit items — just update the JSON strings below.
// The AI engine decodes and uses this data at runtime via JSONDecoder.
// This simulates fetching data from a backend API or database.

enum BeautyDataStore {

    // MARK: - Concern Categories
    // Every concern the ML model can classify — name must match the CoreML label exactly.
    // 'anchors' are keywords used to match user search queries!
    static let concernsJSON = """
    [
      { "name": "Acne & Breakouts",      "icon": "drop.fill",              "anchors": ["acne", "pimple", "breakout", "zit", "blackhead", "blemish", "sebum", "oily"] },
      { "name": "Dark Circles",          "icon": "eye.fill",               "anchors": ["eye", "circle", "puffy", "tired", "bag", "shadow", "undereye", "fatigue"] },
      { "name": "Hyperpigmentation",     "icon": "sun.max.fill",           "anchors": ["pigmentation", "spot", "melasma", "tan", "discoloration", "freckle", "patch", "dark"] },
      { "name": "Wrinkles & Aging",      "icon": "clock.arrow.circlepath", "anchors": ["wrinkle", "aging", "fine", "sagging", "loose", "volume", "crow", "line"] },
      { "name": "Unwanted Hair",         "icon": "scissors",               "anchors": ["hair", "removal", "shaving", "waxing", "follicle", "hirsutism", "hairy"] },
      { "name": "Dull & Uneven Tone",    "icon": "sparkles",               "anchors": ["dull", "glow", "brightening", "radiance", "fairness", "whitening", "uneven"] },
      { "name": "Dryness & Dehydration", "icon": "drop.halffull",          "anchors": ["dry", "hydration", "moisture", "flaky", "rough", "tight", "dehydrated", "parched"] },
      { "name": "Acne Scars",            "icon": "bandage.fill",           "anchors": ["scar", "mark", "crater", "pockmark", "postacne", "indented", "textured"] }
    ]
    """

    // MARK: - Treatments
    // List of professional treatments offered by salons.
    // 'concernTags' link these treatments to the concerns listed above!
    // 'semanticAnchors' help the AI find this treatment based on keywords.
    static let treatmentsJSON = """
    [
      {
        "name": "Laser Hair Removal",
        "icon": "laser.burst",
        "tagline": "Permanent hair-free smoothness",
        "description": "Advanced laser energy targets hair follicles at the root, permanently reducing unwanted hair on face, underarms, legs, arms and bikini area. Suitable for all skin tones using modern diode and Nd:YAG lasers.",
        "duration": "20 – 60 min",
        "sessions": "6 – 8 sessions",
        "priceRange": "LKR 5,000 – 15,000 / session",
        "concernTags": ["Unwanted Hair"],
        "semanticAnchors": ["hair", "follicle", "removal", "waxing", "shaving", "hirsutism", "depilation", "hairy"]
      },
      {
        "name": "Chemical Peels",
        "icon": "wand.and.sparkles",
        "tagline": "Resurface. Renew. Reveal.",
        "description": "A medical-grade chemical solution (AHA, BHA or TCA) is applied to exfoliate damaged outer layers, stimulating fresh cell renewal. Effectively treats acne, dark spots, scars and uneven texture.",
        "duration": "30 – 45 min",
        "sessions": "4 – 6 sessions",
        "priceRange": "LKR 4,000 – 12,000 / session",
        "concernTags": ["Acne & Breakouts", "Hyperpigmentation", "Acne Scars", "Dull & Uneven Tone"],
        "semanticAnchors": ["acne", "pimple", "blemish", "pigmentation", "scar", "exfoliation", "dull", "texture", "peel", "tan", "breakout"]
      },
      {
        "name": "Dermal Fillers",
        "icon": "cross.vial.fill",
        "tagline": "Restore youth. Lift & volumise.",
        "description": "Hyaluronic acid gel is precisely injected to restore lost volume, smooth deep wrinkles, define lips and lift facial contours. Results are immediate, natural-looking and last 9–18 months.",
        "duration": "30 – 60 min",
        "sessions": "1 session (touch-up every 9–18 months)",
        "priceRange": "LKR 25,000 – 65,000 / session",
        "concernTags": ["Wrinkles & Aging"],
        "semanticAnchors": ["wrinkle", "aging", "volume", "sagging", "filler", "rejuvenation", "contour", "youthful", "fine line", "loose skin"]
      },
      {
        "name": "Fairness Injections",
        "icon": "syringe.fill",
        "tagline": "Glow brighter from within.",
        "description": "High-dose Glutathione IV infusions combined with Vitamin C work systemically to inhibit melanin production, reduce hyperpigmentation and deliver a lasting brightening effect across face and body.",
        "duration": "30 min",
        "sessions": "8 – 10 sessions",
        "priceRange": "LKR 8,000 – 22,000 / session",
        "concernTags": ["Dull & Uneven Tone", "Hyperpigmentation"],
        "semanticAnchors": ["brightening", "whitening", "fairness", "melanin", "glow", "radiance", "lightening", "glutathione", "tan", "uneven tone"]
      },
      {
        "name": "Dark Circle Treatment",
        "icon": "eye.circle.fill",
        "tagline": "Brighten tired, shadowed eyes.",
        "description": "A multi-modal approach combining under-eye filler to correct hollows, PRP or mesotherapy to stimulate collagen, and topical brighteners. Significantly reduces dark shadows, puffiness and under-eye bags.",
        "duration": "30 – 45 min",
        "sessions": "3 – 5 sessions",
        "priceRange": "LKR 6,000 – 18,000 / session",
        "concernTags": ["Dark Circles"],
        "semanticAnchors": ["eye", "circle", "puffiness", "tired", "bag", "shadow", "undereye", "periorbital", "hollow", "dark under"]
      },
      {
        "name": "Microneedling",
        "icon": "waveform.path.ecg",
        "tagline": "Stimulate. Repair. Renew.",
        "description": "Controlled micro-injuries trigger the skin's natural healing cascade, boosting collagen and elastin production. Highly effective for acne scars, enlarged pores, stretch marks and overall skin rejuvenation.",
        "duration": "45 – 60 min",
        "sessions": "3 – 6 sessions",
        "priceRange": "LKR 7,000 – 20,000 / session",
        "concernTags": ["Acne Scars", "Wrinkles & Aging"],
        "semanticAnchors": ["scar", "collagen", "pore", "texture", "rejuvenation", "repair", "elastin", "crater", "mark", "indentation"]
      },
      {
        "name": "HydraFacial",
        "icon": "drop.circle.fill",
        "tagline": "Clear. Hydrate. Glow.",
        "description": "A multi-step treatment that cleanses, exfoliates, extracts impurities and infuses hyaluronic acid and antioxidants. Instantly improves hydration, brightness and texture with zero downtime.",
        "duration": "30 – 45 min",
        "sessions": "Monthly maintenance",
        "priceRange": "LKR 6,000 – 15,000 / session",
        "concernTags": ["Dull & Uneven Tone", "Dryness & Dehydration", "Acne & Breakouts"],
        "semanticAnchors": ["hydration", "moisture", "cleansing", "glow", "dryness", "dehydrated", "extraction", "brightening", "dull", "flaky"]
      },
      {
        "name": "Botox / Anti-Aging Injections",
        "icon": "cross.case.fill",
        "tagline": "Freeze lines. Look effortlessly younger.",
        "description": "Botulinum toxin is injected into specific facial muscles to temporarily relax them, smoothing dynamic wrinkles such as forehead lines, crow's feet and frown lines. Results last 3–6 months.",
        "duration": "15 – 30 min",
        "sessions": "Every 3–6 months",
        "priceRange": "LKR 15,000 – 40,000 / session",
        "concernTags": ["Wrinkles & Aging"],
        "semanticAnchors": ["botox", "wrinkle", "forehead", "crow feet", "frown line", "dynamic", "aging", "injection", "anti-aging", "freeze"]
      }
    ]
    """

    // MARK: - Products
    // List of skincare products recommended for at-home use.
    static let productsJSON = """
    [
      {
        "name": "Niacinamide 10% Serum",
        "brand": "The Ordinary",
        "category": "Serum",
        "benefit": "Minimises pores & controls sebum",
        "icon": "drop.fill",
        "concernTags": ["Acne & Breakouts", "Dull & Uneven Tone"]
      },
      {
        "name": "Salicylic Acid Cleanser",
        "brand": "CeraVe",
        "category": "Cleanser",
        "benefit": "Unclogs pores & calms breakouts",
        "icon": "bubbles.and.sparkles",
        "concernTags": ["Acne & Breakouts"]
      },
      {
        "name": "Vitamin C 15% Serum",
        "brand": "Skinceuticals",
        "category": "Serum",
        "benefit": "Brightens & fades dark spots",
        "icon": "sun.max.fill",
        "concernTags": ["Hyperpigmentation", "Dull & Uneven Tone", "Dark Circles"]
      },
      {
        "name": "Alpha Arbutin 2% Serum",
        "brand": "The Ordinary",
        "category": "Serum",
        "benefit": "Lightens pigmentation & tans",
        "icon": "sparkle",
        "concernTags": ["Hyperpigmentation", "Dull & Uneven Tone"]
      },
      {
        "name": "Retinol 0.5% Serum",
        "brand": "La Roche-Posay",
        "category": "Serum",
        "benefit": "Reduces wrinkles & resurfaces skin",
        "icon": "clock.arrow.circlepath",
        "concernTags": ["Wrinkles & Aging", "Acne Scars"]
      },
      {
        "name": "Hyaluronic Acid Serum",
        "brand": "Neutrogena",
        "category": "Serum",
        "benefit": "Deep hydration & plumping",
        "icon": "drop.halffull",
        "concernTags": ["Dryness & Dehydration", "Wrinkles & Aging"]
      },
      {
        "name": "Caffeine Eye Gel",
        "brand": "The Ordinary",
        "category": "Eye Cream",
        "benefit": "De-puffs & brightens under-eyes",
        "icon": "eye.fill",
        "concernTags": ["Dark Circles"]
      },
      {
        "name": "SPF 50+ Sunscreen",
        "brand": "Altruist",
        "category": "SPF",
        "benefit": "Prevents tan & pigmentation regression",
        "icon": "sun.and.horizon.fill",
        "concernTags": ["Hyperpigmentation", "Dull & Uneven Tone", "Acne & Breakouts"]
      },
      {
        "name": "Post-Laser Soothing Gel",
        "brand": "Bioderma",
        "category": "Gel",
        "benefit": "Calms & repairs laser-treated skin",
        "icon": "bandage.fill",
        "concernTags": ["Unwanted Hair"]
      },
      {
        "name": "Ceramide Repair Cream",
        "brand": "CeraVe",
        "category": "Moisturiser",
        "benefit": "Restores skin barrier & moisture",
        "icon": "square.stack.fill",
        "concernTags": ["Dryness & Dehydration"]
      },
      {
        "name": "Kojic Acid Brightening Soap",
        "brand": "Glowza Essentials",
        "category": "Cleanser",
        "benefit": "Daily skin brightening & even tone",
        "icon": "sparkles",
        "concernTags": ["Dull & Uneven Tone", "Hyperpigmentation"]
      },
      {
        "name": "AHA/BHA Exfoliating Toner",
        "brand": "Paula's Choice",
        "category": "Toner",
        "benefit": "Exfoliates & refines skin texture",
        "icon": "wand.and.sparkles",
        "concernTags": ["Acne & Breakouts", "Acne Scars", "Hyperpigmentation"]
      },
      {
        "name": "Azelaic Acid 10% Suspension",
        "brand": "The Ordinary",
        "category": "Serum",
        "benefit": "Fades acne marks & brightens tone",
        "icon": "circle.hexagongrid.fill",
        "concernTags": ["Acne Scars", "Acne & Breakouts", "Hyperpigmentation"]
      },
      {
        "name": "Eye Contour Brightening Cream",
        "brand": "L'Oréal Paris",
        "category": "Eye Cream",
        "benefit": "Reduces dark circles & fine lines",
        "icon": "eye.circle",
        "concernTags": ["Dark Circles", "Wrinkles & Aging"]
      }
    ]
    """
}
