import Foundation
import AppKit
import Carbon.HIToolbox

class ClipboardManager: ObservableObject{
    @Published var history: [String] = []
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let maxHistoryItems = 20
    
    init() {
        lastChangeCount = pasteboard.changeCount
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true){ [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            // Try to get text content
            if let newText = pasteboard.string(forType: .string),
               !newText.isEmpty,
               !history.contains(newText) {
                
                DispatchQueue.main.async {
                    self.history.insert(newText, at: 0)
                    if self.history.count > self.maxHistoryItems {
                        self.history.removeLast()
                    }
                }
            }
        }
    }
    
    func setClipboard(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }
    
    func simulatePaste() {
        // First, set the clipboard content (already done in the button action)
        
        // Give a slight delay to ensure the clipboard content is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Create a keyboard event source
            guard let source = CGEventSource(stateID: .combinedSessionState) else {
                print("Failed to create event source")
                return
            }
            
            // Create the cmd+v down event
            guard let cmdVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) else {
                print("Failed to create key down event")
                return
            }
            cmdVDown.flags = .maskCommand
            
            // Create the cmd+v up event
            guard let cmdVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
                print("Failed to create key up event")
                return
            }
            cmdVUp.flags = .maskCommand
            
            // Post the events to simulate cmd+v
            cmdVDown.post(tap: .cgAnnotatedSessionEventTap)
            cmdVUp.post(tap: .cgAnnotatedSessionEventTap)
            
            print("Paste events sent")
        }
    }
    
    private func pasteUsingCGEvent() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true) // 'V' key
        cmdDown?.flags = .maskCommand
        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
        cmdUp?.flags = .maskCommand
        
        cmdDown?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }
    
    private func pasteUsingAppleScript() {
        let script = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript paste failed: \(error)")
            }
        }
    }
    
    func clearHistory() {
        history.removeAll()
    }
}
