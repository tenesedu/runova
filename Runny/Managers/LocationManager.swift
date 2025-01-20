import Foundation
import CoreLocation
import Combine
import FirebaseFirestore
import FirebaseAuth

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var lastError: Error?
    @Published var isLocationEnabled: Bool = false
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.activityType = .fitness
        
        // Check current authorization status
        checkLocationAuthorization()
    }
    
    private func checkLocationAuthorization() {
        print("Checking location authorization status: \(locationManager.authorizationStatus.rawValue)")
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location authorization granted")
            isLocationEnabled = true
            locationManager.startUpdatingLocation()
            // Force an immediate location update
            locationManager.requestLocation()
            
        case .denied, .restricted:
            print("Location authorization denied or restricted")
            isLocationEnabled = false
            lastError = NSError(domain: "LocationManager", 
                              code: 1, 
                              userInfo: [NSLocalizedDescriptionKey: "Location access denied"])
            
        case .notDetermined:
            print("Location authorization not determined")
            isLocationEnabled = false
            locationManager.requestWhenInUseAuthorization()
            
        @unknown default:
            break
        }
    }
    
    func requestLocation() {
        print("Requesting location update...")
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse ||
                  locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("Received location update: \(location.coordinate)")
        
        DispatchQueue.main.async {
            self.location = location
            self.updateUserLocationInFirestore(location: location)
        }
    }
    
    private func updateUserLocationInFirestore(location: CLLocation) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "location": GeoPoint(latitude: location.coordinate.latitude,
                               longitude: location.coordinate.longitude),
            "lastLocationUpdate": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userId).updateData(userData) { error in
            if let error = error {
                print("Error updating location in Firestore: \(error.localizedDescription)")
            } else {
                print("Successfully updated user location in Firestore")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        self.lastError = error
        
        // Try to recover from the error
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                checkLocationAuthorization()
            case .locationUnknown:
                // Wait for next update
                break
            default:
                // For other errors, stop and restart updates
                locationManager.stopUpdatingLocation()
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Location authorization changed to: \(manager.authorizationStatus.rawValue)")
        authorizationStatus = manager.authorizationStatus
        checkLocationAuthorization()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        print("Stopped location updates")
    }
}
