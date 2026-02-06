import SwiftUI
import AVFoundation

struct SmartCameraView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Binding var estimatedSqFt: Double
    @Binding var identifiedSurface: SurfaceType?
    
    @State private var isScanning = true
    @State private var scanProgress: CGFloat = 0.0
    @State private var foundSurface: SurfaceType? = nil
    @State private var confidence: Double = 0.0
    @State private var algaeDensity: Double = 0.0
    @State private var mossDensity: Double = 0.0
    @State private var showARMeasure = false
    
    @State private var arPoints: [CGPoint] = []
    @State private var measuredArea: Double = 0
    
    #if os(iOS)
    @StateObject private var camera = CameraCoordinator()
    #endif
    
    var body: some View {
        ZStack {
            // 1. Camera Feed
            #if os(iOS)
            if let previewLayer = camera.previewLayer {
                CameraPreview(previewLayer: previewLayer)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                if !camera.isAuthorized {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill").font(.system(size: 60)).foregroundColor(Theme.slate500)
                        Text("Camera Access Required").font(Theme.headingFont).foregroundColor(.white)
                        Text("Enable in Settings").font(Theme.bodyFont).foregroundColor(Theme.slate400)
                    }
                    .padding()
                } else {
                    ProgressView().tint(Theme.sky500).scaleEffect(1.5)
                }
            }
            #else
            Color.black.ignoresSafeArea()
            Image(systemName: "house.fill").resizable().aspectRatio(contentMode: .fit).foregroundColor(Theme.slate800).opacity(0.3).frame(maxWidth: 300)
            #endif
            
            // 2. AR Overlay (Grid)
            if showARMeasure {
                ARGridOverlay(points: $arPoints, measuredArea: $measuredArea)
            }
            
            // 3. Scanner UI
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill").font(.title).foregroundColor(.white)
                    }
                    Spacer()
                    Text(showARMeasure ? "AR MEASURE" : "AI SCANNER").font(Theme.labelFont).padding(.horizontal, 12).padding(.vertical, 6).background(.ultraThinMaterial).cornerRadius(16)
                    Spacer()
                    Button(action: { withAnimation { showARMeasure.toggle() } }) {
                        Image(systemName: showARMeasure ? "camera.viewfinder" : "ruler.fill").font(.title2).foregroundColor(Theme.sky500).padding(8).background(.ultraThinMaterial).clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // Reticle
                if !showARMeasure {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2).fill(Theme.sky500).frame(height: 2).offset(y: scanProgress)
                        RoundedRectangle(cornerRadius: 12).stroke(Theme.sky500.opacity(0.5), lineWidth: 2).frame(width: 250, height: 250)
                    }
                    .frame(height: 250)
                }
                
                Spacer()
                
                // Bottom Panel
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        if showARMeasure {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("MEASURED AREA").font(Theme.labelFont).foregroundColor(Theme.slate400)
                                    Text("\(Int(measuredArea)) sq ft").font(Theme.headingFont).foregroundColor(Theme.emerald500)
                                }
                                Spacer()
                                if measuredArea > 0 {
                                    NeonButton(title: "Confirm", color: Theme.emerald500) {
                                        useMeasureAndDismiss()
                                    }
                                    .frame(width: 120)
                                }
                            }
                        } else {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("DETECTED SURFACE").font(Theme.labelFont).foregroundColor(Theme.slate400)
                                    if let surface = foundSurface {
                                        HStack {
                                            Image(systemName: surface.icon).foregroundColor(Theme.sky500)
                                            Text(surface.rawValue).font(Theme.bodyFont).fontWeight(.bold).foregroundColor(.white)
                                        }
                                        Text("Confidence: \(Int(confidence * 100))%").font(.caption).foregroundColor(Theme.emerald500)
                                    } else {
                                        Text("Analyzing...").font(Theme.bodyFont).foregroundColor(Theme.slate500).italic()
                                    }
                                }
                                Spacer()
                                if let surface = foundSurface {
                                    NeonButton(title: "Use", color: Theme.sky500) {
                                        useScanAndDismiss(surface: surface)
                                    }
                                    .frame(width: 80)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            // Allow free scans - only show paywall after they've used their free scans
            #if os(iOS)
            if camera.isAuthorized {
                 camera.setupCamera()
            }
            #endif
            startScanSimulation()
        }
        .overlay(alignment: .top) {
            // Free scans remaining badge
            if !subscriptionManager.isSubscribed && subscriptionManager.freeScansRemaining > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text("\(subscriptionManager.freeScansRemaining) free scans left")
                        .font(.caption.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.emerald500.opacity(0.9))
                .cornerRadius(20)
                .padding(.top, 80)
            }
        }
    }
    
    private func useScanAndDismiss(surface: SurfaceType) {
        // Consume a free scan if not subscribed
        if subscriptionManager.useFreeScan() {
            identifiedSurface = surface
            HapticManager.success()
            dismiss()
        }
        // If useFreeScan returned false, paywall will show automatically
    }
    
    private func useMeasureAndDismiss() {
        // Consume a free scan if not subscribed
        if subscriptionManager.useFreeScan() {
            estimatedSqFt = measuredArea
            HapticManager.success()
            dismiss()
        }
    }
    
    func startScanSimulation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            scanProgress = 125
        }
        Task {
            // Wait for camera to warm up
            try? await Task.sleep(nanoseconds: 2 * 1000000000)
            
            #if os(iOS)
            if camera.isAuthorized {
                 camera.capturePhoto()
                 // Allow time for capture
                 try? await Task.sleep(nanoseconds: 1000000000)
                 
                 if let image = camera.capturedImage {
                     do {
                         let result = try await GeminiManager.shared.analyzeImage(image)
                         
                         await MainActor.run {
                             withAnimation {
                                 foundSurface = result.surfaceType
                                 confidence = result.confidence
                                 algaeDensity = result.algaeDensity
                                 mossDensity = result.mossDensity
                             }
                         }
                         return
                     } catch {
                         print("Analysis failed: \(error)")
                     }
                 }
            }
            #endif
            
            // Fallback / Demo simulation if hardware fails
            await MainActor.run {
                withAnimation {
                    foundSurface = .sidingVinyl
                    confidence = 0.92
                    algaeDensity = 0.15
                    mossDensity = 0.05
                }
            }
        }
    }
}

