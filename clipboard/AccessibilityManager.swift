import Cocoa
import ApplicationServices

class AccessibilityManager: ObservableObject {
    @Published var isGranted: Bool = false
    
    init() {
        checkPermission()
        
        // Monitor for permission changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(checkPermission),
            name: NSNotification.Name("com.apple.accessibility.api"),
            object: nil
        )
    }
    
    @objc func checkPermission() {
        // Check WITHOUT prompting
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        DispatchQueue.main.async {
            self.isGranted = trusted
        }
    }
    
    func requestPermission() {
        // Check WITH prompt
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        DispatchQueue.main.async {
            self.isGranted = trusted
        }
    }
    
    var isCurrentlyTrusted: Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
