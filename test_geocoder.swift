import MapKit
import CoreLocation

func testGeocoding() {
    let loc = CLLocation(latitude: 0, longitude: 0)
    // Note: MKReverseGeocodingRequest is often a custom wrapper or older API.
    // Assuming it's defined elsewhere in your project:
    if let req = MKReverseGeocodingRequest(location: loc) {
        req.getMapItems { mapItems, error in
            if let mapItem = mapItems?.first {
                // Fixed deprecation warning: using location instead of placemark
                _ = mapItem.location
                // You can also use mapItem.address if available
            }
        }
    }
}
