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
    private var preferencesWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Set the app to be an accessory app (menu bar only)
        NSApp.setActivationPolicy(.accessory)
        
        // Create the status item FIRST, directly in AppDelegate
        setupStatusItem()
        
        // Initialize the overlay manager
        overlayManager = ClipboardOverlayManager()
        overlayManager?.startHotkey(clipboardManager: clipboardManager)
        
        // DISABLES MENUBAR ICON
        // NSApplication.shared.windows.forEach { $0.close() }
        
    }
    
    // Move the status item setup to AppDelegate
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            
            // Try text instead of image first
            button.title = "📋"
            
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Clipboard", action: #selector(showOverlay), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Clear History", action: #selector(clearClipboardHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func showOverlay() {
        overlayManager?.toggleOverlay()
    }
    
    @objc func clearClipboardHistory() {
        clipboardManager.clearHistory()
    }
    
    @objc func showPreferences() {
        // If the window already exists, just bring it to the front.
        if let windowController = preferencesWindowController, windowController.window?.isVisible == true {
            windowController.window?.makeKeyAndOrderFront(nil)
            return
        }
        
        // Create the view and the manager for it
        let preferencesView = PreferencesView()
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200), // Increased size
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Clipboard Preferences"
        window.contentView = NSHostingView(rootView: preferencesView)
        
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        
        // Keep a strong reference to the window controller
        self.preferencesWindowController = windowController
    }
}
