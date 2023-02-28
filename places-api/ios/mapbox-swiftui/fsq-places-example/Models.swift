//  Copyright © 2023 Foursquare Labs, Inc. All rights reserved.

import Foundation
import CoreLocation

struct PlacesResponse: Codable {
    let results: [Place]
}

struct Place: Codable {
    let name: String
    let geocodes: [String: Geocode]
    let distance: Int
}

struct Geocode: Codable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
}
