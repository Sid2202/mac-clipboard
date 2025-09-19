//import SwiftUI
//import AppKit
//
//struct ClipboardOverlayView: View {
//    @ObservedObject var clipboardManager: ClipboardManager
//    var onDismiss: () -> Void
//    @State private var hoveredIndex: Int? = nil
//    @State private var selectedItem: ClipboardItem? = nil
//    @State private var showCopiedIndicator = false
//    @State private var showMaxPinsAlert = false
//    @Environment(\.colorScheme) var colorScheme
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // Header with instructions
//            VStack(spacing: 4) {
//                HStack {
//                    Text("Clipboard")
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    Spacer()
//                    Button(action: onDismiss) {
//                        Image(systemName: "xmark.circle.fill")
//                            .foregroundColor(.secondary)
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//                
//                // Instructions for users
//                Text("Click to copy. Pin items to keep them at the top.")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//            .padding(.horizontal, 12)
//            .padding(.vertical, 8)
//            .background(Color(colorScheme == .dark ? NSColor.windowBackgroundColor : NSColor.controlBackgroundColor))
//            
//            Divider()
//            
//            // Content
//            if clipboardManager.items.isEmpty {
//                Text("Clipboard history is empty")
//                    .foregroundColor(.secondary)
//                    .padding()
//                    .frame(maxWidth: .infinity, alignment: .center)
//            } else {
//                ScrollView {
//                    LazyVStack(spacing: 0) {
//                        ForEach(clipboardManager.items.indices, id: \.self) { index in
//                            let item = clipboardManager.items[index]
//                            clipboardItemView(item, index: index)
//                        }
//                    }
//                }
//            }
//            
//            // Optional: "Copy & Close" button at the bottom
//            if selectedItem != nil {
//                Divider()
//                Button(action: {
//                    onDismiss()
//                }) {
//                    Text("Copied! Now press ⌘V to paste")
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 8)
//                        .background(Color.accentColor.opacity(0.2))
//                        .cornerRadius(4)
//                }
//                .buttonStyle(PlainButtonStyle())
//                .padding(.horizontal, 12)
//                .padding(.vertical, 8)
//            }
//        }
//        .frame(width: 320, height: min(400, CGFloat(clipboardManager.items.count * 45 + (selectedItem != nil ? 120 : 80))))
//        .background(
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color(NSColor.windowBackgroundColor))
//                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 0)
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 10))
//        .overlay(
//            // Copied indicator
//            Group {
//                if showCopiedIndicator {
//                    VStack {
//                        Text("Copied!")
//                            .padding(.horizontal, 12)
//                            .padding(.vertical, 6)
//                            .background(Color.accentColor)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                            .shadow(radius: 2)
//                    }
//                    .transition(.scale.combined(with: .opacity))
//                    .onAppear {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                            withAnimation {
//                                showCopiedIndicator = false
//                            }
//                        }
//                    }
//                }
//            }
//        )
//        .alert(isPresented: $showMaxPinsAlert) {
//            Alert(
//                title: Text("Maximum Pins Reached"),
//                message: Text("You can pin up to 5 items. Unpin an item to pin a new one."),
//                dismissButton: .default(Text("OK"))
//            )
//        }
//    }
//    
//    private func clipboardItemView(_ item: ClipboardItem, index: Int) -> some View {
//        let isHovered = hoveredIndex == index
//        let isSelected = selectedItem?.id == item.id
//        
//        return HStack(spacing: 0) {
//            // The text content and copy button
//            Button(action: {
//                // Just copy to clipboard, don't try to paste
//                clipboardManager.setClipboard(item.text)
//                selectedItem = item
//                
//                // Show a brief "Copied!" indicator
//                withAnimation {
//                    showCopiedIndicator = true
//                }
//            }) {
//                HStack {
//                    if index == 0 && !item.isPinned {
//                        Image(systemName: "asterisk")
//                            .font(.system(size: 10))
//                            .foregroundColor(.secondary)
//                            .frame(width: 16)
//                    } else if item.isPinned {
//                        Image(systemName: "pin.fill")
//                            .foregroundColor(.blue)
//                            .frame(width: 16)
//                    } else {
//                        Spacer()
//                            .frame(width: 16)
//                    }
//                    
//                    Text(displayText(item.text))
//                        .lineLimit(2)
//                        .truncationMode(.tail)
//                        .foregroundColor(.primary)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    
//                    // Show a checkmark for the selected item
//                    if isSelected {
//                        Image(systemName: "checkmark")
//                            .foregroundColor(.accentColor)
//                    }
//                }
//                .padding(.vertical, 6)
//                .padding(.leading, 12)
//                .padding(.trailing, 8)
//            }
//            .buttonStyle(PlainButtonStyle())
//            .frame(maxWidth: .infinity)
//            
//            // Pin/Unpin button
//            Button(action: {
//                if !item.isPinned && clipboardManager.items.filter({ $0.isPinned }).count >= 5 {
//                    showMaxPinsAlert = true
//                    return
//                }
//                clipboardManager.togglePin(for: item)
//            }) {
//                Image(systemName: item.isPinned ? "pin.slash" : "pin")
//                    .foregroundColor(item.isPinned ? .blue : .secondary)
//                    .frame(width: 30)
//                    .padding(.trailing, 8)
//                    .contentShape(Rectangle())
//            }
//            .buttonStyle(PlainButtonStyle())
//            .help(item.isPinned ? "Unpin this item" : "Pin this item")
//        }
//        .background(
//            Group {
//                if isSelected {
//                    Color.accentColor.opacity(0.2)
//                } else if isHovered {
//                    Color(NSColor.selectedControlColor)
//                } else if item.isPinned {
//                    Color.blue.opacity(0.1)
//                } else {
//                    Color.clear
//                }
//            }
//        )
//        .contentShape(Rectangle())
//        .onHover { hovering in
//            withAnimation(.easeInOut(duration: 0.1)) {
//                hoveredIndex = hovering ? index : nil
//            }
//        }
//        
//        // Add divider between items
//        .overlay(
//            Divider()
//                .padding(.leading, 12)
//                .opacity(index < clipboardManager.items.count - 1 ? 1 : 0),
//            alignment: .bottom
//        )
//    }
//    
//    private func displayText(_ text: String) -> String {
//        // Remove excessive whitespace and newlines for display
//        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
//        let withoutNewlines = trimmed.replacingOccurrences(of: "\n", with: " ")
//        return withoutNewlines
//    }
//}
import SwiftUI
import AppKit

