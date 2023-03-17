//  Copyright © 2023 Foursquare Labs, Inc. All rights reserved.

import SwiftUI

@main
struct applewebkit_map_and_fsq_places_apiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(locationManager: LocationManager())
        }
    }
}
