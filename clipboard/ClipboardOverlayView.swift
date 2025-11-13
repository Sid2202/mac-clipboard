import SwiftUI
import AppKit

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

struct HighlightedTextView: View {
    let text: String
    let highlight: String
    
    var body: some View {
        Text(text)
            .lineLimit(2)
            .truncationMode(.tail)
            .foregroundColor(.white)
            .font(.system(size: 14))
    }
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
        .frame(width: 360, height: min(550, CGFloat(filteredItems.count * 55) + 80))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 5)
        .preferredColorScheme(.dark)
        .onAppear(perform: setupView)
        .onChange(of: searchText) {
            selectedIndex = 0
        }
        .alert("Accessibility Permission Required", isPresented: $showAccessibilityAlert) {
            Button("Open System Settings") {
                accessibilityManager.openSystemPreferences()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This app needs Accessibility permission to paste content. Please enable 'clipboard' in System Settings > Privacy & Security > Accessibility.")
        }
        .alert("Maximum Pins Reached", isPresented: $showMaxPinsAlert, actions: { Button("OK") {} }, message: { Text("You can pin up to 5 items.") })
        // Key event handling
        .onKeyPress(keys: [.upArrow, .downArrow, .return, .escape]) { press in
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
                .onSubmit {
                    if !filteredItems.isEmpty {
                        selectAndCopy(at: selectedIndex)
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    isSearchFocused = true
                }) {
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
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredItems.indices, id: \.self) { index in
                            let item = filteredItems[index]
                            clipboardItemView(item, index: index)
                                .id(index)
                        }
                    }
                }
                .onChange(of: selectedIndex) { oldValue, newValue in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(newValue, anchor: .center)
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
    
    // MARK: - Helper Views & Functions
    
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
        // Auto-focus the search field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isSearchFocused = true
        }
    }
    
    private func handleKeyPress(_ press: KeyPress) {
        guard !filteredItems.isEmpty else { return }
        
        switch press.key {
        case .downArrow:
            selectedIndex = (selectedIndex + 1) % filteredItems.count
        case .upArrow:
            selectedIndex = (selectedIndex - 1 + filteredItems.count) % filteredItems.count
        case .return:
            selectAndCopy(at: selectedIndex)
        case .escape:
            onDismiss()
        default:
            break
        }
    }
    
    private func selectAndCopy(at index: Int) {
        guard filteredItems.indices.contains(index) else { return }
        let item = filteredItems[index]
        selectedIndex = index
        performCopyAndPaste(for: item)
    }
    
    private func performCopyAndPaste(for item: ClipboardItem) {
        clipboardManager.setClipboard(item)
        
        DispatchQueue.main.async {
            // Re-check permission status
            self.accessibilityManager.checkPermission()
            
            if self.accessibilityManager.isGranted {
                withAnimation {
                    self.showCopiedIndicator = true
                }
                
                self.clipboardManager.simulatePaste()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.onDismiss()
                }
            } else {
                self.showAccessibilityAlert = true
            }
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
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func clipboardItemView(_ item: ClipboardItem, index: Int) -> some View {
        let isHovered = hoveredIndex == index
        let isSelected = selectedIndex == index
        let hasMatch = !searchText.isEmpty && item.preview.lowercased().contains(searchText.lowercased())
        
        return HStack(spacing: 12) {
            // Icon
            switch item.type {
            case .image:
                if let nsImage = item.image {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                }
            case .text:
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.06))
                    
                    Image(systemName: hasMatch ? "doc.text.magnifyingglass" : "doc.text")
                        .font(.system(size: 16))
                        .foregroundColor(hasMatch ? Color.accentBlue : Color.white.opacity(0.6))
                }
                .frame(width: 36, height: 36)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.preview)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                
                HStack(spacing: 6) {
                    Text(timeAgo(from: item.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.4))
                    
                    if item.isPinned {
                        HStack(spacing: 2) {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 8))
                            Text("Pinned")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(Color.accentRed.opacity(0.8))
                    }
                    
                    // Match indicator
                    if hasMatch {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 8))
                            Text("Match")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(Color.accentBlue.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            // Pin button (only visible on hover or if pinned)
            Button(action: {
                togglePin(for: item)
            }) {
                Image(systemName: item.isPinned ? "pin.slash" : "pin")
                    .font(.system(size: 12))
                    .foregroundColor(item.isPinned ? Color.accentRed.opacity(0.8) : Color.white.opacity(0.5))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(isHovered ? 0.08 : 0))
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(isHovered || item.isPinned ? 1 : 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentBlue.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentBlue.opacity(0.3), lineWidth: 1)
                        )
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                } else if item.isPinned {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentRed.opacity(0.04))
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
            selectedIndex = index
            performCopyAndPaste(for: item)
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}
