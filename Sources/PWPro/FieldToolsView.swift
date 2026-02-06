import SwiftUI

struct FieldToolsView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.slate900.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Segmented Control
                    HStack(spacing: 0) {
                        TabButton(title: "Calculator", isSelected: selectedTab == 0) { selectedTab = 0 }
                        TabButton(title: "Chemicals", isSelected: selectedTab == 1) { selectedTab = 1 }
                        TabButton(title: "AR Measure", isSelected: selectedTab == 2) { selectedTab = 2 }
                        TabButton(title: "Before/After", isSelected: selectedTab == 3) { selectedTab = 3 }
                    }
                    .padding()
                    .background(Theme.slate800.opacity(0.5))
                    
                    if selectedTab == 0 {
                        MixingCalculatorView()
                    } else if selectedTab == 1 {
                        ChemicalsView()
                    } else if selectedTab == 2 {
                        SmartCameraView(estimatedSqFt: $estimatedArea, identifiedSurface: $identifiedSurfaceType)
                    } else {
                        BeforeAfterCameraView()
                    }
                }
            }
            .navigationTitle("Field Tools")
        }
    }
    
    @State private var estimatedArea: Double = 0
    @State private var identifiedSurfaceType: SurfaceType? = nil
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.labelFont)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Theme.sky500.opacity(0.2) : Color.clear)
                .foregroundColor(isSelected ? Theme.sky500 : Theme.slate400)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(isSelected ? Theme.sky500 : Color.clear),
                    alignment: .bottom
                )
        }
        .buttonStyle(.plain)
    }
}

enum MixingMode: String, CaseIterable {
    case batch = "Batch Mix"
    case downstream = "Downstream"
    case manifold = "Manifold"
}

struct MixingCalculatorView: View {
    // Filter out chemicals that don't have a mixing strategy
    var mixableChemicals: [Chemical] {
        ChemicalData.allChemicals.filter { $0.mixingStrategy != nil }
    }
    
    @State private var selectedChemical: Chemical?
    @State private var mixingMode: MixingMode = .batch
    
    // Inputs
    @State private var tankSize: Double = 50 // Gallons
    @State private var injectorRatio: Double = 10 // 10:1
    
