//
//  ClipboardManager.swift
//  clipboard
//
//  Created by Sidhanti Patil on 04/05/25.
//

import Foundation
import AppKit
import Carbon.HIToolbox

class ClipboardManager: ObservableObject{
    @Published var history: [String] = []
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    
    init() {
        lastChangeCount = pasteboard.changeCount
        startMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true){ _ in
            self.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            if let newText = pasteboard.string(forType: .string), !history.contains(newText) {
                
                DispatchQueue.main.async {
                    self.history.insert(newText, at: 0)
                    if self.history.count > 10 {
                        self.history.removeLast()
                    }
                }
            }
        }
    }
    
    func setClipboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    

    func simulatePaste() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true) // 'V'
        cmdDown?.flags = .maskCommand
        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
        cmdUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }

}
