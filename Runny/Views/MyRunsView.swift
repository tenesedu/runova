import SwiftUI

struct MyRunsView: View {
    @State private var runs: [Run] = [] // Assuming you have a Run model
    @State private var showingNewRun = false
    
    var body: some View {
        NavigationView {
            VStack {
                List(runs) { run in
                    HStack {
                        Text(run.title) // Access the title property
                            .foregroundColor(.black) // Set text color to black
                        Spacer()
                        Text("\(run.distance, specifier: "%.2f") km") // Format distance
                            .foregroundColor(.black) // Set text color to black
                    }
                }
                .navigationTitle("My Runs")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingNewRun = true }) {
                            Text("Add Run")
                                .foregroundColor(.black) // Set button text color to black
                        }
                    }
                }
                .sheet(isPresented: $showingNewRun) {
                    NewRunView() // Your view for adding a new run
                }
            }
            .background(Color.white) // Set background color to white for contrast
        }
    }
} 