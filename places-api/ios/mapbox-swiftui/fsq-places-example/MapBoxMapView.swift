//  Copyright © 2023 Foursquare Labs, Inc. All rights reserved.

import SwiftUI
import CoreLocation

struct MapBoxMapView: UIViewControllerRepresentable {
    @Binding var places: [Place]
    
    func makeUIViewController(context: Context) -> MapBoxMapViewController {
        return MapBoxMapViewController()
    }
      
    func updateUIViewController(_ uiViewController: MapBoxMapViewController, context: Context) {
        uiViewController.removeAllAnnotations()

        var closest: Place?
        var closestDistance: Int = 0

        for place in places {
            guard let main = place.geocodes["main"] else {
                continue
            }
            uiViewController.addPointAndViewAnnotation(at: CLLocationCoordinate2D(latitude: main.latitude, longitude: main.longitude), title: place.name)
            
            if (place.distance < closestDistance || closestDistance == 0) {
                closest = place
                closestDistance = place.distance
            }
        }

        guard let closest = closest,
            let latitude = closest.geocodes["main"]?.latitude,
            let longitude = closest.geocodes["main"]?.longitude else {
            return
        }
        let centerCoodinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        uiViewController.updateCameraView(center: centerCoodinate)
    }
    
}