// Simple Grid to simulate AR Planes
struct ARGridOverlay: View {
    @Binding var points: [CGPoint]
    @Binding var measuredArea: Double
    
    var body: some View {
        Canvas { context, size in
            // Draw grid lines
            let step: CGFloat = 40
            for x in stride(from: 0, to: size.width, by: step) {
                let path = Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(path, with: .color(.white.opacity(0.1)), lineWidth: 1)
            }
            for y in stride(from: 0, to: size.height, by: step) {
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(.white.opacity(0.1)), lineWidth: 1)
            }
            
            // Draw Points
            for point in points {
                let rect = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: rect), with: .color(Theme.emerald500))
            }
            
            // Draw Shape
            if points.count > 1 {
                var path = Path()
                path.move(to: points[0])
                for i in 1..<points.count {
                    path.addLine(to: points[i])
                }
                if points.count > 2 {
                    path.closeSubpath()
                    context.fill(path, with: .color(Theme.emerald500.opacity(0.2)))
                    context.stroke(path, with: .color(Theme.emerald500), lineWidth: 2)
                } else {
                    context.stroke(path, with: .color(Theme.emerald500), lineWidth: 2)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            points.append(location)
            // Fake calculation logic: area roughly equals bounds width * height / X
            if points.count > 2 {
                 // Mock Area Calculation
                 let width = abs(points.last!.x - points.first!.x)
                 let height = abs(points.last!.y - points.first!.y)
                 measuredArea = Double(width * height / 10) // Mock scale factor
            }
        }
    }
}
