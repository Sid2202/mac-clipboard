import Cocoa
import SwiftUI
import Combine

class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    private var timer: Timer?
    private let maxItems = 100
    private var lastCopiedString: String = ""
    private var pasteboardChangeCount = NSPasteboard.general.changeCount
    
    init() {
        // Load any saved items
        loadItems()
        
        // Start monitoring clipboard
        startMonitoring()
    }
    
    func startMonitoring() {
        // Check clipboard every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        // Only process if the pasteboard has changed
        if pasteboard.changeCount != pasteboardChangeCount {
            pasteboardChangeCount = pasteboard.changeCount
            
            if let string = pasteboard.string(forType: .string) {
                // Don't add duplicate of the most recent item
                if !items.isEmpty && items[0].text == string && !items[0].isPinned {
                    return
                }
                
                // Don't add empty strings
                if string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return
                }
                
                // Don't add if it's the same as what we just copied programmatically
                if string == lastCopiedString {
                    lastCopiedString = ""
                    return
                }
                
                // Add new item at the beginning
                let newItem = ClipboardItem(text: string, timestamp: Date())
                addItem(newItem)
            }
        }
    }
    
    func addItem(_ item: ClipboardItem) {
        // Remove existing unpinned duplicate if any
        if let existingIndex = items.firstIndex(where: { $0.text == item.text && !$0.isPinned }) {
            items.remove(at: existingIndex)
        }
        
        // Add at beginning
        items.insert(item, at: 0)
        
        // Limit total number of items
        while items.count > maxItems {
            // Find the last unpinned item to remove
            if let lastUnpinnedIndex = items.lastIndex(where: { !$0.isPinned }) {
                items.remove(at: lastUnpinnedIndex)
            } else {
                // All items are pinned, so remove the last pinned item
                items.removeLast()
            }
        }
        
        // Save after change
        saveItems()
    }
    
    func clearHistory() {
        // Remove all unpinned items
        items.removeAll(where: { !$0.isPinned })
        saveItems()
    }
    
    func setClipboard(_ item: ClipboardItem) {
        setClipboard(item.text)
    }
    
    func setClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        lastCopiedString = text
        
        // If this item already exists and isn't at index 0, move it to the top
        if let existingIndex = items.firstIndex(where: { $0.text == text }),
           existingIndex > 0 {
            let item = items.remove(at: existingIndex)
            items.insert(item, at: 0)
            saveItems()
        }
    }
    
    func togglePin(for item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isPinned.toggle()
            
            // If the item is now pinned, it should still stay where it is
            // If it's unpinned, we can choose to reorder it or leave it
            
            saveItems()
        }
    }
    
    func simulatePaste() {
        // Simulate pressing Cmd+V to paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let source = CGEventSource(stateID: .combinedSessionState)
            
            // Create a keyboard event for Command+V (paste)
            let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)  // 'V' key
            keyVDown?.flags = .maskCommand
            
            let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            keyVUp?.flags = .maskCommand
            
            // Post the events
            keyVDown?.post(tap: .cgAnnotatedSessionEventTap)
            keyVUp?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
    
    // MARK: - Persistence
    
    private func saveItems() {
        // Convert to Data and save
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "savedClipboardItems")
        }
    }
    
    private func loadItems() {
        // Retrieve and decode data
        if let savedItems = UserDefaults.standard.object(forKey: "savedClipboardItems") as? Data {
            if let decodedItems = try? JSONDecoder().decode([ClipboardItem].self, from: savedItems) {
                items = decodedItems
            }
        }
    }
    
    // MARK: - Search
    
    func searchItems(query: String) -> [ClipboardItem] {
        if query.isEmpty {
            return items
        }
        
        return items.filter { $0.text.localizedCaseInsensitiveContains(query) }
    }
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var timestamp: Date
    var isPinned: Bool = false
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
}
