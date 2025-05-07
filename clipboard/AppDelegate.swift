//
//  AppDelegate.swift
//  clipboard
//
//  Created by Sidhanti Patil on 04/05/25.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var clipboardManager: ClipboardManager?
    var overlayManager: ClipboardOverlayManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        clipboardManager = ClipboardManager()
        overlayManager = ClipboardOverlayManager()
        overlayManager?.startHotkey(clipboardManager: clipboardManager!)
        
        setupStatusItem()
        
        print("App delegate initialized")
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "📋"
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Clipboard", action: #selector(showOverlay), keyEquivalent: "v"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func showOverlay() {
        overlayManager?.toggleOverlay()
    }
}
