//  Copyright © 2023 Foursquare Labs, Inc. All rights reserved.

import SwiftUI
import MapboxMaps

struct ContentView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var search = ""
    @State private var places = [Place]()
    @State private var showLocationError = false
    @State private var showApiError = false
    
    var body: some View {
        MapBoxMapView(places: $places)
        ZStack(alignment: .bottom) {
            TextField(NSLocalizedString("Search", comment: ""), text: $search) {
                Task { await search() }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
            .offset(y: 0)
            .alert(NSLocalizedString("Unable to get location", comment: ""), isPresented: $showLocationError) {
                Button(NSLocalizedString("OK", comment: ""), role: .cancel) { }
            }
            .alert(NSLocalizedString("Unable to get places", comment: ""), isPresented: $showApiError) {
                Button(NSLocalizedString("OK", comment: ""), role: .cancel) { }
            }
        }
    }

    private func search() async {
        do {
            guard let location = locationManager.location else {
                showLocationError = true
                return
            }
            places = try await Api.getPlaces(query: search, location: location)
        } catch {
            showApiError = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(locationManager: LocationManager())
    }
}

