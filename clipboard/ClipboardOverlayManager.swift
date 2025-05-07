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
    private var statusItem: NSStatusItem?
    
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
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "📋"
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Clipboard", action: #selector(showOverlayFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func showOverlayFromMenu() {
        toggleOverlay()
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
            // Fix: Choose only one of these behaviors
            panel.collectionBehavior = [.canJoinAllSpaces, .transient]
            panel.ignoresMouseEvents = false
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            
            // Position near mouse cursor
            if let screen = NSScreen.main {
                let mouseLocation = NSEvent.mouseLocation
                let panelSize = CGSize(width: 300, height: min(30.0 * CGFloat(self.clipboardManager.history.count + 1), 300))
                let x = min(max(mouseLocation.x - panelSize.width/2, 0), screen.frame.width - panelSize.width)
                let y = min(max(mouseLocation.y - panelSize.height/2, 0), screen.frame.height - panelSize.height)
                panel.setFrame(NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height), display: true)
            }
            
            panel.makeKeyAndOrderFront(nil)
            panel.orderFrontRegardless()
            
            self.panel = panel
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