// Add hex color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Define color palette
extension Color {
    static let accentBlue = Color(hex: "007AFF")
    static let accentRed = Color(hex: "FF3B30")
    static let subtleBackground = Color(hex: "1C1C1E")
    static let darkBackground = Color(hex: "121214")
    static let cardBackground = Color(hex: "2C2C2E")
}

// A more subtle glass effect
struct GlassEffect: ViewModifier {
    var intensity: Double = 1.0
    
    func body(content: Content) -> some View {
        content
            .background(
                BlurEffectView(style: .hudWindow)
                    .opacity(0.85 * intensity)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.white.opacity(0.15 * intensity),
                        lineWidth: 0.5
                    )
            )
    }
}

// A SwiftUI wrapper for NSVisualEffectView
struct BlurEffectView: NSViewRepresentable {
    var style: NSVisualEffectView.Material
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = style
        view.blendingMode = .behindWindow
        view.state = .active
        view.appearance = NSAppearance(named: .darkAqua)
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = style
    }
}

// Elegant button style
struct ElegantButtonStyle: ButtonStyle {
    var color: Color = .accentBlue
    var isOutlined: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isOutlined ?
                    Color.clear :
                    color.opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color, lineWidth: isOutlined ? 1 : 0)
                    .opacity(isOutlined ? (configuration.isPressed ? 0.6 : 0.8) : 0)
            )
            .foregroundColor(isOutlined ? color : .white)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// A custom view that handles text highlighting
