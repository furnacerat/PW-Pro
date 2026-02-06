import SwiftUI
import PhotosUI
import UIKit

struct EstimatesView: View {
    @EnvironmentObject var estimatesStore: EstimatesStore
    @State private var mode: Int = 0 // 0 = Manual, 1 = Photo
    @State private var estimate = Estimate()
    @State private var showImagePicker = false
    @State private var showAfterCamera = false
    @State private var beforeImage: UIImage? = nil
    @State private var afterImage: UIImage? = nil
    @State private var showOverlayPreview = false
    @State private var suggestions: [String] = []
    @State private var objects: [String] = []
    @State private var sqftSuggestion: Double? = nil
    @State private var isAnalyzing = false

    var body: some View {
        Form {
            Picker("Mode", selection: $mode) {
                Text("Manual").tag(0)
                Text("Photo AI").tag(1)
            }
            .pickerStyle(.segmented)

            if mode == 0 {
                manualSection
            } else {
                photoSection
            }

            Section {
                Button("Generate Recommendation") {
                    generateRecommendation()
                }
                Button("Save Estimate") {
                    saveEstimate()
                }
                .buttonStyle(.borderedProminent)
            }

            if !estimate.recommendation.isEmpty {
                Section("Recommendation") {
                    Text(estimate.recommendation)
                    if !estimate.warnings.isEmpty {
                        ForEach(estimate.warnings, id: \.self) { w in
                            Text("⚠️ \(w)")
                                .foregroundColor(.orange)
                        }
                    }
                    if estimate.sqft > 0 {
                        Text("Estimated area: \(Int(estimate.sqft)) sqft")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Estimates")
        .sheet(isPresented: $showImagePicker) {
            PhotoPicker(image: $beforeImage)
        }
        .sheet(isPresented: $showAfterCamera) {
            CameraOverlayPicker(overlayImage: beforeImage) { img in
                if let img = img {
                    afterImage = img
                    estimate.afterImageData = img.jpegData(compressionQuality: 0.8)
                }
            }
        }
        .onChange(of: beforeImage) { _ in
            Task { await analyzeBeforeImage() }
        }
        .sheet(isPresented: $showOverlayPreview) {
            NavigationStack {
                ZStack {
                    if let after = afterImage {
                        Image(uiImage: after).resizable().scaledToFit().ignoresSafeArea()
                    }
                    if let before = beforeImage {
                        Image(uiImage: before).resizable().scaledToFit().opacity(0.35).ignoresSafeArea()
                    }
                }
                .navigationTitle("Overlay Preview")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showOverlayPreview = false } } }
            }
        }
        .overlay {
            if isAnalyzing {
                ProgressView("Analyzing…")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
    }

    var manualSection: some View {
        Section("Manual Input") {
            TextField("Property Owner", text: Binding(
                get: { estimate.propertyOwnerName ?? "" },
                set: { estimate.propertyOwnerName = $0.isEmpty ? nil : $0 }
            ))
            TextField("Property Address", text: Binding(
                get: { estimate.propertyAddress ?? "" },
                set: { estimate.propertyAddress = $0.isEmpty ? nil : $0 }
            ))
            TextField("Scope of Work", text: $estimate.scopeOfWork)

            Toggle("Approved", isOn: $estimate.approved)

            Picker("Surface", selection: $estimate.surface) {
                ForEach(Estimate.SurfaceType.allCases, id: \.self) { s in
                    Text(s.displayName).tag(s)
                }
            }

            Picker("Contamination", selection: $estimate.contamination) {
                ForEach(Estimate.Contamination.allCases, id: \.self) { c in
                    Text(c.displayName).tag(c)
                }
            }

            TextField("Square footage", value: $estimate.sqft, format: .number)
                .keyboardType(.decimalPad)

            TextField("Notes", text: $estimate.notes)
        }
    }

    var photoSection: some View {
        Section("Photo Analysis") {
            if let img = beforeImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
            }

            HStack {
                Button("Pick Before Photo") { showImagePicker = true }
                Spacer()
                Button("Take After Photo (ghost)") {
                    showAfterCamera = true
                }
            }

            if afterImage != nil {
                HStack {
                    Spacer()
                    Button("View Overlay") { showOverlayPreview = true }
                    Spacer()
                }
            }

            if !suggestions.isEmpty || !objects.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    if !suggestions.isEmpty {
                        Text("Surface Suggestions: \(suggestions.joined(separator: ", "))")
                    }
                    if !objects.isEmpty {
                        Text("Detected: \(objects.joined(separator: ", "))")
                    }
                    if let sqft = sqftSuggestion {
                        Text("Image-based sqft suggestion: ~\(Int(sqft)) sqft")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }

    func analyzeBeforeImage() async {
        guard let img = beforeImage else { return }
        isAnalyzing = true
        let result = await AIAnalyzer.analyze(img)
        suggestions = result.surfaces
        objects = result.objects
        sqftSuggestion = result.sqftEstimate

        // Map suggestions into the estimate defaults
        if let first = suggestions.first {
            estimate.surface = Estimate.SurfaceType(rawValue: first) ?? .unknown
        }
        if let firstObj = objects.first {
            if firstObj.lowercased().contains("mildew") || firstObj.lowercased().contains("organic") {
                estimate.contamination = .mildew
            } else if firstObj.lowercased().contains("vegetation") {
                estimate.contamination = .organic
            }
        }
        if let sqft = sqftSuggestion {
            estimate.sqft = sqft
        }
        isAnalyzing = false
    }

    func generateRecommendation() {
        var warnings: [String] = []
        var rec = "Recommended: "

        switch estimate.surface {
        case .vinyl, .aluminum:
            rec += "Low-pressure wash with non-ionic surfactant; avoid acidic cleaners."
        case .brick, .stone, .concrete:
            rec += "Use medium pressure with a mixed alkaline cleaner; pre-wet nearby vegetation and protect plantings."
        case .wood:
            rec += "Low pressure and wood-safe cleaner; avoid soaking and use quick rinse."
        case .unknown:
            rec += "Start with low-pressure rinse and small spot test."
        }

        switch estimate.contamination {
        case .organic:
            rec += " Treat with oxygen bleach or mildew wash for biological growth."
            warnings.append("Biocides may harm vegetation — protect plants and rinsate.")
        case .mildew:
            rec += " Use oxygen or chlorine-based house wash depending on substrate."
            warnings.append("Avoid mixing chlorine with acids or quats.")
        case .oil:
            rec += " Pre-treat with degreaser; consider hot-water or hot-surface methods."
            warnings.append("Oil runoff requires containment and proper disposal.")
        default:
            break
        }

        if estimate.surface == .brick || estimate.surface == .stone {
            warnings.append("High-pressure can damage mortar; use appropriate nozzle angles.")
        }

        if estimate.sqft > 5000 {
            warnings.append("Large area — watch for overspray and plan containment.")
        }

        estimate.recommendation = rec
        estimate.warnings = warnings
    }

    // Save the current estimate into the shared store
    func saveEstimate() {
        // ensure basic fields
        if estimate.propertyOwnerName == nil || estimate.propertyOwnerName?.isEmpty == true {
            estimate.propertyOwnerName = "(Unknown)"
        }
        if estimate.propertyAddress == nil || estimate.propertyAddress?.isEmpty == true {
            estimate.propertyAddress = ""
        }
        estimatesStore.estimates.append(estimate)
        // reset working estimate
        estimate = Estimate()
        beforeImage = nil
        afterImage = nil
    }
}

// Simple photo picker wrapper using PHPicker
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> some UIViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        init(_ parent: PhotoPicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let item = results.first?.itemProvider, item.canLoadObject(ofClass: UIImage.self) else { return }
            item.loadObject(ofClass: UIImage.self) { obj, _ in
                DispatchQueue.main.async {
                    self.parent.image = obj as? UIImage
                }
            }
        }
    }
}

struct EstimatesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { EstimatesView() }
    }
}
