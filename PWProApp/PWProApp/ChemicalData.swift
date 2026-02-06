
import SwiftUI

struct Chemical: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: ChemicalType
    let description: String
    let uses: [String]
    let warnings: [String]
    let isBrandName: Bool
    let mixingStrategy: MixingStrategy?
    
    // Computed property for category (same as type for compatibility)
    var category: String {
        type.rawValue
    }
    
    init(id: UUID = UUID(), name: String, type: ChemicalType, description: String, uses: [String], warnings: [String], isBrandName: Bool, mixingStrategy: MixingStrategy?) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
        self.uses = uses
        self.warnings = warnings
        self.isBrandName = isBrandName
        self.mixingStrategy = mixingStrategy
    }
}

enum MixingStrategy: Codable {
    case targetPercentage // e.g., SH mixing (12.5% -> 1.5%)
    case dilutionRatio(defaultRatio: Double) // e.g., 4:1 (ratio = 4.0)
    case ozPerGallon(defaultOz: Double) // e.g., 1 oz per gallon
}

enum ChemicalType: String, CaseIterable, Codable {
    case detergent = "Detergent"
    case degreaser = "Degreaser"
    case acid = "Acid"
    case disinfectant = "Disinfectant"
    case solvent = "Solvent"
    case specialty = "Specialty"
    case surfaceSealer = "Surface Sealer"
    case window = "Window Cleaning"
    case graffiti = "Graffiti Removal"
    case sh = "Sodium Hypochlorite"
    case surfactant = "Surfactant"
    case other = "Other"
    
    var color: Color {
        switch self {
        case .detergent: return Theme.sky500
        case .degreaser: return Theme.amber500
        case .acid: return Color.red
        case .disinfectant: return Theme.emerald500
        case .solvent: return Color.purple
        case .specialty: return Color.pink
        case .surfaceSealer: return Color.gray
        case .window: return Color.blue
        case .graffiti: return Color.orange
        case .sh: return Color.yellow
        case .surfactant: return Color.green
        case .other: return Color.gray
        }
    }
}

struct ChemicalData {
    static var allChemicals: [Chemical] {
        defaultChemicals + importedChemicals + powerWashChemicals
    }

