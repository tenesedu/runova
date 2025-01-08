//
//  RunnyApp.swift
//  Runny
//
//  Created by Joaquín Tenés on 7/1/25.
//

import SwiftUI
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        return true
    }
}

@main
struct RunnyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
 
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
