import SwiftUI
import FirebaseAuth
import MapKit
import FirebaseFirestore
import CoreLocation

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var users: [UserApp] = []
    @State private var showingUserProfile = false
    @State private var selectedUser: UserApp?
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedResult: MKMapItem?
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedRange: Double = 25.0
    @State private var availableRanges = [10.0, 25.0, 50.0, 100.0]
    @State private var radarAnimationAmount = 1.0
    
    private var runnersInRange: [UserApp] {
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
            
            return distance <= (selectedRange * 1000) && isRecent
        }
        
        // Sort users by distance
        let sortedUsers = filteredUsers.sorted { user1, user2 in
            guard let location1 = user1.locationAsCLLocation(),
                  let location2 = user2.locationAsCLLocation() else {
                return false
            }
            
            let distance1 = currentLocation.distance(from: location1)
            let distance2 = currentLocation.distance(from: location2)
            
            return distance1 < distance2
        }
        
        print("Found \(sortedUsers.count) runners within \(selectedRange)km")
        return sortedUsers
    }
    
    private func isLocationRecent(user: UserApp) -> Bool {
        guard let lastUpdate = user.lastLocationUpdate else { return false }
        let hourAgo = Date().addingTimeInterval(-3600)
        return lastUpdate > hourAgo
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position) {
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
                
                ForEach(runnersInRange) { user in
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
            
            // Top controls overlay
            VStack(spacing: 0) {
                // Top controls container
                HStack(spacing: 0) {
                    // Range Selector
                    RangeSelector(selectedRange: $selectedRange, availableRanges: availableRanges)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Location Button
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
                    .padding(.trailing, 30)
                }
                .padding(.top, 8)
                .padding(.horizontal)
                .background(Color.clear)
                
                Spacer()
                
                // Runners panel at bottom
                RunnersPanel(
                    runnersInRange: runnersInRange,
                    locationManager: locationManager,
                    onUserSelected: { user in
                        selectedUser = user
                        showingUserProfile = true
                    },
                    selectedRange: selectedRange
                )
            }
            .background(
                NavigationLink(
                    destination: Group {
                        if let selectedUser = selectedUser {
                            RunnerDetailView(runner: Runner(user: selectedUser))
                        }
                    },
                    isActive: $showingUserProfile,
                    label: { EmptyView() }
                )
            )
        }
        .onAppear {
            locationManager.requestLocation()
            if users.isEmpty {
                startListeningToUsers()
            }
            
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                radarAnimationAmount = 2.0
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
            center: locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
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
                
                self.searchResults = response.mapItems.sorted { item1, item2 in
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
    
    private var nearbyUsers: [UserApp] {
        guard let currentLocation = locationManager.location else { return users }
        
        return users.sorted { user1, user2 in
            guard let location1 = user1.locationAsCLLocation(),
                  let location2 = user2.locationAsCLLocation() else {
                return false
            }
            
            return currentLocation.distance(from: location1) < currentLocation.distance(from: location2)
        }
    }
    
    private func startListeningToUsers() {
        print("Starting to listen for nearby users...")
        let db = Firestore.firestore()
        
        db.collection("users")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching users (MapView): \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                self.users = documents.compactMap { document in
                    let data = document.data()
                    let user = UserApp(id: document.documentID, data: data)
                    return user
                }
                
                // Print user details with proper optional handling
                for user in self.users {
                    print("User: \(user.name)")
                    if let lastUpdate = user.lastLocationUpdate {
                        print("Last location update: \(lastUpdate)")
                    } else {
                        print("No location update available")
                    }
                    if let location = user.location {
                        print("Location: lat: \(location.latitude), lon: \(location.longitude)")
                    } else {
                        print("No location available")
                    }
                }
                print("Fetched \(self.users.count) total users")
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
    
   
    
    struct RangeSelector: View {
        @Binding var selectedRange: Double
        let availableRanges: [Double]
        
        var body: some View {
            HStack {
                ForEach(availableRanges, id: \.self) { range in
                    Button(action: {
                        withAnimation {
                            selectedRange = range
                        }
                    }) {
                        Text("\(Int(range))km")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(selectedRange == range ? Color.blue : Color.white)
                            )
                            .foregroundColor(selectedRange == range ? .white : .blue)
                    }
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .shadow(radius: 2)
        }
    }
}



struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
