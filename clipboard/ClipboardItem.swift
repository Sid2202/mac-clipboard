import SwiftUI

// Define the types of content we can store
enum ClipboardItemType: String, Codable {
    case text
    case image
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: ClipboardItemType
    var content: Data // Use Data to store both text (UTF-8) and images
    var timestamp: Date
    var isPinned: Bool = false
    
    // Convenience property to get text
    var text: String? {
        if type == .text {
            return String(data: content, encoding: .utf8)
        }
        return nil
    }
    
    // Convenience property to get an image
    var image: NSImage? {
        if type == .image {
            return NSImage(data: content)
        }
        return nil
    }
    
    // A short preview for display purposes
    var preview: String {
        switch type {
        case .text:
            return text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Invalid Text"
        case .image:
            return "Image"
        }
    }
    
    // Initializer for text
    init(text: String, timestamp: Date = Date()) {
        self.type = .text
        self.content = text.data(using: .utf8) ?? Data()
        self.timestamp = timestamp
    }
    
    // Initializer for image data
    init(imageData: Data, timestamp: Date = Date()) {
        self.type = .image
        self.content = imageData
        self.timestamp = timestamp
    }
    
    // Required for Codable since we have custom initializers
    private enum CodingKeys: String, CodingKey {
        case id, type, content, timestamp, isPinned
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
}
