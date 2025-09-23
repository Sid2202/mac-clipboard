import Cocoa
import SwiftUI
import Combine

class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    private var timer: Timer?
    private let maxItems = 100
    
    private var lastCopiedString: String = ""
    private var pasteboardChangeCount = NSPasteboard.general.changeCount
    
    private var lastChangeCount = NSPasteboard.general.changeCount
    
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
        
        guard pasteboard.changeCount != lastChangeCount else {
            return
        }
        
        // First, check for images (as they can also have string representations)
        if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            // Avoid adding duplicates
            if let lastItem = items.first, lastItem.type == .image, lastItem.content == imageData {
                lastChangeCount = pasteboard.changeCount
                return
            }
            
            let newItem = ClipboardItem(imageData: imageData)
            addItem(newItem)
            lastChangeCount = pasteboard.changeCount
            
            // Then, check for strings
        } else if let string = pasteboard.string(forType: .string), !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Avoid adding duplicates
            if let lastItem = items.first, lastItem.text == string {
                lastChangeCount = pasteboard.changeCount
                return
            }
            
            let newItem = ClipboardItem(text: string)
            addItem(newItem)
            lastChangeCount = pasteboard.changeCount
        }
    }
    
    func addItem(_ item: ClipboardItem) {
        // Prevent adding exact duplicates unless pinned
        if let existingIndex = items.firstIndex(where: { $0.content == item.content && !$0.isPinned }) {
            items.remove(at: existingIndex)
        }
        
        items.insert(item, at: 0)
        
        // Limit total number of items
        while items.count > maxItems {
            if let lastUnpinnedIndex = items.lastIndex(where: { !$0.isPinned }) {
                items.remove(at: lastUnpinnedIndex)
            } else {
                items.removeLast() // All items are pinned, remove the oldest
            }
        }
        
        saveItems()
    }
    
    func setClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        var success = false
        switch item.type {
        case .text:
            if let text = item.text {
                success = pasteboard.setString(text, forType: .string)
            }
        case .image:
            // Set multiple image types for better compatibility
            success = pasteboard.setData(item.content, forType: .tiff)
            pasteboard.setData(item.content, forType: .png)
        }
        
        if success {
            // Move the copied item to the top of the list
            if let index = items.firstIndex(of: item) {
                items.remove(at: index)
                items.insert(item, at: 0)
                saveItems()
            }
        }
    }
    @objc func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear Clipboard History?"
        alert.informativeText = "Are you sure you want to delete all unpinned items? This action cannot be undone."
        alert.alertStyle = .warning
        
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            DispatchQueue.main.async {
                // Remove all unpinned items
                self.items.removeAll(where: { !$0.isPinned })
                self.saveItems()
                print("Unpinned clipboard history cleared by user confirmation.")
            }
        } else {
            print("User cancelled the clear history action.")
        }
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
        
        return items.filter {
            if $0.type == .text {
                return $0.text?.localizedCaseInsensitiveContains(query) ?? false
            }
            // You could also allow searching for "image"
            if "image".localizedCaseInsensitiveContains(query) && $0.type == .image {
                return true
            }
            return false
        }
    }
}