    // Variable Inputs (depending on strategy)
    @State private var targetPercentage: Double = 1.5 // % (SH)
    @State private var sourceSH: Double = 12.5 // % (Generic SH)
    @State private var dilutionRatio: Double = 4.0 // X:1 (Degreasers)
    @State private var ozPerGallon: Double = 1.0 // oz/gal (Surfactants)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Mode Selection
                Picker("Mode", selection: $mixingMode) {
                    ForEach(MixingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Chemical Selector
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CHEMICAL AGENT")
                            .font(Theme.labelFont)
                            .foregroundColor(Theme.slate400)
                        
                        Menu {
                            ForEach(mixableChemicals) { chem in
                                Button(action: { 
                                    selectedChemical = chem
                                    updateDefaults(for: chem)
                                }) {
                                    HStack {
                                        Text(chem.name)
                                        if chem.isBrandName { Spacer(); Text("Brand") }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedChemical?.name ?? "Select Chemical")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .foregroundColor(Theme.sky500)
                            }
                            .padding()
                            .background(Theme.slate800)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.slate700, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    if selectedChemical == nil, let first = mixableChemicals.first {
                        selectedChemical = first
                        updateDefaults(for: first)
                    }
                }
                
                // Dynamic Inputs
                if let chemical = selectedChemical, let strategy = chemical.mixingStrategy {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("SETTINGS")
                                .font(Theme.labelFont)
                                .foregroundColor(Theme.slate400)
                            
                            // 1. GLOBAL SETTINGS (Tank / Injector) based on Mode
                            if mixingMode == .batch {
                                InputSlider(
                                    label: "Tank Size",
                                    value: $tankSize,
                                    range: 5...500,
                                    step: 5,
                                    displayValue: "\(Int(tankSize)) gal",
                                    color: Theme.emerald500
                                )
                            } else if mixingMode == .downstream {
                                InputSlider(
                                    label: "Injector Ratio",
                                    value: $injectorRatio,
                                    range: 4...20,
                                    step: 1,
                                    displayValue: "1:\(Int(injectorRatio))",
                                    color: Theme.amber500
                                )
                            }
                            
                            Divider().background(Theme.slate700)
                            
                            // 2. CHEMICAL SPECIFIC SETTINGS
                            switch strategy {
                            case .targetPercentage:
                                InputSlider(
                                    label: "Target Strength",
                                    value: $targetPercentage,
                                    range: 0.5...6.0,
                                    step: 0.1,
                                    displayValue: String(format: "%.1f%%", targetPercentage),
                                    color: Theme.sky500
                                )
                                VStack(alignment: .leading) {
                                    Text("Source SH Strength: \(String(format: "%.1f", sourceSH))%")
                                        .font(.caption)
                                        .foregroundColor(Theme.slate400)
                                    Slider(value: $sourceSH, in: 10...15, step: 0.5)
                                        .tint(Theme.slate400)
                                }
                                
                            case .dilutionRatio(_):
                                InputSlider(
                                    label: "Dilution Ratio (Water:Chem)",
                                    value: $dilutionRatio,
                                    range: 1...20,
                                    step: 1,
                                    displayValue: "\(Int(dilutionRatio)):1",
                                    color: Theme.purple500
                                )
                                
                            case .ozPerGallon(_):
                                InputSlider(
                                    label: "Ounces per Gallon",
                                    value: $ozPerGallon,
                                    range: 0.5...10,
                                    step: 0.5,
                                    displayValue: String(format: "%.1f oz", ozPerGallon),
                                    color: Theme.pink500
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Results
                    ResultsView(
                        mode: mixingMode,
                        strategy: strategy,
                        tankSize: tankSize,
                        injectorRatio: injectorRatio,
                        targetPercent: targetPercentage,
                        sourceSH: sourceSH,
                        dilutionRatio: dilutionRatio,
                        ozPerGal: ozPerGallon
                    )
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top)
        }
    }
    
    private func updateDefaults(for chemical: Chemical) {
        switch chemical.mixingStrategy {
        case .dilutionRatio(let defaultRatio):
            self.dilutionRatio = defaultRatio
        case .ozPerGallon(let defaultOz):
            self.ozPerGallon = defaultOz
        case .targetPercentage:
            self.targetPercentage = 1.5 // Default SH clean
        default: break
        }
    }
}

struct InputSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let displayValue: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                    .foregroundColor(Theme.slate50)
                Spacer()
                Text(displayValue)
                    .font(Theme.headingFont)
                    .foregroundColor(color)
            }
            Slider(value: $value, in: range, step: step)
                .tint(color)
        }
    }
}

struct ResultsView: View {
    let mode: MixingMode
    let strategy: MixingStrategy
    
    // Inputs
    let tankSize: Double
    let injectorRatio: Double
    let targetPercent: Double
    let sourceSH: Double
    let dilutionRatio: Double
    let ozPerGal: Double
    
    var body: some View {
        VStack(spacing: 16) {
            switch mode {
            case .batch:
                batchCalculation
            case .downstream:
                downstreamCalculation
            case .manifold:
                manifoldCalculation
            }
        }
    }
    
    // MARK: - Batch Calculations
    @ViewBuilder
    var batchCalculation: some View {
        switch strategy {
        case .targetPercentage:
            // SH Formula: (Target / Source) * Tank
            let shNeeded = (targetPercent / sourceSH) * tankSize
            let waterNeeded = tankSize - shNeeded
            
            HStack(spacing: 12) {
                ResultCard(title: "SH Needed", value: fmt(shNeeded), unit: "GAL", color: Theme.sky500)
                ResultCard(title: "Water Needed", value: fmt(waterNeeded), unit: "GAL", color: Theme.emerald500)
            }
            
        case .dilutionRatio:
            // Ratio 4:1 means 5 parts total. Chem = 1/5.
            let totalParts = dilutionRatio + 1
            let chemNeeded = tankSize / totalParts
            let waterNeeded = tankSize - chemNeeded
            
            HStack(spacing: 12) {
                ResultCard(title: "Chem Needed", value: fmt(chemNeeded), unit: "GAL", color: Theme.purple500)
                ResultCard(title: "Water Needed", value: fmt(waterNeeded), unit: "GAL", color: Theme.emerald500)
            }
            
        case .ozPerGallon:
            // Simple: Tank * Oz
            let totalOz = tankSize * ozPerGal
            
            ResultCard(title: "Chem Needed", value: fmt(totalOz), unit: "OZ", color: Theme.pink500)
        }
    }
    
