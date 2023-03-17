//  Copyright © 2023 Foursquare Labs, Inc. All rights reserved.


import SwiftUI
import CoreData
import MapKit
import CoreLocation


struct ContentView: View {
    @ObservedObject var locationManager: LocationManager
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span:               MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
    @State private var search = ""
    @State private var places = [Place]()
    @State private var showLocationError = false
    @State private var showApiError = false
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    
    
    var body: some View {
        Map(coordinateRegion: $mapRegion, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: places) { place in
            MapAnnotation(coordinate: place.location) {
                Text(place.name).background(.gray).foregroundColor(.white)
                Circle().fill(Color.indigo)
                    .onTapGesture{
                        print("Tapped on \(place.name)")
                    }
            }
        }
        ZStack(alignment: .bottom) {
            TextField(NSLocalizedString("Search", comment: ""), text: $search) {
                Task { await search() }
            }
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
        ContentView(locationManager: LocationManager() )
    }
}
