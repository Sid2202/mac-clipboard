import SwiftUI
import AppKit

struct ClipboardOverlayView: View {
    var clipboardManager: ClipboardManager
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(clipboardManager.history.indices, id: \.self) { index in
                let item = clipboardManager.history[index]
                
                Button(action: {
                    // Copy to clipboard
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(item, forType: .string)
                    
                    // Attempt to paste using AX API
                    pasteToFrontmostApp()
                    
                    // Close the overlay
                    onDismiss()
                }) {
                    HStack {
                        Text(truncateText(item, maxLength: 50))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ClipboardItemButtonStyle(isSelected: index == 0))
                
                if index < clipboardManager.history.count - 1 {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    private func truncateText(_ text: String, maxLength: Int) -> String {
        return text.count > maxLength ?
            String(text.prefix(maxLength)) + "..." :
            text
    }
    
    private func pasteToFrontmostApp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Get the frontmost application
            if let frontmostApp = NSWorkspace.shared.frontmostApplication {
                let targetAppName = frontmostApp.localizedName ?? "the frontmost application"
                
                let script = """
                tell application "\(targetAppName)"
                    activate
                    tell application "System Events"
                        keystroke "v" using command down
                    end tell
                end tell
                """
                
                var error: NSDictionary?
                if let scriptObject = NSAppleScript(source: script) {
                    scriptObject.executeAndReturnError(&error)
                    if let error = error {
                        print("Error executing AppleScript: \(error)")
                        
                        // Fallback to a more generic approach
                        fallbackPaste()
                    }
                }
            } else {
                fallbackPaste()
            }
        }
    }
    
    private func fallbackPaste() {
        // This is a fallback method that tries an alternative approach
        let script = """
        tell application "System Events"
            keystroke "v" using command down
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("Fallback paste failed: \(error)")
            }
        }
    }
}

// Custom button style for clipboard items
struct ClipboardItemButtonStyle: ButtonStyle {
    var isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Group {
                    if configuration.isPressed {
                        Color.accentColor.opacity(0.3)
                    } else if isSelected {
                        Color.accentColor.opacity(0.1)
                    } else {
                        Color.clear
                    }
                }
            )
    }
}

