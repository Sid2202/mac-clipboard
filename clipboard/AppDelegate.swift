//
//  AppDelegate.swift
//  clipboard
//
//  Created by Sidhanti Patil on 04/05/25.
//
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var clipboardManager = ClipboardManager()
    var overlayManager: ClipboardOverlayManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set the app to be an accessory app (menu bar only)
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Initialize the clipboard manager
        clipboardManager = ClipboardManager()
        
        // Initialize the overlay manager
        overlayManager = ClipboardOverlayManager()
        overlayManager?.startHotkey(clipboardManager: clipboardManager)
        
        // Close any open windows (this handles any automatically created windows)
        NSApplication.shared.windows.forEach { $0.close() }
        
        print("Clipboard manager initialized. Press Cmd+Shift+V to show overlay")
    }
}
