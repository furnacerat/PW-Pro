import SwiftUI

struct ChemicalCalculatorView: View {
    enum Mode: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case batch = "Batch Mix"
        case manifold = "Manifold Valve"
        case injector = "Downstream Injector"
    }

    @State private var selectedChemicalIndex = 0
    @State private var mode: Mode = .batch
    @State private var tankSize: String = "50" // gallons
    @State private var desiredPercent: String = "2.0"
    @State private var totalGallons: String = "100"
    @State private var ratioPresetIndex = 2

    let ratioPresets: [Double] = [5, 10, 20, 50, 100, 128]

    var body: some View {
        Form {
            Section("Chemical") {
                Picker("Chemical", selection: $selectedChemicalIndex) {
                    ForEach(0..<ChemicalData.chemicals.count, id: \.self) { i in
                        Text(ChemicalData.chemicals[i].name).tag(i)
                    }
                }
            }

            Section("Mode") {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
            }

            if mode == .batch {
                Section("Batch Mix") {
                    HStack { Text("Tank size (gal)"); Spacer(); TextField("50", text: $tankSize).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text("Desired %"); Spacer(); TextField("2.0", text: $desiredPercent).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    VStack(alignment: .leading, spacing: 8) {
                        let t = Double(tankSize) ?? 0
                        let p = (Double(desiredPercent) ?? 0) / 100.0
                        let chemGal = t * p
                        let chemOz = chemGal * 128.0
                        let waterGal = max(0, t - chemGal)
                        Text("Chemical: \(format(chemGal)) gal (\(format(chemOz)) oz)")
                        Text("Water: \(format(waterGal)) gal")
                        Text("Application %: \(format(p * 100)) %")
                    }
                }
            } else if mode == .manifold {
                Section("Manifold / Mixing Valve") {
                    Picker("Valve ratio (1:X)", selection: $ratioPresetIndex) {
                        ForEach(0..<ratioPresets.count, id: \.self) { i in
                            Text("1:\(String(Int(ratioPresets[i])))").tag(i)
                        }
                    }
                    HStack { Text("Tank size (gal)"); Spacer(); TextField("100", text: $tankSize).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text("Or desired % (optional)"); Spacer(); TextField("2.0", text: $desiredPercent).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }

                    VStack(alignment: .leading, spacing: 8) {
                        let t = Double(tankSize) ?? 0
                        let ratio = ratioPresets[ratioPresetIndex]
                        let frac = 1.0 / (1.0 + ratio)
                        let achieved = frac * 100.0
                        let chemGal = t * frac
                        Text("Valve ratio: 1:\(String(Int(ratio)))")
                        Text("Achieved application: \(format(achieved)) %")
                        Text("Chemical for tank: \(format(chemGal)) gal")
                        if let desired = Double(desiredPercent), desired > 0 {
                            let reqRatio = max(0.0, (1.0 / (desired / 100.0)) - 1.0)
                            let nearest = nearestPreset(to: reqRatio)
                            Text("To reach \(format(desired))% you need ~1:\(formatDecimal(reqRatio)) (nearest common: 1:\(String(Int(nearest))) )")
                        }
                    }
                }
            } else if mode == .injector {
                Section("Downstream Injector") {
                    Picker("Injector ratio (1:X)", selection: $ratioPresetIndex) {
                        ForEach(0..<ratioPresets.count, id: \.self) { i in
                            Text("1:\(String(Int(ratioPresets[i])))").tag(i)
                        }
                    }
                    HStack { Text("Total gallons to apply"); Spacer(); TextField("100", text: $totalGallons).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text("Or desired % (optional)"); Spacer(); TextField("2.0", text: $desiredPercent).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }

                    VStack(alignment: .leading, spacing: 8) {
                        let total = Double(totalGallons) ?? 0
                        let ratio = ratioPresets[ratioPresetIndex]
                        let frac = 1.0 / (1.0 + ratio)
                        let achieved = frac * 100.0
                        let chemGal = total * frac
                        Text("Injector ratio: 1:\(String(Int(ratio)))")
                        Text("Achieved application: \(format(achieved)) %")
                        Text("Chemical required: \(format(chemGal)) gal (\(format(chemGal*128)) oz)")
                        if let desired = Double(desiredPercent), desired > 0 {
                            let reqRatio = max(0.0, (1.0 / (desired / 100.0)) - 1.0)
                            let nearest = nearestPreset(to: reqRatio)
                            Text("To reach \(format(desired))% you need ~1:\(formatDecimal(reqRatio)) (nearest common: 1:\(String(Int(nearest))) )")
                        }
                    }
                }
            }
        }
        .navigationTitle("Chemical Calculator")
    }

    func format(_ value: Double) -> String {
        if abs(value) >= 1000 { return String(format: "%.0f", value) }
        return String(format: "%.3g", value)
    }

    func formatDecimal(_ value: Double) -> String {
        return String(format: "%.1f", value)
    }

    func nearestPreset(to ratio: Double) -> Double {
        guard ratio.isFinite && ratio > 0 else { return ratioPresets.last ?? 100 }
        var best = ratioPresets[0]
        var bestDiff = abs(ratio - best)
        for p in ratioPresets {
            let d = abs(ratio - p)
            if d < bestDiff { best = p; bestDiff = d }
        }
        return best
    }
}

struct ChemicalCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { ChemicalCalculatorView() }
    }
}
