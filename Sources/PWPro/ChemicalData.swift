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
    
    var color: Color {
        switch self {
        case .detergent: return Theme.sky500
        case .degreaser: return Theme.amber500
        case .acid: return Color.red
        case .disinfectant: return Theme.emerald500
        case .solvent: return Color.purple
        case .specialty: return Color.pink
        }
    }
}

struct ChemicalData {
    static let allChemicals: [Chemical] = [
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
