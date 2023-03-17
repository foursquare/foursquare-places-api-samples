//  Copyright © 2023 Foursquare Labs, Inc. All rights reserved.

import Foundation
import CoreLocation

struct PlacesResponse: Codable {
    let results: [Place]
}

struct Place: Codable {
    let fsq_id: String
    let name: String
    let geocodes: [String: Geocode]
    let distance: Int
}

extension Place: Identifiable {
    var id: String { fsq_id }
    var location: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: self.geocodes["main"]!.latitude, longitude: self.geocodes["main"]!.longitude) }
}

struct Geocode: Codable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
}
