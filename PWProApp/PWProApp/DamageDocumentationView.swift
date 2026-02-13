import SwiftUI
import PhotosUI

// MARK: - Damage Record Model

struct DamageRecord: Codable, Identifiable {
    let id: UUID
    var note: String
    var timestamp: Date
    var jobReference: String // Free-text job/estimate/invoice reference
    var imageFileNames: [String] // Local file names in app documents dir
    
    init(note: String = "", jobReference: String = "", imageFileNames: [String] = []) {
        self.id = UUID()
        self.timestamp = Date()
        self.note = note
        self.jobReference = jobReference
        self.imageFileNames = imageFileNames
    }
    
    var formattedTimestamp: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm:ss a"
        fmt.timeZone = .current
        return fmt.string(from: timestamp)
    }
    
    var shortTimestamp: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy · h:mm a"
        return fmt.string(from: timestamp)
    }
}

// MARK: - Persistence

class DamageRecordStore: ObservableObject {
    static let shared = DamageRecordStore()
    
    @Published var records: [DamageRecord] = []
    
    private let storageKey = "damageRecords"
    
    init() {
        load()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([DamageRecord].self, from: data) else { return }
        records = decoded
    }
    
    func add(_ record: DamageRecord) {
        records.insert(record, at: 0)
        save()
    }
    
    func delete(_ record: DamageRecord) {
        // Delete image files
        for fileName in record.imageFileNames {
            let url = Self.imageDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: url)
        }
        records.removeAll { $0.id == record.id }
        save()
    }
    
    // MARK: - Image Storage
    
    static var imageDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("DamagePhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    #if os(iOS)
    static func saveImage(_ image: UIImage) -> String? {
        let fileName = UUID().uuidString + ".jpg"
        let url = imageDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        do {
            try data.write(to: url)
            return fileName
        } catch {
            print("❌ Failed to save damage photo: \(error)")
            return nil
        }
    }
    #endif
    
    static func loadImage(named fileName: String) -> PlatformImage? {
        let url = imageDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        #if os(iOS)
        return UIImage(data: data)
        #else
        return NSImage(data: data)
        #endif
    }
}

// MARK: - Main View

struct DamageDocumentationView: View {
    @StateObject private var store = DamageRecordStore.shared
    @State private var showNewReport = false
    @State private var searchText = ""
    
    var filteredRecords: [DamageRecord] {
        if searchText.isEmpty { return store.records }
        return store.records.filter {
            $0.note.localizedCaseInsensitiveContains(searchText) ||
            $0.jobReference.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            if store.records.isEmpty {
                emptyState
            } else {
                recordsList
            }
        }
        .sheet(isPresented: $showNewReport) {
            NewDamageReportSheet(store: store)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Theme.amber500.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "camera.badge.clock.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.amber500)
            }
            
            VStack(spacing: 8) {
                Text("Pre-Job Damage Docs")
                    .font(Theme.headingFont)
                    .foregroundColor(.white)
                
                Text("Photograph existing damage before every job.\nTimestamped, commented, and linked to your jobs.")
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.slate400)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { showNewReport = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Damage Report")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Theme.amber500, Theme.amber500.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Theme.amber500.opacity(0.3), radius: 12, y: 4)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Records List
    
    private var recordsList: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAMAGE REPORTS")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    Text("\(store.records.count) report\(store.records.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.slate500)
                }
                
                Spacer()
                
                Button(action: { showNewReport = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.amber500)
                        .shadow(color: Theme.amber500.opacity(0.3), radius: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.slate500)
                
                TextField("Search by note or job ref…", text: $searchText)
                    .font(Theme.bodyFont)
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.slate500)
                    }
                }
            }
            .padding(10)
            .background(Theme.slate800)
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredRecords) { record in
                        DamageRecordCard(record: record, store: store)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Damage Record Card

struct DamageRecordCard: View {
    let record: DamageRecord
    @ObservedObject var store: DamageRecordStore
    @State private var isExpanded = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row — always visible
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Thumbnail
                    if let first = record.imageFileNames.first,
                       let img = DamageRecordStore.loadImage(named: first) {
                        Image(platformImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .cornerRadius(10)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.slate700)
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(Theme.slate500)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Job Reference
                        if !record.jobReference.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 9))
                                Text(record.jobReference)
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(Theme.sky500)
                        }
                        
                        // Note preview
                        Text(record.note.isEmpty ? "No comment" : record.note)
                            .font(Theme.bodyFont)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        // Timestamp
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                            Text(record.shortTimestamp)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(Theme.slate500)
                    }
                    
                    Spacer()
                    
                    // Photo count + chevron
                    VStack(spacing: 4) {
                        HStack(spacing: 3) {
                            Text("\(record.imageFileNames.count)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                            Image(systemName: "photo.fill")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(Theme.slate400)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.slate600)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
                .padding(12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded detail
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().background(Theme.slate700)
                    
                    // Full timestamp
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(Theme.amber500)
                        Text(record.formattedTimestamp)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.amber500)
                    }
                    
                    // Full note
                    if !record.note.isEmpty {
                        Text(record.note)
                            .font(Theme.bodyFont)
                            .foregroundColor(Theme.slate300)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Photo grid
                    if !record.imageFileNames.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(record.imageFileNames, id: \.self) { fileName in
                                if let img = DamageRecordStore.loadImage(named: fileName) {
                                    Image(platformImage: img)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 100)
                                        .cornerRadius(8)
                                        .clipped()
                                }
                            }
                        }
                    }
                    
                    // Delete
                    HStack {
                        Spacer()
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Delete Report")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.red500)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.red500.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.slate800.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.slate700.opacity(0.5), lineWidth: 0.5)
                )
        )
        .confirmationDialog("Delete this damage report?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                withAnimation {
                    store.delete(record)
                }
            }
        }
    }
}

