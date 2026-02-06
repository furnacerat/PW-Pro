import SwiftUI
import MapKit

struct SatelliteEstimatorView: View {
    @State private var position: MapCameraPosition = .automatic
    @State private var points: [CLLocationCoordinate2D] = []
    @State private var showingCalculation = false
    @Environment(\.dismiss) var dismiss
    
    var calculatedArea: Double {
        // Simple Shoelace Formula for area calculation on a flat plane (approximate)
        guard points.count >= 3 else { return 0 }
        
        // Convert coords to meters relative to first point for simpler math
        let origin = points[0]
        let metersPerDegreeY = 111111.0
        let metersPerDegreeX = 111111.0 * cos(origin.latitude * .pi / 180.0)
        
        let pts = points.map { coord in
            CGPoint(
                x: (coord.longitude - origin.longitude) * metersPerDegreeX,
                y: (coord.latitude - origin.latitude) * metersPerDegreeY
            )
        }
        
        var area = 0.0
        for i in 0..<pts.count {
            let p1 = pts[i]
            let p2 = pts[(i + 1) % pts.count]
            area += (p1.x * p2.y) - (p2.x * p1.y)
        }
        
        return abs(area) / 2.0 * 10.7639 // Convert sqm to sqft
    }
    
    var body: some View {
        ZStack {
            MapReader { reader in
                Map(position: $position) {
                    ForEach(0..<points.count, id: \.self) { i in
                        Annotation("", coordinate: points[i]) {
                            Circle()
                                .fill(Theme.sky500)
                                .frame(width: 10, height: 10)
                                .shadow(radius: 2)
                        }
                    }
                    
                    if points.count >= 3 {
                        MapPolygon(coordinates: points)
                            .foregroundStyle(Theme.sky500.opacity(0.3))
                            .stroke(Theme.sky500, lineWidth: 2)
                    }
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .onTapGesture { screenPoint in
                    if let coordinate = reader.convert(screenPoint, from: .local) {
                        points.append(coordinate)
                    }
                }
            }
            
            // UI Overlay
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("AERIAL ESTIMATOR")
                        .font(Theme.labelFont)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    Spacer()
                    Button(action: { points.removeAll() }) {
                        Image(systemName: "trash")
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                if !points.isEmpty {
                    GlassCard {
                        VStack(spacing: 12) {
                            HStack {
                                StatBadge(title: "POINTS", value: "\(points.count)", color: Theme.sky500)
                                Spacer()
                                StatBadge(title: "EST. AREA", value: "\(Int(calculatedArea)) SQFT", color: Theme.emerald500)
                            }
                            
                            if points.count >= 3 {
                                NeonButton(title: "Use This Measurement", color: Theme.emerald500) {
                                    // Pass data back in real app
                                    dismiss()
                                }
                            } else {
                                Text("Tap 3+ points to calculate area")
                                    .font(.caption)
                                    .foregroundColor(Theme.slate400)
                            }
                        }
                    }
                    .padding()
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SatelliteEstimatorView()
}