struct HighlightedTextView: View {
    let text: String
    let highlight: String
    
    var body: some View {
        let components = highlightComponents()
        
        return HStack(spacing: 0) {
            ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                Text(component.text)
                    .foregroundColor(component.isHighlighted ? .black : .white)
                    .font(.system(size: 14, weight: component.isHighlighted ? .medium : .regular))
                    .background(component.isHighlighted ? Color.accentBlue.opacity(0.7) : Color.clear)
            }
        }
    }
    
    struct TextComponent {
        let text: String
        let isHighlighted: Bool
    }
    
    private func highlightComponents() -> [TextComponent] {
        var components: [TextComponent] = []
        let lowercaseText = text.lowercased()
        let lowercaseHighlight = highlight.lowercased()
        
        var currentIndex = text.startIndex
        
        while currentIndex < text.endIndex {
            if let range = lowercaseText[currentIndex...].range(of: lowercaseHighlight) {
                if range.lowerBound > currentIndex {
                    let beforeText = String(text[currentIndex..<range.lowerBound])
                    components.append(TextComponent(text: beforeText, isHighlighted: false))
                }
                
                let highlightedText = String(text[range])
                components.append(TextComponent(text: highlightedText, isHighlighted: true))
                
                currentIndex = range.upperBound
            } else {
                let remainingText = String(text[currentIndex...])
                components.append(TextComponent(text: remainingText, isHighlighted: false))
                break
            }
        }
        
        return components
    }
}

// MARK: - Main ClipboardOverlayView

