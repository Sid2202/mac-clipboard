//
//  AppDelegate.swift
//  clipboard
//
//  Created by Sidhanti Patil on 04/05/25.
//
import Cocoa
import SwiftUI
import KeyboardShortcuts
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private let clipboardManager = ClipboardManager()
    private var overlayManager: ClipboardOverlayManager?
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App is launching...")
        
        // Set the app to be an accessory app (menu bar only)
        NSApp.setActivationPolicy(.accessory)
        
        // Create the status item FIRST, directly in AppDelegate
        setupStatusItem()
        
        // Initialize the overlay manager
        overlayManager = ClipboardOverlayManager()
        overlayManager?.startHotkey(clipboardManager: clipboardManager)
        
        // DISABLES MENUBAR ICON
        // NSApplication.shared.windows.forEach { $0.close() }
        
        print("App launch complete")
    }
    
    // Move the status item setup to AppDelegate
    private func setupStatusItem() {
        print("Creating status item in AppDelegate...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            print("Button exists, setting up...")
            
            // Try text instead of image first
            button.title = "📋"
            
            print("Button title set to CL")
        } else {
            print("Failed to get button from status item")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Clipboard", action: #selector(showOverlay), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Clear History", action: #selector(clearClipboardHistory), keyEquivalent: ""))
        // menu.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        print("Menu assigned to status item in AppDelegate")
    }
    
    @objc func showOverlay() {
        overlayManager?.toggleOverlay()
    }
    
    @objc func clearClipboardHistory() {
        clipboardManager.clearHistory()
    }
    
    @objc func showPreferences() {
        let prefWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 150),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        let prefView = PreferencesView()
        prefWindow.contentView = NSHostingView(rootView: prefView)
        prefWindow.center()
        prefWindow.title = "Clipboard Preferences"
        prefWindow.makeKeyAndOrderFront(nil)
    }
}
