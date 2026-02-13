import SwiftUI
import PhotosUI

struct ShowcaseView: View {
    @StateObject var jobManager = ActiveJobManager.shared
    @StateObject var invoiceManager = InvoiceManager.shared
    
    @State private var beforeItem: PhotosPickerItem?
    @State private var afterItem: PhotosPickerItem?
    
    @State private var beforeImage: UIImage?
    @State private var afterImage: UIImage?
    
    @State private var selectedLayout: ShowcaseLayout = .splitVertical
    @State private var generatedImage: UIImage?
    @State private var isGenerating = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.slate900.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Photo Selection
                        HStack(spacing: 16) {
                            PhotoPickerBox(title: "BEFORE", selection: $beforeItem, image: $beforeImage, jobImage: jobManager.beforeImage)
                            PhotoPickerBox(title: "AFTER", selection: $afterItem, image: $afterImage, jobImage: jobManager.afterImage)
                        }
                        .padding(.horizontal)
                        
                        // 2. Layout Selection
                        Picker("Layout", selection: $selectedLayout) {
                            ForEach(ShowcaseLayout.allCases) { layout in
                                Text(layout.rawValue).tag(layout)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: selectedLayout) { _, _ in generatePreview() }
                        
                        // 3. Preview
                        if let preview = generatedImage {
                            Image(uiImage: preview)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.3), radius: 10)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.slate700, lineWidth: 1)
                                        .padding()
                                )
                        } else {
                            Rectangle()
                                .fill(Theme.slate800)
                                .frame(height: 300)
                                .cornerRadius(12)
                                .padding()
                                .overlay(Text("Select both photos to preview").foregroundColor(Theme.slate500))
                        }
                        
                        // 4. Actions
                        if generatedImage != nil {
                            Button {
                                showingShareSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share to Social Media")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.sky500)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Before & After Studio")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                if let image = generatedImage {
                    ShareSheet(activityItems: [image])
                }
            }
            .onAppear {
                // Auto-load images from active job if available
                if let jobBefore = jobManager.beforeImage {
                    self.beforeImage = jobBefore
                }
                if let jobAfter = jobManager.afterImage {
                    self.afterImage = jobAfter
                }
                generatePreview()
            }
            .onChange(of: beforeImage) { _, _ in generatePreview() }
            .onChange(of: afterImage) { _, _ in generatePreview() }
        }
    }
    
    private func generatePreview() {
        guard let b = beforeImage, let a = afterImage else { return }
        
        isGenerating = true
        // format branding settings
        let settings = invoiceManager.businessSettings
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = ShowcaseGenerator.generateShowcase(before: b, after: a, layout: selectedLayout, businessSettings: settings)
            DispatchQueue.main.async {
                self.generatedImage = result
                self.isGenerating = false
            }
        }
    }
}

struct PhotoPickerBox: View {
    let title: String
    @Binding var selection: PhotosPickerItem?
    @Binding var image: UIImage?
    var jobImage: UIImage?
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(Theme.slate400)
            
            PhotosPicker(selection: $selection, matching: .images) {
                ZStack {
                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.slate800)
                            .frame(height: 150)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.title)
                                    .foregroundColor(Theme.slate600)
                            )
                    }
                }
            }
            .onChange(of: selection) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        image = uiImage
                    }
                }
            }
        }
    }
}