struct ClipboardOverlayView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    var onDismiss: () -> Void
    @State private var hoveredIndex: Int? = nil
    @State private var selectedItem: ClipboardItem? = nil
    @State private var showCopiedIndicator = false
    @State private var showMaxPinsAlert = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.items
        } else {
            return clipboardManager.searchItems(query: searchText)
        }
    }
    
    var body: some View {
        ZStack {
            // Subtle dark background
            Color.darkBackground
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Clipboard History")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.6))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Circle())
                        .onHover { isHovered in
                            if isHovered {
                                NSCursor.pointingHand.set()
                            } else {
                                NSCursor.arrow.set()
                            }
                        }
                    }
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(isSearchFocused ? .accentBlue : Color.white.opacity(0.5))
                            .font(.system(size: 12))
                        
                        TextField("Search...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .focused($isSearchFocused)
                            .onSubmit {
                                selectFirstItemIfPossible()
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                isSearchFocused = true
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.white.opacity(0.5))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.accentBlue.opacity(isSearchFocused ? 0.3 : 0), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(
                    Color.subtleBackground.opacity(0.8)
                        .modifier(GlassEffect(intensity: 0.5))
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Content
                if filteredItems.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        if searchText.isEmpty && clipboardManager.items.isEmpty {
                            // Empty clipboard state
                            Image(systemName: "clipboard")
                                .font(.system(size: 32))
                                .foregroundColor(Color.white.opacity(0.3))
                            
                            VStack(spacing: 8) {
                                Text("Your clipboard is empty")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color.white.opacity(0.7))
                                
                                Text("Copy text from any application and it will appear here")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 16)
                            }
                        } else {
                            // No search results state
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(Color.white.opacity(0.3))
                            
                            Text("No matching items for '\(searchText)'")
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.subtleBackground.opacity(0.4))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(filteredItems.indices, id: \.self) { index in
                                let item = filteredItems[index]
                                clipboardItemView(item, index: index)
                            }
                        }
                    }
                    .background(Color.subtleBackground.opacity(0.4))
                }
                
                // Copied notification at the bottom
                if selectedItem != nil {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    Button(action: {
                        onDismiss()
                    }) {
                        Text("Copied! Press ⌘V to paste")
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(ElegantButtonStyle(color: .accentBlue))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Color.subtleBackground.opacity(0.8)
                            .modifier(GlassEffect(intensity: 0.5))
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.subtleBackground.opacity(0.9))
                    .modifier(GlassEffect(intensity: 0.7))
            )
            
            // Copied indicator overlay
            if showCopiedIndicator {
                VStack {
                    Text("Copied")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentBlue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
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
        .frame(width: 340, height: min(500, CGFloat(filteredItems.count * 60 + (selectedItem != nil ? 160 : 120))))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 5)
        .preferredColorScheme(.dark)
        .alert(isPresented: $showMaxPinsAlert) {
            Alert(
                title: Text("Maximum Pins Reached"),
                message: Text("You can pin up to 5 items. Unpin an item to pin a new one."),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Auto-focus the search field when the overlay appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFocused = true
            }
        }
    }
    
    private func selectFirstItemIfPossible() {
        if !filteredItems.isEmpty {
            let firstItem = filteredItems[0]
            clipboardManager.setClipboard(firstItem)
            selectedItem = firstItem
            
            withAnimation {
                showCopiedIndicator = true
            }
        }
    }
    
    private func clipboardItemView(_ item: ClipboardItem, index: Int) -> some View {
        let isHovered = hoveredIndex == index
        let isSelected = selectedItem?.id == item.id
        
        return HStack(spacing: 12) {
            // Left side with icon and text
            HStack(spacing: 12) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(
                            item.isPinned ?
                                Color.accentRed.opacity(0.15) :
                                (index == 0 && !item.isPinned ?
                                    Color.accentBlue.opacity(0.15) :
                                    Color.clear)
                        )
                        .frame(width: 24, height: 24)
                    
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.accentRed.opacity(0.8))
                    } else if index == 0 && !item.isPinned {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.accentBlue.opacity(0.8))
                    }
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 3) {
                    if searchText.isEmpty {
                        Text(displayText(item.text))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    } else {
                        HighlightedTextView(text: displayText(item.text), highlight: searchText)
                            .lineLimit(1)
                    }
                    
                    Text(timeAgo(from: item.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Right side with buttons
            HStack(spacing: 8) {
                // Pin/Unpin button
                Button(action: {
                    if !item.isPinned && clipboardManager.items.filter({ $0.isPinned }).count >= 5 {
                        showMaxPinsAlert = true
                        return
                    }
                    clipboardManager.togglePin(for: item)
                }) {
                    Image(systemName: item.isPinned ? "pin.slash" : "pin")
                        .font(.system(size: 11))
                        .foregroundColor(item.isPinned ? Color.accentRed.opacity(0.8) : Color.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(isHovered || item.isPinned ? 1 : 0)
                .onHover { isHovered in
                    if isHovered {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                
                // Copy button
                Button(action: {
                    clipboardManager.setClipboard(item)
                    selectedItem = item
                    
                    withAnimation {
                        showCopiedIndicator = true
                    }
                }) {
                    Text("Copy")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(ElegantButtonStyle(color: .accentBlue))
                .opacity(isHovered ? 1 : 0.5)
                .onHover { isHovered in
                    if isHovered {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Group {
                if isSelected {
                    Color.accentBlue.opacity(0.1)
                } else if isHovered {
                    Color.white.opacity(0.04)
                } else if item.isPinned {
                    Color.accentRed.opacity(0.05)
                } else {
                    Color.clear
                }
            }
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredIndex = hovering ? index : nil
            }
        }
        .onTapGesture {
            clipboardManager.setClipboard(item)
            selectedItem = item
            
            withAnimation {
                showCopiedIndicator = true
            }
        }
    }
    
    private func displayText(_ text: String) -> String {
        // Remove excessive whitespace and newlines for display
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let withoutNewlines = trimmed.replacingOccurrences(of: "\n", with: " ")
        return withoutNewlines
    }
    
    func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "Yesterday" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour) hour\(hour == 1 ? "" : "s") ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) minute\(minute == 1 ? "" : "s") ago"
        } else {
            return "Just now"
        }
    }
}
    
    private func highlightedText(original: String, highlight: String) -> some View {
        return HighlightedTextView(text: original, highlight: highlight)
    }

    // A custom view that handles text highlighting
//struct HighlightedTextView: View {
//    let text: String
//    let highlight: String
//    
//    var body: some View {
//        let components = highlightComponents()
//        
//        return HStack(spacing: 0) {
//            ForEach(Array(components.enumerated()), id: \.offset) { index, component in
//                Text(component.text)
//                    .foregroundColor(component.isHighlighted ? .black : .white)
//                    .font(.system(size: 14, weight: component.isHighlighted ? .medium : .regular))
//                    .background(component.isHighlighted ? Color.accentBlue.opacity(0.7) : Color.clear)
//            }
//        }
//    }
//    
//    struct TextComponent {
//        let text: String
//        let isHighlighted: Bool
//    }
//    
//    private func highlightComponents() -> [TextComponent] {
//        var components: [TextComponent] = []
//        let lowercaseText = text.lowercased()
//        let lowercaseHighlight = highlight.lowercased()
//        
//        var currentIndex = text.startIndex
//        
//        while currentIndex < text.endIndex {
//            if let range = lowercaseText[currentIndex...].range(of: lowercaseHighlight) {
//                if range.lowerBound > currentIndex {
//                    let beforeText = String(text[currentIndex..<range.lowerBound])
//                    components.append(TextComponent(text: beforeText, isHighlighted: false))
//                }
//                
//                let highlightedText = String(text[range])
//                components.append(TextComponent(text: highlightedText, isHighlighted: true))
//                
//                currentIndex = range.upperBound
//            } else {
//                let remainingText = String(text[currentIndex...])
//                components.append(TextComponent(text: remainingText, isHighlighted: false))
//                break
//            }
//        }
//        
//        return components
//    }
//}
//    
//    func timeAgo(from date: Date) -> String {
//        let calendar = Calendar.current
//        let now = Date()
//        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
//        
//        if let day = components.day, day > 0 {
//            return day == 1 ? "Yesterday" : "\(day) days ago"
//        } else if let hour = components.hour, hour > 0 {
//            return "\(hour) hour\(hour == 1 ? "" : "s") ago"
//        } else if let minute = components.minute, minute > 0 {
//            return "\(minute) minute\(minute == 1 ? "" : "s") ago"
//        } else {
//            return "Just now"
//        }
//    }

// A custom focusable TextField that can receive keyboard focus
struct FocusableTextField: NSViewRepresentable {
    var placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    var onCommit: () -> Void = {}
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: FocusableTextField
        
        init(_ parent: FocusableTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            DispatchQueue.main.async {
                self.parent.text = textField.stringValue
            }
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            DispatchQueue.main.async {
                self.parent.isFocused = false
            }
        }
        
        func controlTextDidBeginEditing(_ obj: Notification) {
            DispatchQueue.main.async {
                self.parent.isFocused = true
            }
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onCommit()
                return true
            }
            return false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.placeholderString = placeholder
        textField.stringValue = text
        textField.delegate = context.coordinator
        
        // Styling
        textField.backgroundColor = .clear
        textField.isBordered = false
        textField.focusRingType = .none
        textField.textColor = .white
        textField.drawsBackground = false
        
        // Make sure it's editable and selectable
        textField.isEditable = true
        textField.isSelectable = true
        
        // Set appropriate font
        textField.font = NSFont.systemFont(ofSize: 14)
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Only update if there's a real change to avoid focus issues
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        
        if isFocused && nsView.window?.firstResponder != nsView {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}
