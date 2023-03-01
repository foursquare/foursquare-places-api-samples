//  Copyright © 2023 Foursquare Labs, Inc. All rights reserved.

import SwiftUI
import MapboxMaps

@main
struct MapBoxPlacesSwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(locationManager: LocationManager())
        }
    }
}
