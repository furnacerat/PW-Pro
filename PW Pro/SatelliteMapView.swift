import SwiftUI
import MapKit

/// A simple MKMapView wrapper configured for satellite imagery and point capture.
struct SatelliteMapView: UIViewRepresentable {
    @Binding var points: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.mapType = .satellite
        map.showsUserLocation = false
        map.delegate = context.coordinator
        map.isRotateEnabled = true
        map.pointOfInterestFilter = .excludingAll

        let long = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        long.minimumPressDuration = 0.4
        map.addGestureRecognizer(long)

        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // update annotations and polygon overlay
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)

        for coord in points {
            let ann = MKPointAnnotation()
            ann.coordinate = coord
            uiView.addAnnotation(ann)
        }

        if points.count >= 2 {
            let polygon = MKPolygon(coordinates: points, count: points.count)
            uiView.addOverlay(polygon)
        }

        if let last = points.last {
            let region = MKCoordinateRegion(center: last, latitudinalMeters: 200, longitudinalMeters: 200)
            uiView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: SatelliteMapView

        init(_ parent: SatelliteMapView) { self.parent = parent }

        @objc func handleLongPress(_ gr: UILongPressGestureRecognizer) {
            guard gr.state == .began, let map = gr.view as? MKMapView else { return }
            let pt = gr.location(in: map)
            let coord = map.convert(pt, toCoordinateFrom: map)
            parent.points.append(coord)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolygon {
                let r = MKPolygonRenderer(polygon: poly)
                r.fillColor = UIColor.systemBlue.withAlphaComponent(0.15)
                r.strokeColor = UIColor.systemBlue
                r.lineWidth = 2
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
