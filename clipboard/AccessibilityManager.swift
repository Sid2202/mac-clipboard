//
//  AccessibilityManager.swift
//  clipboard
//
//  Created by Sidhanti Patil on 23/09/25.
//


import Foundation
import AppKit
import Combine

class AccessibilityManager: ObservableObject {
    // This property will be true if the user has granted permission.
    @Published var isGranted: Bool = false

    init() {
        // Check the permission status as soon as the manager is created.
        checkPermission()
    }

    /// Checks the current accessibility permission status and updates the `isGranted` property.
    func checkPermission() {
        // This is the legacy API to check for permissions.
        // We pass `false` to `kAXTrustedCheckOptionPrompt` so it only checks the status
        // without showing the system's default (and less friendly) prompt.
        let options: [String: Bool] = ["AXTrustedCheckOptionPrompt": false]
        let currentStatus = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Update our published property on the main thread if the status has changed.
        if self.isGranted != currentStatus {
            DispatchQueue.main.async {
                self.isGranted = currentStatus
            }
        }
    }

    func requestPermission() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
