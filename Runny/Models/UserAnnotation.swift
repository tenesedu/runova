import MapKit

class UserAnnotation: NSObject, MKAnnotation {
    let user: User
    var coordinate: CLLocationCoordinate2D
    var title: String?
    
    init(user: User) {
        self.user = user
        self.coordinate = CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)
        self.title = user.name
        super.init()
    }
} 