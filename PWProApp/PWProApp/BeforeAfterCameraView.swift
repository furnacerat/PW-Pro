import SwiftUI
import PhotosUI

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
extension Image {
    init(platformImage: PlatformImage) {
        self.init(nsImage: platformImage)
    }
}
#else
import UIKit
typealias PlatformImage = UIImage
extension Image {
    init(platformImage: PlatformImage) {
        self.init(uiImage: platformImage)
    }
}
#endif

// Extension to bridge UIImage(systemName:) on macOS
extension PlatformImage {
    static func system(name: String) -> PlatformImage? {
        #if os(macOS)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil)
        #else
        return UIImage(systemName: name)
        #endif
    }
}

struct BeforeAfterCameraView: View {
    @State private var beforeImage: PlatformImage?
    @State private var afterImage: PlatformImage?
    @State private var ghostOpacity: Double = 0.4
    @State private var isCameraActive = false
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    #if os(iOS)
    @StateObject private var camera = CameraCoordinator()
    #endif
    
    var body: some View {
        VStack(spacing: 0) {
            if let after = afterImage, let before = beforeImage {
                // Result comparison view
                ComparisonView(before: before, after: after) {
                    // Reset to take another
                    afterImage = nil
                    isCameraActive = true
                    #if os(iOS)
                    camera.startSession()
                    #endif
                }
            } else if isCameraActive {
                // Camera Mode with Ghost Overlay
                ZStack {
                    #if os(iOS)
                    // Real camera feed on iOS
                    if let previewLayer = camera.previewLayer {
                        CameraPreview(previewLayer: previewLayer)
                            .ignoresSafeArea()
                    } else {
                        Color.black.ignoresSafeArea()
                        if !camera.isAuthorized {
                            VStack(spacing: 16) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Theme.slate500)
                                Text("Camera Access Required")
                                    .font(Theme.headingFont)
                                    .foregroundColor(.white)
                                Text("Please enable camera access in Settings")
                                    .font(Theme.bodyFont)
                                    .foregroundColor(Theme.slate400)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                        } else {
                            ProgressView()
                                .tint(Theme.sky500)
                                .scaleEffect(1.5)
                        }
                    }
                    #else
                    // Simulated feed for macOS
                    Color.black.ignoresSafeArea()
                    Image(systemName: "camera.viewfinder")
                        .resizable()
                        .aspectRatio (contentMode: .fit)
                        .foregroundColor(Theme.slate800)
                        .opacity(0.5)
                        .frame(maxWidth: 200)
                    
                    Text("LIVE CAMERA FEED\n(Simulated on macOS)")
                        .font(Theme.labelFont)
                        .foregroundColor(Theme.slate500)
                        .multilineTextAlignment(.center)
                    #endif
                    
                    // Ghost Overlay (Before Image)
                    if let before = beforeImage {
                        Image(platformImage: before)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(ghostOpacity)
                            .allowsHitTesting(false)
                            .ignoresSafeArea()
                    }
                    
                    // Controls
                    VStack {
                        Spacer()
                        
                        // AR Status Bar
                        HStack {
                            Label("AR ALIGNMENT ACTIVE", systemImage: "target")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.emerald500)
                            Spacer()
                            Toggle("GHOST", isOn: Binding(
                                get: { ghostOpacity > 0 },
                                set: { if $0 { ghostOpacity = 0.4 } else { ghostOpacity = 0 } }
                            ))
                            .labelsHidden()
                            .tint(Theme.sky500)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.4))
                         .cornerRadius(20)
                        .padding(.horizontal)
                        
                        // Opacity Slider
                        HStack {
                            Image(systemName: "eye.slash.fill")
                                .foregroundColor(Theme.slate400)
                            Slider(value: $ghostOpacity, in: 0...0.8)
                                .tint(Theme.sky500)
                            Image(systemName: "eye.fill")
                                .foregroundColor(Theme.sky500)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Capture Button
                        Button(action: {
                            #if os(iOS)
                            camera.capturePhoto()
                            #else
                            // Placeholder for macOS
                            afterImage = PlatformImage.system(name: "house.circle.fill")
                            #endif
                        }) {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 60, height: 60)
                                )
                        }
                        .padding(.bottom, 30)
                    }
                }
                #if os(iOS)
                .onChange(of: camera.capturedImage) { _, newImage in
                    if let image = newImage {
                        afterImage = image
                        camera.stopSession()
                    }
                }
                .onAppear {
                    if camera.isAuthorized {
                        camera.setupCamera()
                    }
                }
                .onDisappear {
                    camera.stopSession()
                }
                #endif
            } else {
                // Initial State: Load Before Photo
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "photo.stack")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.sky500)
                        .padding()
                        .background(Theme.sky500.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text("Before & After Camera")
                        .font(Theme.headingFont)
                        .foregroundColor(.white)
                    
                    Text("Choose a 'Before' photo to align your 'After' shot perfectly.")
                        .font(Theme.bodyFont)
                        .foregroundColor(Theme.slate400)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Select Before Photo")
                        }
                        .font(Theme.labelFont)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.sky500)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = PlatformImage(data: data) {
                                beforeImage = image
                                isCameraActive = true
                            } else {
                                // Fallback
                                beforeImage = PlatformImage.system(name: "house")
                                isCameraActive = true 
                            }
                        }
                    }
                    
                    // Demo skip
                    Button("Use Demo Photo") {
                        beforeImage = PlatformImage.system(name: "house") // Placeholder
                        isCameraActive = true
                    }
                    .foregroundColor(Theme.slate500)
                    .padding(.bottom)
                }
                .padding()
            }
        }
        .background(Theme.slate900.ignoresSafeArea())
    }
}

struct ComparisonView: View {
    let before: PlatformImage
    let after: PlatformImage
    let onRetake: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("RESULT")
                    .font(Theme.headingFont)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onRetake) {
                    Text("New")
                        .foregroundColor(Theme.sky500)
                }
            }
            .padding()
            .background(Theme.slate800)
            
            // Side by Side
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Image(platformImage: before)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    
                    Text("BEFORE")
                        .font(Theme.labelFont)
                        .padding(6)
                        .background(.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding(8)
                }
                
                Divider()
                
                ZStack(alignment: .topLeading) {
                    Image(platformImage: after)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    
                    Text("AFTER")
                        .font(Theme.labelFont)
                        .padding(6)
                        .background(.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding(8)
                }
            }
            .frame(maxHeight: .infinity)
            
            // Footer Actions
            HStack(spacing: 16) {
                NeonButton(title: "Share", color: Theme.sky500, icon: "square.and.arrow.up") {
                    // Share action placeholder
                }
                
                NeonButton(title: "Save to Job", color: Theme.emerald500, icon: "checkmark") {
                    // Save action placeholder
                }
            }
            .padding()
            .background(Theme.slate900)
        }
    }
}

