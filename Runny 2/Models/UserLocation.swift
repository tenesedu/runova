import Foundation
import FirebaseFirestore
import MapKit

// UserLocation now expects a User model which contains a GeoPoint
struct UserLocation: Identifiable {
    let id: String
      let name: String
      let imageURL: String
      let coordinate: CLLocationCoordinate2D
      let user: UserApp
      
      // Initialize UserLocation from a User
      init(user: UserApp) {
          self.id = user.id
          self.name = user.name
          self.imageURL = user.profileImageUrl
          
          // Check if the user has a valid location (GeoPoint)
          if let geoPoint = user.location {
              // Extract latitude and longitude from the GeoPoint object
              self.coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
          } else {
              // If no location is available, provide a default coordinate (e.g., 0,0)
              self.coordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
          }
          
          self.user = user
      }
}
