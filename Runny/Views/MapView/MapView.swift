import SwiftUI
import FirebaseAuth
import MapKit
import FirebaseFirestore
import CoreLocation

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var users: [User] = []
    @State private var showingUserProfile = false
    @State private var selectedUser: User?
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedResult: MKMapItem?
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    private var runnersWithin25km: [User] {
        guard let currentLocation = locationManager.location else {
            print("No location available")
            return []
        }
        
        let filteredUsers = users.filter { user in
            guard let userLocation = user.locationAsCLLocation(),
                  user.id != Auth.auth().currentUser?.uid else {
                return false
            }
            
            let distance = currentLocation.distance(from: userLocation)
            let isRecent = isLocationRecent(user: user)
            
            return distance <= 25000 && isRecent // 25km radius and recent location
        }
        
        print("Found \(filteredUsers.count) runners within 25km")
        return filteredUsers
    }
    
    private func isLocationRecent(user: User) -> Bool {
        guard let lastUpdate = user.lastLocationUpdate else { return false }
        let hourAgo = Date().addingTimeInterval(-3600) // 1 hour ago
        return lastUpdate > hourAgo
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position) {
                // Show current user location with custom marker
                if let location = locationManager.location,
                   let currentUserId = Auth.auth().currentUser?.uid,
                   let currentUser = users.first(where: { $0.id == currentUserId }) {
                    Annotation("", coordinate: location.coordinate) {
                        UserMapMarker(user: currentUser) {
                            selectedUser = currentUser
                            showingUserProfile = true
                        }
                    }
                }
                
                // Show other users
                ForEach(runnersWithin25km) { user in
                    if let userLocation = user.locationAsCLLocation(),
                       user.id != Auth.auth().currentUser?.uid {
                        Annotation("", coordinate: userLocation.coordinate) {
                            UserMapMarker(user: user) {
                                selectedUser = user
                                showingUserProfile = true
                            }
                        }
                    }
                }
                
                // Show selected search result pin
                if let selectedResult = selectedResult {
                    Annotation("Selected Location", coordinate: selectedResult.placemark.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                }
            }
            .mapStyle(.standard(showsTraffic: false))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()
            
            // Location Button - Top Right
            VStack {
                Button(action: {
                    if let location = locationManager.location {
                        withAnimation {
                            position = .region(MKCoordinateRegion(
                                center: location.coordinate,
                                span: MKCoordinateSpan(
                                    latitudeDelta: 0.005,
                                    longitudeDelta: 0.005
                                )
                            ))
                        }
                    } else {
                        locationManager.requestLocation()
                    }
                }) {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44)
                .padding(.trailing, 16)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Bottom runners panel
            VStack {
                Spacer()
                RunnersPanel(runnersWithin25km: runnersWithin25km) { user in
                    selectedUser = user
                    showingUserProfile = true
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
        
            locationManager.requestLocation()
            if users.isEmpty {
                startListeningToUsers()
            }
        }
        .sheet(item: $selectedUser) { user in
           
                NavigationView {
                    RunnerDetailView(runner: Runner(user: user))
                        .navigationBarItems(trailing: Button("Done") {
                            showingUserProfile = false
                            selectedUser = nil
                        })
                }
            
        }
        .alert("Location Access Required", 
               isPresented: .constant(!locationManager.isLocationEnabled && locationManager.authorizationStatus != .notDetermined)) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable location access in Settings to see nearby runners.")
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { 
            searchResults = []
            return 
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = MKCoordinateRegion(
            center: locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038), // Madrid center as default
            latitudinalMeters: 50000,
            longitudinalMeters: 50000
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Search error: \(error.localizedDescription)")
                    return
                }
                
                guard let response = response else { 
                    self.searchResults = []
                    return 
                }
                
                // Simplify results sorting
                self.searchResults = response.mapItems.sorted { item1, item2 in
                    // Get full addresses
                    let address1 = [
                        item1.name,
                        item1.placemark.thoroughfare,
                        item1.placemark.locality
                    ].compactMap { $0 }.joined(separator: ", ")
                    
                    let address2 = [
                        item2.name,
                        item2.placemark.thoroughfare,
                        item2.placemark.locality
                    ].compactMap { $0 }.joined(separator: ", ")
                    
                    // Simple string matching
                    return address1.localizedStandardContains(self.searchText)
                }
            }
        }
    }
    
    private func selectSearchResult(_ result: MKMapItem) {
        selectedResult = result
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: result.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
        searchText = ""
        searchResults = []
    }
    
    // Computed property to sort users by distance
    private var nearbyUsers: [User] {
        guard let currentLocation = locationManager.location else { return users }
        
        return users.sorted { user1, user2 in
            guard let location1 = user1.locationAsCLLocation(),
                  let location2 = user2.locationAsCLLocation() else {
                return false
            }
            
            // Compare the distances from the current location
            return currentLocation.distance(from: location1) < currentLocation.distance(from: location2)
        }
    }
    
    private func startListeningToUsers() {
        print("Starting to listen for nearby users...")
        let db = Firestore.firestore()
        
        // Remove the time filter initially to see if we get any users
        db.collection("users")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching users: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                self.users = documents.compactMap { document in
                    let data = document.data()
                    let user = User(id: document.documentID, data: data)
        
                    return user
                }
                for user in self.users {
                    print(user.name)
                    print(user.lastLocationUpdate)
                    print(user.location)
                }
                print("Fetched \(self.users.count) total users")
                
            }
    }
    
    struct UserMapMarker: View {
        let user: User
        let action: () -> Void
        @State private var profileImage: UIImage?
        
        var isCurrentUser: Bool {
            user.id == Auth.auth().currentUser?.uid
        }
        
        var body: some View {
            VStack(spacing: 4) {
                // Profile Image
                Group {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isCurrentUser ? Color.blue : Color.white, lineWidth: 3)
                )
                .shadow(radius: 3)
                
                // Name Label
                Text(isCurrentUser ? "You" : user.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(radius: 1)
                    )
            }
            .contentShape(Rectangle()) // Makes the entire area tappable
            .onTapGesture {
                action()
            }
            .onAppear {
                loadProfileImage()
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
    }
    
    struct SearchBarMap: View {
        @Binding var text: String
        let onSubmit: () -> Void
        
        var body: some View {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search address...", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .submitLabel(.search)
                    .onSubmit(onSubmit)
                
                if !text.isEmpty {
                    Button(action: { 
                        text = ""
                        onSubmit()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 2)
        }
    }
    
    struct SearchResultRow: View {
        let result: MKMapItem
        let action: () -> Void
        
        var formattedAddress: String {
            [
                result.placemark.thoroughfare,
                result.placemark.subThoroughfare,
                result.placemark.locality,
                result.placemark.subLocality
            ].compactMap { $0 }.joined(separator: ", ")
        }
        
        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name ?? "")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(formattedAddress)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }
        }
    }
    
    struct RunnersPanel: View {
        let runnersWithin25km: [User]
        let onUserSelected: (User) -> Void
        @State private var isExpanded = false
        
        var body: some View {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("\(runnersWithin25km.count) Runners Nearby")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !runnersWithin25km.isEmpty {
                        Button(action: {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                // Content
                if runnersWithin25km.isEmpty {
                    HStack {
                        Spacer()
                        Text("No runners in your area")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(runnersWithin25km) { user in
                                NearbyRunnerCard(user: user, isExpanded: isExpanded) {
                                    onUserSelected(user)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
            )
            .frame(height: runnersWithin25km.isEmpty ? 160 : (isExpanded ? 340 : 180)) // Increased minimum height
        }
    }
    
    struct NearbyRunnerCard: View {
        let user: User
        let isExpanded: Bool
        let action: () -> Void
        @State private var profileImage: UIImage?
        @State private var distance: String = ""
        @StateObject private var locationManager = LocationManager()
        
        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 8) {
                    // Profile Image with overlapped distance
                    ZStack(alignment: .topLeading) {
                        // Profile Image
                        Group {
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .frame(width: 120, height: isExpanded ? 140 : 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Distance Badge
                        if !distance.isEmpty {
                            Text(distance + " away")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(8)
                        }
                    }
                    
                    // Runner Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)
                        
                        if isExpanded {
                            Text(user.city)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(width: 120)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear {
                loadProfileImage()
                calculateDistance()
            }
        }
        
        private func loadProfileImage() {
            guard let url = URL(string: user.profileImageUrl) else { return }
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.profileImage = image
                    }
                }
            }.resume()
        }
        
        private func calculateDistance() {
            if let currentLocation = locationManager.location,
               let userLocation = user.locationAsCLLocation() {
                let distanceInMeters = currentLocation.distance(from: userLocation)
                distance = String(format: "%.1f km", distanceInMeters / 1000)
            }
        }
    }
}
