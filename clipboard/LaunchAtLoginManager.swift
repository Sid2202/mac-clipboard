//
//  LaunchAtLoginManager.swift
//  clipboard
//
//  Created by Sidhanti Patil on 20/09/25.
//


import Foundation
import ServiceManagement
import Combine

class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool = false {
        didSet {
            // This `didSet` will automatically update the system setting when the toggle is flipped.
            if oldValue != isEnabled {
                updateLaunchAtLogin(enabled: isEnabled)
            }
        }
    }

    init() {
        // When the manager is created, check the current status of the login item.
        self.isEnabled = (SMAppService.mainApp.status == .enabled)
    }

    private func updateLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                // Register the app to launch at login.
                if SMAppService.mainApp.status == .notFound {
                    try SMAppService.mainApp.register()
                    print("Successfully registered app for launch at login.")
                }
            } else {
                // Unregister the app.
                try SMAppService.mainApp.unregister()
                print("Successfully unregistered app from launch at login.")
            }
        } catch {
            // If something goes wrong, print an error and revert the UI state.
            print("Failed to update launch at login setting: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isEnabled = !enabled
            }
        }
    }
}