    static let defaultChemicals: [Chemical] = [
        // Generic Chemicals
        Chemical(
            name: "Sodium Hypochlorite (SH)",
            type: .disinfectant,
            description: "The primary active ingredient in bleach. A powerful oxidizing agent used to kill organic growth.",
            uses: ["Mold remediation", "Algae removal", "Sanitizing surfaces", "Brightening concrete"],
            warnings: ["Corrosive to metals", "Can damage pumps/seals if not rinsed", "Toxic fumes if mixed with acids", "Harmful to plants"],
            isBrandName: false,
            mixingStrategy: .targetPercentage
        ),
        Chemical(
            name: "Sodium Hydroxide (Caustic Soda)",
            type: .degreaser,
            description: "A highly alkaline chemical effective at breaking down organic materials like fats and oils.",
            uses: ["Heavy degreasing", "Hood cleaning", "Stripping paint/sealers"],
            warnings: ["Extremely corrosive involved causes severe burns", "Requires full PPE", "Can damage aluminum"],
            isBrandName: false,
            mixingStrategy: .dilutionRatio(defaultRatio: 10.0) // 10:1 default
        ),
        Chemical(
            name: "Oxalic Acid",
            type: .acid,
            description: "An organic acid excellent for rust removal and wood brightening.",
            uses: ["Rust removal", "Wood restoration/brightening", "Removing tannin stains"],
            warnings: ["Toxic if ingested", "Can cause kidney damage", "Wear respirator and gloves"],
            isBrandName: false,
            mixingStrategy: .dilutionRatio(defaultRatio: 12.0) // Often ~8-16 oz per gallon (powder), let's approx ratio
        ),
        Chemical(
            name: "Muriatic Acid",
            type: .acid,
            description: "Industrial strength hydrochloric acid.",
            uses: ["Etching concrete", "Removing heavy efflorescence", "Cleaning mortar smears"],
            warnings: ["Highly dangerous fumes", "Burns skin instantly", "Damages most metals"],
            isBrandName: false,
            mixingStrategy: .dilutionRatio(defaultRatio: 4.0) // 4:1 common for masonry
        ),
        
        // Brand Name Chemicals
        Chemical(
            name: "F9 BARC",
            type: .acid,
            description: "World's best rust remover. Battery Acid Restoration Cleaner.",
            uses: ["Rust removal", "Fertilizer stain removal", "Orange battery acid burn removal"],
            warnings: ["Professional use only", "Do not let dry on glass"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 2.0) // 1:2 or straight
        ),
        Chemical(
            name: "Gold Assassin",
            type: .degreaser,
            description: "Caustic degreaser by CWB Solutions.",
            uses: ["Heavy equipment cleaning", "Gas station pads", "Oil stain removal"],
            warnings: ["High pH", "Caustic burns possible"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 4.0) // 4:1 for general degreasing
        ),
        Chemical(
            name: "Cleansol BC",
            type: .detergent,
            description: "Brushless oxidation remover by Ecoim.",
            uses: ["Removing oxidation from vinyl siding", "Gutter brightening", "General house wash"],
            warnings: ["Do not allow to dry on glass", "Check compatibility"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 1.0) // 1:1 common for oxidation? or 4:1
        ),
        Chemical(
            name: "EBC (Enviro Bio Cleaner)",
            type: .degreaser,
            description: "Water-based, biodegradable multi-purpose cleaner.",
            uses: ["General degreasing", "Drive-thrus", "Building exteriors"],
            warnings: ["Safe but concentrated", "Follow dilution ratios"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 10.0) // 10:1 maintenance
        ),
        Chemical(
            name: "Agent Green",
            type: .specialty,
            description: "Chlorine surfactant and enhancer by Agent Clean.",
            uses: ["Roof washing", "House washing", "Helps bleach cling and penetrate"],
            warnings: ["Mix carefully with SH"],
            isBrandName: true,
            mixingStrategy: .ozPerGallon(defaultOz: 1.0) // Additive
        ),
        Chemical(
            name: "F9 Double Eagle",
            type: .degreaser,
            description: "Cleaner, degreaser, and neutralizer.",
            uses: ["Food grease", "Tire marks", "General flatwork"],
            warnings: ["Concentrated", "Professional use only"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 4.0)
        ),
        
        // Southeast Softwash Products
        Chemical(
            name: "Southern Swag (Fresh Rain)",
            type: .detergent,
            description: "Premium surfactant by Southeast Softwash. High foaming with a fresh rain scent.",
            uses: ["Roof washing", "House washing", "Bleach additive"],
            warnings: ["Mix with SH", "Do not let dry on windows"],
            isBrandName: true,
            mixingStrategy: .ozPerGallon(defaultOz: 1.0) // 1 oz/gal SH
        ),
        Chemical(
            name: "Southern Twang (Apple)",
            type: .detergent,
            description: "Green apple scented surfactant. High foam and cling.",
            uses: ["Roof washing", "House washing", "Masks bleach scent"],
            warnings: ["Mix with SH"],
            isBrandName: true,
            mixingStrategy: .ozPerGallon(defaultOz: 1.0)
        ),
        Chemical(
            name: "Southern Slang (Cherry)",
            type: .detergent,
            description: "Cherry scented surfactant. Thick foam for vertical surfaces.",
            uses: ["Roof washing", "House washing", "Scent masking"],
            warnings: ["Mix with SH"],
            isBrandName: true,
            mixingStrategy: .ozPerGallon(defaultOz: 1.0)
        ),
        Chemical(
            name: "Southern Drawl (Citrus)",
            type: .detergent,
            description: "Citrus scented surfactant by Southeast Softwash.",
            uses: ["Roof washing", "House washing", "General cleaning"],
            warnings: ["Mix with SH"],
            isBrandName: true,
            mixingStrategy: .ozPerGallon(defaultOz: 1.0)
        ),
        Chemical(
            name: "Ox-Knox",
            type: .acid,
            description: "Brushless oxidation remover. Removes chalky residue from vinyl siding.",
            uses: ["Vinyl siding oxidation", "Gutter tiger striping", "Metal brightening"],
            warnings: ["Do not let dry on glass", "Test small area first"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 1.0) // Usually stronger mix
        ),
        Chemical(
            name: "Concrete Crew",
            type: .degreaser,
            description: "Heavy duty concrete cleaner and degreaser.",
            uses: ["Driveways", "Gas stations", "Oil stains"],
            warnings: ["Alkaline", "PPE Required"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 4.0)
        ),
        Chemical(
            name: "Plant Protect",
            type: .specialty,
            description: "Bleach neutralizer and soil conditioner.",
            uses: ["Protecting landscaping", "Neutralizing bleach runoff", "Equipment rinsing"],
            warnings: ["Use after washing"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 16.0) // Rinse aid
        ),
        Chemical(
            name: "Mud May-Day",
            type: .acid,
            description: "Red clay and mineral stain remover.",
            uses: ["Red clay stains", "Mineral deposits", "Brick cleaning"],
            warnings: ["Corrosive", "Do not use on polished stone"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 4.0)
        ),
        Chemical(
            name: "Gutter Guard",
            type: .detergent,
            description: "Concentrated gutter cleaning chemical.",
            uses: ["Gutter cleaning", "Black streak removal"],
            warnings: ["Wear gloves"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 2.0) // 1:2 or 1:4
        ),
        Chemical(
            name: "Glass Glow",
            type: .specialty,
            description: "Window and glass cleaner additive.",
            uses: ["Window cleaning", "Shiny surfaces"],
            warnings: ["Streak free if used correctly"],
            isBrandName: true,
            mixingStrategy: .ozPerGallon(defaultOz: 2.0)
        ),
        Chemical(
            name: "Dynamite Degreaser",
            type: .degreaser,
            description: "Powerful industrial degreaser.",
            uses: ["Heavy equipment", "Grease pads", "Dumpster pads"],
            warnings: ["Caustic", "Burns skin"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 4.0)
        ),
        Chemical(
            name: "Super Seal",
            type: .specialty,
            description: "Water-based Siloxane concrete sealer.",
            uses: ["Sealing concrete", "Waterproofing masonry"],
            warnings: ["Apply to clean dry surface"],
            isBrandName: true,
            mixingStrategy: nil // RTU often? Or user manual required. Omit from calculator.
        ),
        Chemical(
            name: "Monu-mental",
            type: .detergent,
            description: "Eco-friendly exterior cleaner for delicate surfaces.",
            uses: ["Historic markers", "Headstones", "Delicate masonry"],
            warnings: ["Biological cleaner", "Slow acting"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 1.0) // Often 1:1 or 1:4
        ),
        
        // Softwash Depot Products
        Chemical(
            name: "SWD Apple Surfactant",
            type: .detergent,
            description: "Apple scented surfactant with track marker. High foaming.",
            uses: ["Roof washing", "House washing", "Marking treated areas"],
            warnings: ["Mix with SH", "Rinses clean"],
            isBrandName: true,
            mixingStrategy: .ozPerGallon(defaultOz: 1.0)
        ),
        Chemical(
            name: "SWD Cherry Scented",
            type: .detergent,
            description: "Cherry scented surfactant for soft washing.",
            uses: ["Roof washing", "House washing", "Scent masking"],
            warnings: ["Mix with SH"],
            isBrandName: true,
            mixingStrategy: .ozPerGallon(defaultOz: 1.0)
        ),
        Chemical(
            name: "SWD Lemon Scented",
            type: .detergent,
            description: "Lemon scented surfactant for soft washing.",
            uses: ["Roof washing", "House washing", "General cleaning"],
            warnings: ["Mix with SH"],
            isBrandName: true,
            mixingStrategy: .ozPerGallon(defaultOz: 1.0)
        ),
        Chemical(
            name: "SWD Orange Grove",
            type: .detergent,
            description: "Orange scented surfactant.",
            uses: ["Roof washing", "House washing", "Citrus scent"],
            warnings: ["Mix with SH"],
            isBrandName: true,
            mixingStrategy: .ozPerGallon(defaultOz: 1.0)
        ),
        Chemical(
            name: "Mango Mauler",
            type: .detergent,
            description: "Mango scented soft wash surfactant pods.",
            uses: ["Roof washing", "House washing", "Easy dosing"],
            warnings: ["Mix with SH"],
            isBrandName: true,
            mixingStrategy: nil // Pods are unit based, not really calculator friendly in this context
        ),
        Chemical(
            name: "Bye Bye Bleach",
            type: .specialty,
            description: "Bleach neutralizer by Softwash Depot.",
            uses: ["Neutralizing bleach", "Protecting plants", "Rinsing equipment"],
            warnings: ["Use after washing"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 4.0)
        ),
        Chemical(
            name: "NeutraPod",
            type: .specialty,
            description: "Powdered bleach neutralizer in pods.",
            uses: ["Neutralizing bleach", "Plant protection", "Gutter neutralization"],
            warnings: ["Dissolve in water"],
            isBrandName: true,
            mixingStrategy: nil // Pods
        ),
        Chemical(
            name: "The D-Greaser",
            type: .degreaser,
            description: "Professional concrete degreaser.",
            uses: ["Oil stains", "Grease pads", "Driveways"],
            warnings: ["Alkaline", "PPE required"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 8.0)
        ),
        Chemical(
            name: "Un Rustable",
            type: .acid,
            description: "Rust remover for various surfaces.",
            uses: ["Rust stains", "Irrigation stains"],
            warnings: ["Corrosive", "Acid based"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 1.0)
        ),
        Chemical(
            name: "EFF No",
            type: .acid,
            description: "Efflorescence and calcium remover.",
            uses: ["Efflorescence", "Calcium deposits", "Hard water stains"],
            warnings: ["Acid based", "Do not use on polished stone"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 4.0)
        ),
        Chemical(
            name: "Gutter Glow",
            type: .detergent,
            description: "Premium gutter cleaner and oxidation remover.",
            uses: ["Gutter cleaning", "Removing oxidation stripes"],
            warnings: ["Wear gloves"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 2.0)
        ),
        Chemical(
            name: "SWD DETOX",
            type: .acid,
            description: "Brushless oxidation remover.",
            uses: ["Vinyl siding oxidation", "Metal brightening"],
            warnings: ["Do not let dry on glass"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 1.0)
        ),
        Chemical(
            name: "Trident Hurricane Cat 5",
            type: .specialty,
            description: "Professional sealer kit.",
            uses: ["Sealing pavers", "Concrete protection"],
            warnings: ["Follow mix instructions"],
            isBrandName: true,
            mixingStrategy: nil // Complex kit
        ),
        Chemical(
            name: "Trident White Water",
            type: .acid,
            description: "Powerful efflorescence, salt, and mineral stain remover.",
            uses: ["Heavy efflorescence", "Salt deposits", "Mineral stains"],
            warnings: ["Strong acid", "Professional use only"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 4.0)
        ),
        Chemical(
            name: "Citra-Shield",
            type: .detergent,
            description: "Industrial cleaner concentrate.",
            uses: ["General cleaning", "Biological growth"],
            warnings: ["Concentrated"],
            isBrandName: true,
            mixingStrategy: .dilutionRatio(defaultRatio: 5.0)
        ),
        Chemical(
            name: "Deco Silicast BES",
            type: .specialty,
            description: "Concrete sealer.",
            uses: ["Enhanced look sealer", "Paver sealing"],
            warnings: ["Apply to clean surface"],
            isBrandName: true,
            mixingStrategy: nil // Sealer
        )
    ]
}

