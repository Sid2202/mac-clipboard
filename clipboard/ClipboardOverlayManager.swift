import Cocoa
import SwiftUI
import KeyboardShortcuts
import UserNotifications

extension KeyboardShortcuts.Name {
    static let showClipboardOverlay = Self("showClipboardOverlay")
}

// Add this custom panel class
class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}

class ClipboardOverlayManager: NSObject {
    static var shared: ClipboardOverlayManager?
    private var panel: NSPanel?
    private var clipboardManager: ClipboardManager!
    private var eventMonitor: Any?
    private let accessibilityManager = AccessibilityManager()
    
    override init() {
        super.init()
        ClipboardOverlayManager.shared = self
    }
    
    func startHotkey(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
        
        // Set default shortcut (Cmd+Shift+V)
        KeyboardShortcuts.setShortcut(.init(.v, modifiers: [.command, .shift]), for: .showClipboardOverlay)
        
        // Register the callback
        KeyboardShortcuts.onKeyDown(for: .showClipboardOverlay) { [weak self] in
            self?.toggleOverlay()
        }
    }
    func toggleOverlay() {
        DispatchQueue.main.async {
            if let panel = self.panel, panel.isVisible {
                self.hideOverlay()
                return
            }
            
            self.showOverlay()
        }
    }
    private func hideOverlay() {
        // Remove event monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        panel?.orderOut(nil)
    }
    
    @objc private func showOverlayFromMenu() {
        toggleOverlay()
    }
    
    @objc private func clearClipboardHistory() {
        clipboardManager.clearHistory()
    }
    
    @objc private func showPreferences() {
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
    
    func completePaste(with item: ClipboardItem) {
        // 1. Set the system clipboard content
        self.clipboardManager.setClipboard(item)

        // 2. Hide the UI panel immediately
        self.hideOverlay()

        // 3. RELINQUISH FOCUS IMMEDIATELY
        NSApp.hide(nil)
        
        // 4. TRIGGER THE PASTE AFTER A BUFFER
        // We give the target app (Chrome, VS Code, etc.) 150ms to become "Key" again.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // Attempt to simulate paste. In App Sandbox, this often fails silently or is blocked.
            // We can't easily detect if CGEvent was blocked, so we assume best effort.
            // However, we can check if we have accessibility permissions first.
            
            if self.accessibilityManager.isGranted {
                 self.clipboardManager.simulatePaste()
            } else {
                 // Fallback: Notify user to paste manually
                 // Since we are hidden, we might want to show a notification or just rely on the user knowing.
                 // For now, let's trust the user knows to paste if nothing happens, or we could send a notification.
                 self.sendPasteNotification()
            }
        }
    }
    
    private func sendPasteNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Copied to Clipboard"
        content.body = "Press ⌘V to paste."
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showOverlay() {
//        let view = ClipboardOverlayView(clipboardManager: self.clipboardManager) {
//            self.hideOverlay()
//        }
        let view = ClipboardOverlayView(
            clipboardManager: self.clipboardManager,
            onDismiss: { [weak self] in
                // Handle simple dismissal (like clicking outside)
                self?.hideOverlay()
                NSApp.hide(nil)
            },
            onSelectionAndDismiss: { [weak self] selectedItem in
                // Handle item selection
                guard let self = self else { return }
                if let item = selectedItem {
                    self.completePaste(with: item)
                } else {
                    self.hideOverlay()
                    NSApp.hide(nil)
                }
            }
        )

        let hosting = NSHostingController(rootView: view)
        
        // FIXED: Create panel with proper initializer
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 400),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        
        panel.contentViewController = hosting
        
        // CRITICAL FIXES for keyboard input
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        
        // Position panel at the cursor location
        if let screen = NSScreen.main {
            let mouseLocation = NSEvent.mouseLocation
            
            // Calculate height based on number of items (with min/max constraints)
            let itemHeight: CGFloat = 45
            let headerHeight: CGFloat = 40
            let itemCount = CGFloat(self.clipboardManager.items.count)
            let calculatedHeight = min(400, max(100, itemCount * itemHeight + headerHeight))
            
            let panelSize = CGSize(width: 360, height: calculatedHeight)
            
            // Adjust position to ensure panel is fully visible on screen
            let x = min(max(mouseLocation.x - panelSize.width/2, screen.visibleFrame.minX),
                       screen.visibleFrame.maxX - panelSize.width)
            
            // Position above cursor if there's room, otherwise below
            var y = mouseLocation.y + 10
            if y + panelSize.height > screen.visibleFrame.maxY {
                y = mouseLocation.y - panelSize.height - 10
            }
            
            panel.setFrame(NSRect(origin: CGPoint(x: x, y: y), size: panelSize), display: true)
        }
        
        // Make the panel key and front
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        
        // Activate the app to ensure keyboard events work
        NSApp.activate(ignoringOtherApps: true)
        
        self.panel = panel
        
        // Setup event monitor for dismissing on click outside
        self.setupEventMonitor()
    }
    
    private func setupEventMonitor() {
        // Remove existing monitor if any
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // Add event monitor to dismiss overlay when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return }
            
            // Get the click location
            let clickLocation = event.locationInWindow
            
            // Check if click is outside the panel
            if !panel.frame.contains(clickLocation) {
                self.hideOverlay()
            }
        }
    }
    
    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

struct PreferencesView: View {
    // Create a state object for our manager.
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()
    @StateObject private var accessibilityManager = AccessibilityManager()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            
            // Section for General Settings
            VStack(alignment: .leading) {
                Text("General")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                // Use the manager's isEnabled property for the toggle.
                Toggle("Launch at Login", isOn: $launchAtLoginManager.isEnabled)
                    .toggleStyle(.switch) // A nicer looking toggle
            }
            
            // Section for Keyboard Shortcut
            VStack(alignment: .leading) {
                Text("Keyboard Shortcut")
                    .font(.headline)
                
                KeyboardShortcuts.Recorder(for: .showClipboardOverlay)
            }
            
            VStack(alignment: .leading) {
                Text("Permissions")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                HStack {
                    Text("Auto-Paste (Accessibility)")
                    Spacer()
                    if accessibilityManager.isGranted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Allowed")
                        }
                        .foregroundColor(.green)
                    } else {
                        Button("Grant Access...") {
                            accessibilityManager.requestPermission()
                        }
                    }
                }
                .padding(.top, 5)
            }
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 250)
        .onAppear {
            accessibilityManager.checkPermission()
        }
    }
}
