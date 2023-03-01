//  Copyright © 2023 Foursquare Labs, Inc. All rights reserved.

import Foundation
import CoreLocation

final class Api {
    enum Error: Swift.Error {
        case httpError(statusCode: Int)
        case serializationError
    }

    private init() { }

    class func getPlaces(query: String, location: CLLocation) async throws -> [Place] {
        let url = {
            var comps = URLComponents(string: "https://api.foursquare.com/v3/places/search")!
            comps.queryItems = [
                URLQueryItem(name: "query", value: query.self),
                URLQueryItem(name: "ll", value: "\(location.coordinate.latitude),\(location.coordinate.longitude)"),
                URLQueryItem(name: "limit", value: "15")
            ]
            comps.percentEncodedQuery = comps.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            return comps.url!
        }()
        let request = {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = [
                "accept": "application/json",
                "Authorization" : "[YOUR_API_KEY]"
            ]
            return request
        }()
        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)!.statusCode
        if statusCode != 200 {
            throw Error.httpError(statusCode: statusCode)
        }
        guard let response = try? JSONDecoder().decode(PlacesResponse.self, from: data) else {
            throw Error.serializationError
        }
        return response.results
    }
}
