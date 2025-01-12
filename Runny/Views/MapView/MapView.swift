import SwiftUI
import FirebaseAuth
import MapKit
import FirebaseFirestore
import CoreLocation

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion()
    @State private var users: [User] = []
    @State private var showingUserProfile = false
    @State private var selectedUser: User?
    
    private var runnersWithin25km: [User] {
        guard let currentLocation = locationManager.location else { return [] }
        return users.filter { user in
            let userLocation = CLLocation(latitude: user.latitude, longitude: user.longitude)
            return currentLocation.distance(from: userLocation) <= 25000 // 25km in meters
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: users) { user in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: user.latitude,
                    longitude: user.longitude
                )) {
                    UserMapMarker(user: user) {
                        selectedUser = user
                        showingUserProfile = true
                    }
                }
            }
            
            VStack(spacing: 0) {
                // Title showing nearby runners count
                HStack {
                    Text("\(runnersWithin25km.count) Runners Nearby")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    Spacer()
                }
                
                // Nearby Runners Carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(nearbyUsers) { user in
                            NearbyRunnerCard(user: user) {
                                selectedUser = user
                                showingUserProfile = true
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .edgesIgnoringSafeArea(.bottom)
            )
            .frame(height: 180) // Reduced height for smaller cards
        }
        .sheet(isPresented: $showingUserProfile) {
            if let user = selectedUser {
                NavigationView {
                    ProfileView(userId: user.id)
                }
            }
        }
        .onAppear {
            setupInitialRegion()
            startListeningToUsers()
        }
    }
    
    // Computed property to sort users by distance
    private var nearbyUsers: [User] {
        guard let currentLocation = locationManager.location else { return users }
        
        return users.sorted { user1, user2 in
            let location1 = CLLocation(latitude: user1.latitude, longitude: user1.longitude)
            let location2 = CLLocation(latitude: user2.latitude, longitude: user2.longitude)
            
            return currentLocation.distance(from: location1) < currentLocation.distance(from: location2)
        }
    }
    
    private func setupInitialRegion() {
        if let location = locationManager.location {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
    
    private func startListeningToUsers() {
        let db = Firestore.firestore()
        // Only fetch users that have updated their location in the last hour
        let hourAgo = Date().addingTimeInterval(-3600)
        
        db.collection("users")
            .whereField("lastLocationUpdate", isGreaterThan: Timestamp(date: hourAgo))
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching users: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                users = documents.map { User(id: $0.documentID, data: $0.data()) }
            }
    }
}

struct UserMapMarker: View {
    let user: User
    let action: () -> Void
    
    private var isCurrentUser: Bool {
        user.id == Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        Button(action: action) {
            VStack {
                AsyncImage(url: URL(string: user.profileImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .shadow(radius: 3)
                
                Text(isCurrentUser ? "You" : user.name)
                    .font(.caption)
                    .foregroundColor(.black)
                    .padding(4)
                    .background(Color.white)
                    .cornerRadius(4)
                    .shadow(radius: 1)
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        updateUserLocation(location)
    }
    
    private func updateUserLocation(_ location: CLLocation) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        let locationData: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "lastLocationUpdate": Timestamp(date: Date())
        ]
        
        db.collection("users").document(userId).updateData(locationData) { error in
            if let error = error {
                print("Error updating location: \(error.localizedDescription)")
            }
        }
    }
}

// Add this new view for the carousel cards
struct NearbyRunnerCard: View {
    let user: User
    let action: () -> Void
    @State private var profileImage: UIImage?
    @State private var distance: String = ""
    @StateObject private var locationManager = LocationManager()
    @Environment(\.colorScheme) var colorScheme
    
    private var isCurrentUser: Bool {
        user.id == Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                // Profile Image Section
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 150) // Smaller card size
                        .clipped()
                } else {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 150) // Smaller card size
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40) // Smaller icon
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
                
                // Info Overlay
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(isCurrentUser ? "You" : user.name)
                            .font(.system(size: 14, weight: .semibold)) // Smaller font
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(distance)
                            .font(.system(size: 10)) // Smaller font
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 10)) // Smaller icon
                        Text("Nearby")
                            .font(.system(size: 10)) // Smaller font
                            .foregroundColor(.white)
                    }
                }
                .padding(6) // Smaller padding
                .background(
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.clear, .black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                )
            }
            .frame(width: 120, height: 150) // Smaller card size
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadProfileImage()
            calculateDistance()
        }
    }
    
    private func loadProfileImage() {
        guard let url = URL(string: user.profileImageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = image
                }
            }
        }.resume()
    }
    
    private func calculateDistance() {
        guard let currentLocation = locationManager.location else { return }
        let userLocation = CLLocation(latitude: user.latitude, longitude: user.longitude)
        let distanceInMeters = currentLocation.distance(from: userLocation)
        
        if distanceInMeters < 1000 {
            distance = String(format: "%.0fm", distanceInMeters)
        } else {
            let distanceInKm = distanceInMeters / 1000
            distance = String(format: "%.1fkm", distanceInKm)
        }
    }
}
 