// MARK: - New Damage Report Sheet

struct NewDamageReportSheet: View {
    @ObservedObject var store: DamageRecordStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var note = ""
    @State private var jobReference = ""
    @State private var capturedImages: [PlatformImage] = []
    @State private var showImageSourcePicker = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @StateObject private var jobManager = ActiveJobManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.slate900.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Timestamp
                        timestampCard
                        
                        // Job Reference
                        if jobManager.isActive {
                            autoLinkedJobCard
                        } else {
                            jobReferenceCard
                        }
                        
                        // Photos
                        photosCard
                        
                        // Notes
                        notesCard
                        
                        // Save Button
                        saveButton
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Damage Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.slate400)
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showCamera) {
                DamageCameraCapture { image in
                    capturedImages.append(image)
                }
            }
            #endif
        }
        .presentationDetents([.large])
    }
    
    // MARK: - Timestamp Card
    
    private var timestampCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .foregroundColor(Theme.emerald500)
                    Text("TIMESTAMP")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                }
                
                Text(currentTimestamp)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("Automatically recorded when you save")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.slate500)
            }
        }
    }
    
    private var currentTimestamp: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm:ss a"
        fmt.timeZone = .current
        return fmt.string(from: Date())
    }
    
    // MARK: - Job Reference Card
    
    private var jobReferenceCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .foregroundColor(Theme.sky500)
                    Text("JOB / ESTIMATE / INVOICE REF")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                }
                
                TextField("e.g. JOB-2024-0042 or Smith Residence", text: $jobReference)
                    .font(Theme.bodyFont)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Theme.slate800)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.slate700, lineWidth: 1)
                    )
                
                Text("Links this report to a specific job for CYA")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.slate500)
            }
        }
    }
    
    // MARK: - Photos Card
    
    private var photosCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(Theme.amber500)
                    Text("DAMAGE PHOTOS")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                    
                    Spacer()
                    
                    if !capturedImages.isEmpty {
                        Text("\(capturedImages.count) photo\(capturedImages.count == 1 ? "" : "s")")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.amber500)
                    }
                }
                
                // Photo Grid
                if !capturedImages.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 8) {
                        ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, img in
                            ZStack(alignment: .topTrailing) {
                                Image(platformImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 100)
                                    .cornerRadius(8)
                                    .clipped()
                                
                                // Remove button
                                Button {
                                    withAnimation { let _ = capturedImages.remove(at: index) }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.5), radius: 4)
                                }
                                .padding(4)
                            }
                        }
                    }
                }
                
                // Add Photo Buttons
                HStack(spacing: 12) {
                    #if os(iOS)
                    Button {
                        showCamera = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                            Text("Take Photo")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.amber500)
                        .cornerRadius(10)
                    }
                    #endif
                    
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle")
                            Text("Library")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.slate700)
                        .cornerRadius(10)
                    }
                    .onChange(of: selectedItems) { _, newItems in
                        Task {
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self) {
                                    #if os(iOS)
                                    if let uiImage = UIImage(data: data) {
                                        await MainActor.run {
                                            capturedImages.append(uiImage)
                                        }
                                    }
                                    #else
                                    if let nsImage = NSImage(data: data) {
                                        await MainActor.run {
                                            capturedImages.append(nsImage)
                                        }
                                    }
                                    #endif
                                }
                            }
                            selectedItems = []
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Notes Card
    
    private var notesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .foregroundColor(Theme.purple500)
                    Text("NOTES / COMMENTS")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate400)
                }
                
                TextEditor(text: $note)
                    .font(Theme.bodyFont)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Theme.slate800)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.slate700, lineWidth: 1)
                    )
                
                Text("Describe the damage—location, severity, type")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.slate500)
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button(action: saveReport) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                Text("Save Damage Report")
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: capturedImages.isEmpty
                        ? [Theme.slate600, Theme.slate700]
                        : [Theme.amber500, Theme.amber500.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: capturedImages.isEmpty ? .clear : Theme.amber500.opacity(0.3), radius: 12, y: 4)
        }
        .disabled(capturedImages.isEmpty)
    }
    
    // MARK: - Save Logic
    
    private func saveReport() {
        var fileNames: [String] = []
        
        #if os(iOS)
        for image in capturedImages {
            if let fileName = DamageRecordStore.saveImage(image) {
                fileNames.append(fileName)
            }
        }
        #endif
        
        let record = DamageRecord(
            note: note,
            jobReference: jobManager.isActive ? "\(jobManager.jobDisplayName) — \(jobManager.jobDisplayAddress)" : jobReference,
            imageFileNames: fileNames
        )
        
        if jobManager.isActive {
            jobManager.addDamageRecord(record)
        } else {
            store.add(record)
        }
        HapticManager.success()
        dismiss()
    }
    
    // MARK: - Auto-Linked Job Card
    
    private var autoLinkedJobCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "link.circle.fill")
                        .foregroundColor(Theme.emerald500)
                    Text("AUTO-LINKED TO ACTIVE JOB")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.emerald500)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Theme.emerald500)
                        .frame(width: 6, height: 6)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(jobManager.jobDisplayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(jobManager.jobDisplayAddress)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.slate400)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.emerald500.opacity(0.08))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Camera Capture (iOS only)

#if os(iOS)
struct DamageCameraCapture: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: DamageCameraCapture
        
        init(_ parent: DamageCameraCapture) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif

#Preview {
    DamageDocumentationView()
}
