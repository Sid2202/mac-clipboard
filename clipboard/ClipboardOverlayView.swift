import SwiftUI
import AppKit

struct ClipboardOverlayView: View {
    var clipboardManager: ClipboardManager
    var onDismiss: () -> Void
    @State private var hoveredIndex: Int? = nil
    @State private var selectedItem: String? = nil
    @State private var showCopiedIndicator = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with instructions
            VStack(spacing: 4) {
                HStack {
                    Text("Clipboard")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Instructions for users
                Text("Click an item to copy, then paste manually with ⌘V")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(colorScheme == .dark ? NSColor.windowBackgroundColor : NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            if clipboardManager.history.isEmpty {
                Text("Clipboard history is empty")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(clipboardManager.history.indices, id: \.self) { index in
                            let item = clipboardManager.history[index]
                            clipboardItemView(item, index: index)
                        }
                    }
                }
            }
            
            // Optional: "Copy & Close" button at the bottom
            if selectedItem != nil {
                Divider()
                Button(action: {
                    onDismiss()
                }) {
                    Text("Copied! Now press ⌘V to paste")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 320, height: min(400, CGFloat(clipboardManager.history.count * 45 + (selectedItem != nil ? 120 : 80))))
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            // Copied indicator
            Group {
                if showCopiedIndicator {
                    VStack {
                        Text("Copied!")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                showCopiedIndicator = false
                            }
                        }
                    }
                }
            }
        )
    }
    
    private func clipboardItemView(_ item: String, index: Int) -> some View {
        let isHovered = hoveredIndex == index
        let isSelected = selectedItem == item
        
        return Button(action: {
            // Just copy to clipboard, don't try to paste
            clipboardManager.setClipboard(item)
            selectedItem = item
            
            // Show a brief "Copied!" indicator
            withAnimation {
                showCopiedIndicator = true
            }
        }) {
            HStack {
                Text(displayText(item))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                
                // Show a checkmark for the selected item
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .padding(.trailing, 12)
                }
            }
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        Color.accentColor.opacity(0.2)
                    } else if isHovered {
                        Color(NSColor.selectedControlColor)
                    } else {
                        Color.clear
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                hoveredIndex = hovering ? index : nil
            }
        }
        
        // Add divider between items
        .overlay(
            Divider()
                .padding(.leading, 12)
                .opacity(index < clipboardManager.history.count - 1 ? 1 : 0),
            alignment: .bottom
        )
    }
    
    private func displayText(_ text: String) -> String {
        // Remove excessive whitespace and newlines for display
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutNewlines = trimmed.replacingOccurrences(of: "\n", with: " ")
        return withoutNewlines
    }
}