// MARK: - Imported Chemicals
extension ChemicalData {
    static let importedChemicals: [Chemical] = [
        Chemical(
            id: UUID(),
            name: "Pro 80 New Masonry Cleaner – Professional Acid-Based Cleaner for Brick, Block & Concrete",
            type: .acid,
            description: "Pro 80 New Masonry Cleaner is a professional-grade acid-based masonry cleaner formulated specifically for cleaning newly installed masonry surfaces. It is designed to safely and effectively remove mor...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Break Down – Biodegradable Concrete Remover | Safe Cement & Mortar Dissolver",
            type: .other,
            description: "Break Down – Biodegradable Concrete Remover is a professional-grade solution designed to safely dissolve concrete, cement, mortar, grout, and lime-based buildup without damaging surrounding surfaces. ...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Dirt Vanish Off-Road Armor – Shine & Protection for Hardworking Machines | 32oz Bottle",
            type: .detergent,
            description: "When your equipment takes a beating, Dirt Vanish’s Knockout hits back harder. Its high-foaming, cherry-scented formula lifts away buildup without harsh scrubbing, saving time while protecting paint, p...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Dirt Vanish Knockout – High-Foaming Off-Road Cleaner | 1 Gallon Bottle",
            type: .detergent,
            description: "When your equipment takes a beating,Dirt Vanish’s Knockout hits back harder. Its high-foaming, cherry-scented formula lifts away buildup without harsh scrubbing, saving time while protecting paint, pl...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Dirt Vanish Knockout – High-Foaming Off-Road Cleaner | 32oz Bottle",
            type: .detergent,
            description: "Off-Road Armor by Dirt Vanish is the ultimate water based finishing spray for your SxS, atv, skid steer, mega truck, or heavy equipment. Applied with a towel, spray gun, or air gun, it delivers a deep...",
            uses: ["Refer to product label for specific uses"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Dirt Vanish Off-Road Armor – Shine & Protection for Hardworking Machines | 1 Gallon",
            type: .detergent,
            description: "Off-Road Armor by Dirt Vanish is the ultimate water based finishing spray for your SxS, atv, skid steer, mega truck, or heavy equipment. Applied with a towel, spray gun, or air gun, it delivers a deep...",
            uses: ["Refer to product label for specific uses"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Dirt Vanish Off-Road Armor MAX – Shine & Protection for Hardworking Machines | 32oz Bottle",
            type: .detergent,
            description: "Off-Road Armor MAX by Dirt Vanish is the ultimate water based finishing spray for your SxS, ATV, skid steer, mega truck, or heavy equipment. Applied with a towel, spray gun, or air gun, it delivers a ...",
            uses: ["Refer to product label for specific uses"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Dirt Vanish Off-Road Armor MAX – Shine & Protection for Hardworking Machines | 1 Gallon",
            type: .detergent,
            description: "Off-Road Armor MAX by Dirt Vanish is the ultimate water based finishing spray for your SxS, ATV, skid steer, mega truck, or heavy equipment. Applied with a towel, spray gun, or air gun, it delivers a ...",
            uses: ["Refer to product label for specific uses"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Fine Grade Detailing Clay Bar – Red – Pack of 2",
            type: .detergent,
            description: "The Maxshine Detailing Clay Bar – Red (Fine Grade) is designed for gentle paint decontamination on lightly to moderately contaminated surfaces. Ideal for maintenance detailing, this fine-grade clay sa...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Heavy Grade Detailing Clay Bar – Purple – Pack of 3",
            type: .detergent,
            description: "The Maxshine Detailing Clay Bar – Purple (Heavy Grade) is engineered for aggressive paint decontamination on heavily contaminated surfaces. Designed to remove stubborn bonded contaminants such as over...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Wheel & Tire Cleaner – Heavy-Duty Brake Dust & Tire Cleaner – 1 Gallon",
            type: .detergent,
            description: "The Maxshine Wheel &amp; Tire Cleaner is a powerful, professional-grade formula designed to break down brake dust, road grime, grease, and tire blooming quickly and effectively. Engineered for use on ...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Royal Magic Waterless Wash & Wax – High-Gloss No-Rinse Formula – 1 Gallon",
            type: .detergent,
            description: "The Maxshine Royal Magic Waterless Wash &amp; Wax is a premium no-rinse cleaning and protection solution designed to safely clean and enhance automotive paint without the use of water. Its advanced fo...",
            uses: ["Refer to product label for specific uses"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Refresh Car Wash Shampoo – High-Lubricity Wash Soap – 1 Gallon",
            type: .detergent,
            description: "The Maxshine Refresh Car Wash Shampoo is a premium maintenance wash soap formulated to safely and effectively clean automotive surfaces while enhancing gloss and preserving existing protection. Its hi...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Mist Enhance & Protect Cleaner Spray Sealant – 1 Gallon",
            type: .detergent,
            description: "The Maxshine Mist Enhance &amp; Protect Cleaner Spray Sealant is a versatile, professional-grade solution designed to clean, enhance gloss, and protect automotive surfaces in one easy step. This advan...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Ultra Foaming Wash – High-Foam Car Wash Soap – 1 Gallon",
            type: .detergent,
            description: "The Maxshine Ultra Foaming Wash is a premium car wash soap engineered to produce thick, clinging foam that safely lifts dirt and road grime from vehicle surfaces. Designed for use with foam cannons, f...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Leather Ceramic Coating – Interior Leather Protection – 60ml Bottle Only",
            type: .detergent,
            description: "The Maxshine Leather Ceramic Coating is a professional-grade interior protection solution engineered to protect leather surfaces from wear, staining, UV damage, and discoloration. This advanced cerami...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Grab N' Go Car Care Kit – Paint Correct | Complete Paint Correction Kit",
            type: .detergent,
            description: "The Grab N' Go Car Care Kit – Paint Correct is a complete, ready-to-use solution designed to restore gloss and improve the appearance of automotive paint by addressing light to moderate defects. This ...",
            uses: ["Refer to product label for specific uses"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Graphene Detail Spray – High-Gloss Ceramic Boost – 16oz",
            type: .detergent,
            description: "The Maxshine Graphene Detail Spray is a premium maintenance product designed to enhance gloss, slickness, and protection on automotive paint surfaces. Infused with graphene-enhanced technology, this a...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Glass Cleaner – Streak-Free Automotive Window Cleaner – 1 Gallon",
            type: .detergent,
            description: "The Maxshine Glass Cleaner is a professional-grade formula designed to deliver crystal-clear, streak-free results on automotive glass and mirrors. Engineered to cut through fingerprints, road film, ha...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Graphene-Max Ceramic Coating – Advanced Paint Protection – 60ml Bottle Only",
            type: .detergent,
            description: "The Maxshine Graphene-Max Ceramic Coating is a professional-grade paint protection solution engineered with advanced graphene-infused ceramic technology for maximum durability, gloss, and hydrophobic ...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Graphene Ceramic Coating – Professional Paint Protection – 50ml Bottle Only",
            type: .detergent,
            description: "The Maxshine Graphene Ceramic Coating is a professional-grade paint protection solution formulated with advanced graphene-enhanced ceramic technology. Designed for experienced detailers and coating pr...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Graphene-Max Ceramic Coating Kit – Advanced Paint Protection – 60ml",
            type: .detergent,
            description: "The Maxshine Graphene-Max Ceramic Coating Kit is a professional-grade paint protection system engineered with advanced graphene-infused ceramic technology. This high-performance coating delivers excep...",
            uses: ["Refer to product label for specific uses"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Carnauba Paste Wax – Deep Gloss Paint Protection – 8oz",
            type: .detergent,
            description: "The Maxshine Carnauba Paste Wax is a premium paint protection product formulated with high-quality carnauba wax to deliver deep gloss, rich color enhancement, and durable surface protection. Designed ...",
            uses: ["Refer to product label for specific uses"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Clay Lube Car Wash Cleaner – Paint Decontamination Lubricant – 1 Gallon",
            type: .detergent,
            description: "The Maxshine Clay Lube Car Wash Cleaner is a high-lubricity formula designed to safely and effectively support paint decontamination using clay bars, clay mitts, or synthetic clay towels. This premium...",
            uses: ["Refer to product label for specific uses"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine All in One Polish & Protect – High-Gloss Finish & Sealing Wax – 32oz",
            type: .detergent,
            description: "The Maxshine All in One Polish &amp; Protect is a professional-grade solution designed to clean, polish, and protect automotive paint in a single step. This advanced formula removes light oxidation, s...",
            uses: ["Refer to product label for specific uses"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine AIO Conditioner – Interior Protectant & Dressing – 16oz",
            type: .detergent,
            description: "The Maxshine AIO Conditioner is a premium interior protectant designed to clean, condition, and protect automotive surfaces in one easy step. This advanced formula restores a rich, factory-fresh appea...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine All in One Cleaner – Citrus Cleaning Power Active Degreaser – 1 Gallon",
            type: .degreaser,
            description: "The Maxshine All in One Cleaner – Citrus Cleaning Power Active Degreaser is a powerful, versatile cleaning solution designed to tackle tough grime while remaining safe for a wide range of automotive s...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Titan Stack Kit - Steel Silver Powder Coat",
            type: .other,
            description: "Titan Stack Kit",
            uses: ["Refer to product label for specific uses"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Seal 'N Lock Super Wet Look – 5 Gallon Pail | High-Gloss Paver Sealer (72 Buckets)",
            type: .specialty,
            description: "The Seal 'N Lock Super Wet Look (5 Gallon) is a professional-grade, high-gloss paver sealer ...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Whisper Wash Classic Extreme 19\" Surface Cleaner – XForce Aluminum 4-Tip",
            type: .other,
            description: "The Whisper Wash Classic Extreme 19\" Surface Cleaner is engineered for contractors who demand higher output...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Mesh Scrub Headcover for Premium Detailing Extension Microfiber IncrediStick",
            type: .other,
            description: "The Maxshine Mesh Scrub Headcover...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Bio Bomber Safe Exterior Cleaner and Protectant | Multi-Surface Eco-Friendly Wash Solution",
            type: .other,
            description: "Bio Bomber Safe Exterior Cleaner and Protectant is a powerful yet environmentally responsible cleaning formula...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        ),
        Chemical(
            id: UUID(),
            name: "Maxshine Silicone Water Blade – Transparent | Flexible Drying Squeegee for Auto Detailing",
            type: .other,
            description: "The Maxshine Silicone Water Blade...",
            uses: ["General surface cleaning"],
            warnings: ["Refer to product label for safety warnings"],
            isBrandName: true,
            mixingStrategy: nil // Manual entry required
        )
    ]
}

// MARK: - PowerWash.com Chemicals
extension ChemicalData {
    static let powerWashChemicals: [Chemical] = [
        Chemical(
            id: UUID(),
            name: "6 OZ. Aerosol Corrosion X",
            type: .other,
            description: "6 OZ. Aerosol Corrosion X",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "FACILITEC FS BOOSTER 55 GAL",
            type: .other,
            description: "FACILITEC FS BOOSTER 55 GAL",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Bulk Bleach - 1 Gallon",
            type: .sh,
            description: "",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Max Quat 10% Sanitizer - Pressure Washing Chemical Disinfectant",
            type: .sh,
            description: "Max-Quat 10% Sanitizer: Superior Sanitization for Every Industry...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Delux Windows Plus Glass Cleaner (1 Gallon)",
            type: .window,
            description: "Discover the Sparkle with Windows Plus!...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Super StripaCast: Coating Remover",
            type: .other,
            description: "Easily Strip Away Old Sealers with STRIPACAST!...",
            uses: ["General purpose", "Concrete cleaning"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Clearly Clean Xtreme Concrete Cleaner",
            type: .other,
            description: "A crystal clear, heavy-duty highly concentrated concrete cleaner...",
            uses: ["General purpose", "Concrete cleaning"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "World's Best Graffiti Feltpen Fadeout - 1 gallon",
            type: .graffiti,
            description: "Feltpen Fadeout is designed for the final removal of shadows...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "NeutraPods®",
            type: .other,
            description: "Say goodbye to the hassle of protecting your delicate plants...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Heavy Duty Industrial Degreaser 1430 - 16 oz DNB PowerHouse Cleaning Solution",
            type: .degreaser,
            description: "DNB PowerHouse Degreaser 1430 is a heavy-duty industrial cleaner...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "EFF-OFF Calcium & Efflorescence Remover for Pressure Washing",
            type: .sh,
            description: "Remove calcium and efflorescence from hard surfaces...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Wood Defender",
            type: .other,
            description: "Wood Defender is the intelligent choice...",
            uses: ["General purpose", "Wood restoration"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Hurricane CAT 5",
            type: .other,
            description: "Hurricane CAT 5 is the ultimate in 2-part sealers...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Barrier",
            type: .other,
            description: "Barrier – Invisible Protection for Stone, Concrete, and Pavers...",
            uses: ["General purpose", "Concrete cleaning"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "DELUX Apple Blast Soft Wash Detergent – Apple Scent & Bleach Masking Additive",
            type: .sh,
            description: "Apple Blast Scent Soft Wash Detergent is a super foaming surfactant...",
            uses: ["General purpose", "Asphalt shingles"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Canvas & Vinyl Super Awning Cleaner (1 Gallon)",
            type: .other,
            description: "Deep clean even the heavily soiled awnings...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "World's Best Graffiti Safewipes 6 Pack",
            type: .graffiti,
            description: "Graffiti Safewipes will remove: Spray Can Paints, over-spray...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Delux Defender PM for Bleach Neutralizer for Professionals",
            type: .sh,
            description: "Delux Defender – Formerly Known as PM Bleach Neutralizer...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Rust Remover Plus Pressure Washing Chemical: Achieve Fast, Professional Results!",
            type: .sh,
            description: "Introducing Rust Remover Plus™ Pressure Washing Chemical...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Fresh Wash Floral  - Soft Wash Detergent",
            type: .sh,
            description: "Transform your cleaning game with the ultimate soft wash detergent...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Delux Fresh Wash Lemon Scent - Soft Wash Detergent",
            type: .sh,
            description: "Delux Fresh Wash Lemon: Elevate Your Cleaning Game!...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "DELUX Fresh Wash Apple Blossom - Pressure Washer House & Roof Wash Detergent",
            type: .sh,
            description: "DELUX Fresh Wash Apple Blossom is the ultimate solution...",
            uses: ["General purpose", "Asphalt shingles"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "WOW! Stainless Steel Polish (5 Gallon Bucket)",
            type: .sh,
            description: "WOW! Stainless Steel Cleaner was developed to clean the toughest surfaces...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "A-400 Hydrofluoric Acid Aluminum Brightener",
            type: .acid,
            description: "A-400 Hydroflouric Acid Aluminum Brightener is a heavy-duty...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Eradicrete Concrete Remover 5 Gallons",
            type: .other,
            description: "Use eradicrete to cut through concrete and calcium deposits...",
            uses: ["General purpose", "Concrete cleaning"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "DNB Powerhouse Degreaser -5 Gallons Concrete Pressure Washer Cleaner for Powerful Cleaning",
            type: .sh,
            description: "The DNB Powerhouse Degreaser is a professional-grade concrete cleaner...",
            uses: ["General purpose", "Concrete cleaning"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Crystal Clear Restore OA-50  Restore New look to Wood, Concrete, Cool Deck and more",
            type: .other,
            description: "Revitalize Your World with Crystal Clear Restore!...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "EBC Enviro Bio Cleaner - General Purpose Pressure Washing Chemical for Cleaning and Sanitizing",
            type: .sh,
            description: "Introducing Enviro Bio Cleaner (EBC) - Your Ultimate Heavy-Duty Cleaning Solution!...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "DELUX® Blue Professional Tire Shine",
            type: .sh,
            description: "Keep that like-new finish on tires, rubber hoses...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "R-111 Classic Brown for Car Pressure Washing",
            type: .sh,
            description: "Increase cling time and use less detergent...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Pink Lightning Aluminum Brightener 3X",
            type: .acid,
            description: "Looking to give your fleet, trucks, boats, or trailers a stunning makeover?...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Fresh Wash Pine Sap-It - House & Roof Soft Wash Detergent Additive",
            type: .sh,
            description: "Introducing Fresh Wash Pine (formally known as Sap-IT)...",
            uses: ["General purpose", "Asphalt shingles"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "A-402 Citrix Aluminum Brightener",
            type: .acid,
            description: "A-402 Citrix Aluminum Brightener is a revolutionary blend...",
            uses: ["General purpose", "Concrete cleaning"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        ),
        Chemical(
            id: UUID(),
            name: "Pink Thunder Vehicle Soap",
            type: .surfactant,
            description: "Delux Pink Thunder™ Vehicle Wash Soap—the go-to solution for pros and DIYers...",
            uses: ["General purpose"],
            warnings: [],
            isBrandName: true,
            mixingStrategy: nil
        )
    ]
}