    // MARK: - Downstream Calculations
    @ViewBuilder
    var downstreamCalculation: some View {
        switch strategy {
        case .targetPercentage:
            // Max hitting the wall = Source / (Injector + 1)
            let hittingWall = sourceSH / (injectorRatio + 1)
            let isPossible = targetPercent <= hittingWall
            
            GlassCard {
                VStack {
                    Text("AT THE TIP")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    
                    Text("\(String(format: "%.2f", hittingWall))%")
                        .font(Theme.headingFont.weight(.heavy))
                        .font(.system(size: 48))
                        .foregroundColor(Theme.amber500)
                        .shadow(color: Theme.amber500.opacity(0.5), radius: 10)
                    
                    if !isPossible {
                        Text("Target \(String(format: "%.1f", targetPercent))% is unreachable")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            
        case .dilutionRatio:
            // Injector does 10:1 (roughly 9% chem).
            // If we need 4:1 (20% chem), we can't do it unless we boost source? 
            // Usually downstream is fixed. Let's show the final ratio at tip.
            // Ratio at tip = InjectorRatio + (InjectorRatio * SourceDilution?? No)
            // Just injector ratio.
            
            let tipRatio = injectorRatio
            let percentStrength = 1.0 / (injectorRatio + 1) * 100
            
            GlassCard {
                VStack(spacing: 8) {
                    Text("FINAL DILUTION")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    Text("1:\(Int(tipRatio))")
                        .font(Theme.headingFont).font(.title)
                        .foregroundColor(Theme.amber500)
                    Text("Approx \(fmt(percentStrength))% Strength")
                        .font(.caption).foregroundColor(Theme.slate500)
                }
                .frame(maxWidth: .infinity).padding()
            }
            
        case .ozPerGallon:
            // Injector pulls 1 gal chem per X gal water.
            // Result is fixed.
            let ozPerGalAtTip = 128.0 / (injectorRatio + 1)
            
            ResultCard(title: "Oz/Gal at Tip", value: fmt(ozPerGalAtTip), unit: "OZ", color: Theme.pink500)
        }
    }
    
    // MARK: - Manifold Calculations
    @ViewBuilder
    var manifoldCalculation: some View {
        // Simple dial logic assumption: Dial 0-10 represents 0-100% flow relative to water?
        // Or ratio. Simplification:
        // SH: Target / Source * 10
        // Surfactant: Oz / 5 * 10?? (Heuristic)
        
        switch strategy {
        case .targetPercentage:
            let dial = (targetPercent / sourceSH) * 10
            HStack {
                ResultCard(title: "SH Dial", value: fmt(dial), unit: "/ 10", color: Theme.sky500)
                ResultCard(title: "Water Dial", value: "10", unit: "/ 10", color: Theme.emerald500)
            }
            
        case .dilutionRatio:
            // Needs 4:1. 
            // Water = 10 (Max input). Chem needs to be 1/4th of Water flow? No, 4:1 means 4 water 1 chem.
            // So Chem Dial = WaterDial / Ratio.
            let chemDial = 10.0 / dilutionRatio
            
            HStack {
                ResultCard(title: "Chem Dial", value: fmt(chemDial), unit: "/ 10", color: Theme.purple500)
                ResultCard(title: "Water Dial", value: "10", unit: "/ 10", color: Theme.emerald500)
            }
            
        case .ozPerGallon:
            // 1 oz per gallon. 1 gallon = 128 oz.
            // Ratio approx 1:128.
            // Very low dial setting.
            let dial = (ozPerGal / 128.0) * 10 * 10 // *10 boost for metering valve calibration roughly? 
            // This is vague without specific manifold specs. Let's just show Oz info.
            
            ResultCard(title: "Metering Valve", value: "LOW", unit: "\(fmt(ozPerGal)) oz/gal", color: Theme.pink500)
        }
    }
    
    func fmt(_ val: Double) -> String {
        return String(format: "%.1f", val)
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        GlassCard {
            VStack(spacing: 4) {
                Text(title)
                    .font(Theme.labelFont)
                    .foregroundColor(Theme.slate400)
                    .multilineTextAlignment(.center)
                
                Text(value)
                    .font(Theme.headingFont)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.3), radius: 8)
                
                Text(unit)
                    .font(Theme.labelFont)
                    .foregroundColor(Theme.slate500)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

struct ARMeasurePlaceholder: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(Theme.sky500.opacity(0.5))
            Text("AR Measurement Coming Soon")
                .font(Theme.headingFont)
                .foregroundColor(Theme.slate400)
                .padding()
            Spacer()
        }
    }
}
