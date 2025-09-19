import Cocoa
import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let showClipboardOverlay = Self("showClipboardOverlay")
}

class ClipboardOverlayManager: NSObject {
    static var shared: ClipboardOverlayManager?
    private var panel: NSPanel?
    private var clipboardManager: ClipboardManager!
//    private var statusItem: NSStatusItem?
    
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
        
        // Also add a menu bar item as a fallback
//        setupStatusItem()
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
    
    func toggleOverlay() {
        DispatchQueue.main.async {
            if let panel = self.panel, panel.isVisible {
                panel.orderOut(nil)
                return
            }
            
            let view = ClipboardOverlayView(clipboardManager: self.clipboardManager) {
                self.panel?.orderOut(nil)
            }
            let hosting = NSHostingController(rootView: view)
            
            let panel = NSPanel(contentViewController: hosting)
            panel.styleMask = [.nonactivatingPanel, .hudWindow, .utilityWindow]
            panel.level = .floating
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.collectionBehavior = [.canJoinAllSpaces, .transient]
            panel.ignoresMouseEvents = false
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            
            // Position panel at the cursor location
            if let screen = NSScreen.main {
                let mouseLocation = NSEvent.mouseLocation
                
                // Calculate height based on number of items (with min/max constraints)
                let itemHeight: CGFloat = 45
                let headerHeight: CGFloat = 40
                let itemCount = CGFloat(self.clipboardManager.items.count)
                let calculatedHeight = min(400, max(100, itemCount * itemHeight + headerHeight))
                
                let panelSize = CGSize(width: 320, height: calculatedHeight)
                
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
            
            panel.makeKeyAndOrderFront(nil)
            panel.orderFrontRegardless()
            
            self.panel = panel
            
            // Add event monitor to dismiss overlay when clicking outside
            NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                if let panel = self?.panel, panel.isVisible {
                    self?.panel?.orderOut(nil)
                }
            }
        }
    }
}

struct PreferencesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Keyboard Shortcut")
                .font(.headline)
            
            KeyboardShortcuts.Recorder(for: .showClipboardOverlay)
                .padding()
            
            Spacer()
        }
        .padding()
        .frame(width: 300, height: 150)
    }
}
