//
//  ios_appApp.swift
//  ios_app
//
//  Created by I074917 on 17/12/25.
//

import SwiftUI
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@main
struct ios_appApp: App {
    
    init() {
        // Configure Google Sign-In on app launch
        #if canImport(GoogleSignIn)
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
            print("🔹 [App] Configuring Google Sign-In with ClientID: \(clientID)")
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        } else {
            print("❌ [App] GIDClientID not found in Info.plist")
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .onOpenURL { url in
                    // Handle Google Sign-In callback
                    #if canImport(GoogleSignIn)
                    GIDSignIn.sharedInstance.handle(url)
                    #endif
                }
        }
    }
}
