import SwiftUI
import CoreLocation

struct MeasuringView: View {
    @State private var points: [CLLocationCoordinate2D] = []
    @State private var result: MeasurementResult? = nil

    var body: some View {
        VStack(spacing: 0) {
            SatelliteMapView(points: $points)
                .frame(maxHeight: 420)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button("Undo") {
                        if !points.isEmpty { points.removeLast(); recompute() }
                    }
                    .disabled(points.isEmpty)

                    Button("Clear") {
                        points.removeAll(); result = nil
                    }
                    Spacer()
                    Button("Compute") { recompute() }
                        .disabled(points.count < 3)
                }
                .padding([.horizontal, .top])

                if let res = result {
                    Text("Area: \(Int(res.areaSquareFeet)) ft²")
                        .font(.headline)
                    Text(String(format: "Perimeter: %.1f ft", res.perimeterFeet))
                        .font(.subheadline)
                    Text("Points: \(res.points.count)")
                        .font(.caption)
                } else {
                    Text("Place at least 3 points on the map (long-press) then tap Compute")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                Spacer()
            }
        }
        .navigationTitle("Measuring")
    }

    private func recompute() {
        result = MeasurementResult.from(coordinates: points)
    }
}

struct MeasuringView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { MeasuringView() }
    }
}
