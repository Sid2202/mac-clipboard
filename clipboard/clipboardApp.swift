//
//  clipboardApp.swift
//  clipboard
//
//  Created by Sidhanti Patil on 04/05/25.
//

import SwiftUI

@main
struct clipboardApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    let overlayManager = ClipboardOverlayManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
//                EmptyView()
                .onAppear {
                    overlayManager.startHotkey(clipboardManager: clipboardManager)
                    print("Clipboard app initialized. Press Cmd+Shift+V to show overlay")
                }
                .environmentObject(clipboardManager)
        }
        .commands{
            
        }
    }
}
