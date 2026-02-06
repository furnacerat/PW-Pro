import Foundation
import CoreLocation
import MapKit

struct MeasurementResult {
    var areaSquareFeet: Double
    var perimeterFeet: Double
    var points: [CLLocationCoordinate2D]
}

extension MeasurementResult {
    static func from(coordinates: [CLLocationCoordinate2D]) -> MeasurementResult {
        guard coordinates.count >= 3 else {
            return MeasurementResult(areaSquareFeet: 0, perimeterFeet: 0, points: coordinates)
        }

        // Convert to MKMapPoint for planar shoelace area calculation
        let mapPoints = coordinates.map { MKMapPoint($0) }

        // Shoelace formula on mapPoints (x,y)
        var sum: Double = 0
        for i in 0..<mapPoints.count {
            let j = (i + 1) % mapPoints.count
            sum += mapPoints[i].x * mapPoints[j].y - mapPoints[j].x * mapPoints[i].y
        }
        let polygonAreaMapPoints = abs(sum) / 2.0

        // Approximate meters per map point using average latitude
        let avgLat = coordinates.map { $0.latitude }.reduce(0, +) / Double(coordinates.count)
        let metersPerMapPoint = MKMetersPerMapPointAtLatitude(avgLat)
        let areaSqMeters = polygonAreaMapPoints * metersPerMapPoint * metersPerMapPoint
        let areaSqFeet = areaSqMeters * 10.76391041671

        // Perimeter: sum great-circle distances between consecutive points
        var perimeterMeters: Double = 0
        for i in 0..<coordinates.count {
            let j = (i + 1) % coordinates.count
            let a = CLLocation(latitude: coordinates[i].latitude, longitude: coordinates[i].longitude)
            let b = CLLocation(latitude: coordinates[j].latitude, longitude: coordinates[j].longitude)
            perimeterMeters += a.distance(from: b)
        }
        let perimeterFeet = perimeterMeters * 3.280839895

        return MeasurementResult(areaSquareFeet: areaSqFeet, perimeterFeet: perimeterFeet, points: coordinates)
    }
}
