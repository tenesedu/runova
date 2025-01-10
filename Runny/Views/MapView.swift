import SwiftUI
import FirebaseAuth
import MapKit
import FirebaseFirestore
import CoreLocation

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Custom Map with user location annotation
                CustomMapView(
                    region: $viewModel.region,
                    runners: viewModel.runners
                )
                .edgesIgnoringSafeArea(.top)
                
                VStack {
                    // Search Bar
                    SearchBarView(text: $searchText)
                        .padding()
                    
                    Spacer()
                    
                    // Location Button
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.centerOnUserLocation()
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                                .frame(width: 50, height: 50)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
                
                // Error Alert
                if let error = viewModel.locationError {
                    VStack {
                        Text(error)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(10)
                            .padding()
                        
                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true) // Hide navigation bar
        }
    }
}

// Custom Search Bar
struct SearchBarView: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search location", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

// Updated Runner Marker
struct RunnerMapMarker: View {
    let runner: RunnerLocation
    
    var body: some View {
        VStack(spacing: 4) {
            // Profile Image Circle
            AsyncImage(url: URL(string: runner.profileImageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .background(Circle().fill(Color.white))
            .shadow(radius: 3)
            
            // Name Label
            Text(runner.name)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 1)
            
            // Distance
            Text("\(runner.distance)km")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

// Update RunnerLocation struct to include profile image URL
struct RunnerLocation: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let distance: Int
    let profileImageUrl: String
}

// Update the fetchNearbyRunners function in MapViewModel
extension MapViewModel {
    func fetchNearbyRunners(retryCount: Int = 3) {
        guard let userLocation = locationManager?.location else { return }
        
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("isOnline", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching nearby runners: \(error.localizedDescription)")
                    if retryCount > 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self?.fetchNearbyRunners(retryCount: retryCount - 1)
                        }
                    } else {
                        self?.locationError = "Failed to fetch nearby runners. Please check your connection."
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.runners = documents.compactMap { document -> RunnerLocation? in
                    let data = document.data()
                    
                    // Skip the current user
                    if document.documentID == Auth.auth().currentUser?.uid {
                        return nil
                    }
                    
                    guard let geoPoint = data["location"] as? GeoPoint else {
                        return nil
                    }
                    
                    let runnerLocation = CLLocation(
                        latitude: geoPoint.latitude,
                        longitude: geoPoint.longitude
                    )
                    
                    // Only include runners within 10km
                    let distance = userLocation.distance(from: runnerLocation) / 1000
                    if distance > 10 { return nil }
                    
                    return RunnerLocation(
                        id: document.documentID,
                        name: data["name"] as? String ?? "Unknown Runner",
                        coordinate: CLLocationCoordinate2D(
                            latitude: geoPoint.latitude,
                            longitude: geoPoint.longitude
                        ),
                        distance: Int(distance),
                        profileImageUrl: data["profileImageUrl"] as? String ?? ""
                    )
                }
            }
    }
}

// Custom Map View with user location annotation
struct CustomMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let runners: [RunnerLocation]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        // Remove all annotations for testing
        mapView.removeAnnotations(mapView.annotations)
        
        // Add only user location for testing
        if let userLocation = mapView.userLocation.location {
            let userAnnotation = MKPointAnnotation()
            userAnnotation.coordinate = userLocation.coordinate
            userAnnotation.title = "You"
            mapView.addAnnotation(userAnnotation)
        }
        
        // Add runners annotations
        let annotations = runners.map { runner -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = runner.coordinate
            annotation.title = runner.name
            return annotation
        }
        mapView.addAnnotations(annotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        
        init(_ parent: CustomMapView) {
            self.parent = parent
        }
        
        // Customize user location annotation view if needed
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Customize as needed
            return nil
        }
    }
}

// Custom annotation for runners
class RunnerAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let runner: RunnerLocation
    
    init(runner: RunnerLocation) {
        self.coordinate = runner.coordinate
        self.runner = runner
    }
}

// Update MapViewModel to include current user's profile URL
class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var runners: [RunnerLocation] = []
    @Published var locationError: String?
    private var locationManager: CLLocationManager?
    @Published var currentUserProfileUrl: String?
    
    override init() {
        super.init()
        DispatchQueue.main.async {
            self.setupLocationManager()
            self.fetchCurrentUserProfile()
        }
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 10
        
        // Check current authorization status
        switch locationManager?.authorizationStatus {
        case .notDetermined:
            print("📍 Requesting location authorization...")
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("📍 Location access denied or restricted")
            locationError = "Please enable location access in Settings to see nearby runners"
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 Location access authorized")
            locationManager?.startUpdatingLocation()
        case .none:
            print("📍 No location manager available")
        @unknown default:
            break
        }
    }
    
    func checkLocationAuthorization() {
        guard let locationManager = locationManager else {
            print("📍 Location manager not initialized")
            return
        }
        
        print("📍 Checking location authorization...")
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("📍 Requesting location authorization...")
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("📍 Location access restricted")
            locationError = "Location access restricted"
        case .denied:
            print("📍 Location access denied")
            locationError = "Please enable location access in Settings to see nearby runners"
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 Location access authorized")
            locationError = nil
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("📍 User location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Only update if accuracy is good enough
        if location.horizontalAccuracy > 0 {
            locationError = nil
            withAnimation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
            updateUserLocationInFirestore(location: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 Location error: \(error.localizedDescription)")
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = "Location access denied. Please enable in Settings."
            case .locationUnknown:
                locationError = "Unable to determine location. Please try again."
            default:
                locationError = "Location error: \(error.localizedDescription)"
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("📍 Location authorization changed")
        checkLocationAuthorization()
    }
    
    private func updateUserLocationInFirestore(location: CLLocation) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "location": GeoPoint(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ),
            "isOnline": true,
            "lastUpdated": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            if let error = error {
                print("Error updating location: \(error.localizedDescription)")
                self?.locationError = "Error updating location: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchCurrentUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data(),
               let profileUrl = data["profileImageUrl"] as? String {
                DispatchQueue.main.async {
                    self?.currentUserProfileUrl = profileUrl
                }
            }
        }
    }
    
    func centerOnUserLocation() {
        guard let location = locationManager?.location else {
            locationError = "Unable to determine your location"
            print("📍 No location available")
            return
        }
        
        print("📍 Centering on user location: \(location.coordinate)")
        withAnimation {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
}
 
