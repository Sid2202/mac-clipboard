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
    @StateObject private var accessibilityManager = AccessibilityManager()
    @State private var showAccessibilityAlert = false
    @State private var selectedIndex: Int = 0
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.items
        } else {
            return clipboardManager.searchItems(query: searchText)
        }
    }
    
    var body: some View {
        ZStack {
            // Main content VStack
            VStack(spacing: 0) {
                headerView
                
                Divider().background(Color.white.opacity(0.1))
                
                contentView
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.subtleBackground.opacity(0.9))
                    .modifier(GlassEffect(intensity: 0.7))
            )
            
            copiedIndicatorView
        }
        .frame(width: 360, height: min(550, CGFloat(filteredItems.count * 55) + 80)) // Dynamic height
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 5)
        .preferredColorScheme(.dark)
        .onAppear(perform: setupView)
        .onChange(of: searchText) { _ in selectedIndex = 0 } // Reset selection on search
        .alert("Permission Required", isPresented: $showAccessibilityAlert, actions: accessibilityAlertButtons)
        .alert("Maximum Pins Reached", isPresented: $showMaxPinsAlert, actions: { Button("OK") {} }, message: { Text("You can pin up to 5 items.") })
        // --- NEW: This modifier captures all key presses for navigation ---
        .onKeyPress(keys: [.upArrow, .downArrow, .return]) { press in
            handleKeyPress(press)
            return .handled
        }
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(isSearchFocused ? .accentBlue : Color.white.opacity(0.5))
            
            TextField("Search or use ↑↓ and ↩ to select...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .focused($isSearchFocused)
                .onSubmit { selectAndCopy(at: selectedIndex) } // Pressing Enter in search bar also copies
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Color.white.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(12)
        .background(Color.subtleBackground.opacity(0.8).modifier(GlassEffect(intensity: 0.5)))
    }
    
    @ViewBuilder
    private var contentView: some View {
        if filteredItems.isEmpty {
            emptyStateView
        } else {
            // --- NEW: ScrollViewReader allows programmatic scrolling ---
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredItems.indices, id: \.self) { index in
                            let item = filteredItems[index]
                            clipboardItemView(item, index: index)
                                .id(index) // Assign an ID for scrolling
                        }
                    }
                }
                .onChange(of: selectedIndex) { newIndex in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(newIndex, anchor: .center) // Auto-scroll to selection
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: searchText.isEmpty ? "clipboard" : "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(Color.white.opacity(0.3))
            
            Text(searchText.isEmpty ? "Clipboard is Empty" : "No Results for \"\(searchText)\"")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.white.opacity(0.7))
            
            if searchText.isEmpty {
                Text("Items you copy will appear here.")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var copiedIndicatorView: some View {
        if showCopiedIndicator {
            Text("Copied to Clipboard")
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Material.thick)
                .cornerRadius(20)
                .shadow(radius: 5)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation { showCopiedIndicator = false }
                    }
                }
        }
    }
    
    private func selectFirstItemIfPossible() {
        if !filteredItems.isEmpty {
            let firstItem = filteredItems[0]
//            clipboardManager.setClipboard(firstItem)
//            selectedItem = firstItem
//            
//            withAnimation {
//                showCopiedIndicator = true
//            }
            performCopyAndPaste(for: firstItem)
        }
    }
    
    // MARK: - Helper Views & Functions
        
    private func itemTypeIcon(for item: ClipboardItem) -> some View {
        Group {
            if let nsImage = item.image {
                Image(nsImage: nsImage)
                    .resizable().aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32).cornerRadius(4)
            } else {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.white.opacity(0.7))
                    .frame(width: 32, height: 32)
            }
        }
    }
    
    private func itemPreviewText(for item: ClipboardItem) -> some View {
        Group {
            if item.type == .text && !searchText.isEmpty {
                HighlightedTextView(text: item.preview, highlight: searchText).lineLimit(1)
            } else {
                Text(item.preview).lineLimit(1).truncationMode(.tail)
                    .foregroundColor(.white).font(.system(size: 14))
            }
        }
    }
    
    private func pinButton(for item: ClipboardItem, isHovered: Bool) -> some View {
        Button(action: { togglePin(for: item) }) {
            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12))
                .foregroundColor(item.isPinned ? .accentRed : .white)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isHovered || item.isPinned ? 0.7 : 0)
    }
    
    @ViewBuilder
    private func accessibilityAlertButtons() -> some View {
        Button("Open System Settings") {
            accessibilityManager.requestPermission()
            onDismiss()
        }
        Button("Cancel", role: .cancel) {}
    }
    
    // MARK: - Actions & Logic
    
    private func setupView() {
        accessibilityManager.checkPermission()
        selectedIndex = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isSearchFocused = true
        }
    }
    
    // --- NEW: Central function for handling key presses ---
    private func handleKeyPress(_ press: KeyPress) {
        guard !filteredItems.isEmpty else { return }
        
        switch press.key {
        case .downArrow:
            selectedIndex = (selectedIndex + 1) % filteredItems.count
        case .upArrow:
            selectedIndex = (selectedIndex - 1 + filteredItems.count) % filteredItems.count
        case .return:
            selectAndCopy(at: selectedIndex)
        default:
            break
        }
    }
    
    private func selectAndCopy(at index: Int) {
        guard filteredItems.indices.contains(index) else { return }
        let item = filteredItems[index]
        
        // Update selection state and perform the copy/paste
        selectedIndex = index
        performCopyAndPaste(for: item)
    }
    
    private func performCopyAndPaste(for item: ClipboardItem) {
        clipboardManager.setClipboard(item)
        
        withAnimation { showCopiedIndicator = true }
        
        accessibilityManager.checkPermission() // Re-check just in case
        if accessibilityManager.isGranted {
            clipboardManager.simulatePaste()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onDismiss()
            }
        } else {
            showAccessibilityAlert = true
        }
    }
    
    private func togglePin(for item: ClipboardItem) {
        if !item.isPinned && clipboardManager.items.filter({ $0.isPinned }).count >= 5 {
            showMaxPinsAlert = true
        } else {
            clipboardManager.togglePin(for: item)
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func clipboardItemView(_ item: ClipboardItem, index: Int) -> some View {
        let isHovered = hoveredIndex == index
        let isSelected = selectedItem?.id == item.id
        
        return HStack(spacing: 12) {
            // Left side with icon and text
            HStack(spacing: 12) {
                // Status icon
                switch item.type {
                case .image:
                    if let nsImage = item.image {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .cornerRadius(4)
                    }
                case .text:
                    Image(systemName: "doc.text")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.7))
                        .frame(width: 32, height: 32)
                }
                // Text content
                VStack(alignment: .leading, spacing: 3) {
                    if item.type == .text && !searchText.isEmpty {
                        HighlightedTextView(text: item.preview, highlight: searchText)
                            .lineLimit(1)
                    } else {
                        Text(item.preview)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
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
                    performCopyAndPaste(for: item)
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
}
    
private func highlightedText(original: String, highlight: String) -> some View {
    return HighlightedTextView(text: original, highlight: highlight)
}

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
