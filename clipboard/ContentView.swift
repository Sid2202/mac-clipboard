//
//  ContentView.swift
//  clipboard
//
//  Created by Sidhanti Patil on 04/05/25.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var showingClearConfirmation = false
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return clipboardManager.items
        } else {
            return clipboardManager.searchItems(query: searchText)
        }
    }
    
    var body: some View {
        ZStack {
            // Subtle background
            Color.darkBackground
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 16) {
                // Header with title and buttons
                HStack {
                    Text("Clipboard")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showingClearConfirmation = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(ElegantButtonStyle(color: .accentRed, isOutlined: true))
                    .alert(isPresented: $showingClearConfirmation) {
                        Alert(
                            title: Text("Clear Clipboard History?"),
                            message: Text("This will remove all unpinned items. Pinned items will be preserved."),
                            primaryButton: .destructive(Text("Clear")) {
                                clipboardManager.clearHistory()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .padding(.horizontal)
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.white.opacity(0.5))
                        .font(.system(size: 12))
                    
                    TextField("Search clipboard items...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
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
                )
                .padding(.horizontal)
                
                // Stats
                HStack(spacing: 12) {
                    statItem(
                        value: "\(clipboardManager.items.count)",
                        label: "Items",
                        icon: "doc.plaintext",
                        color: .accentBlue
                    )
                    
                    statItem(
                        value: "\(clipboardManager.items.filter { $0.isPinned }.count)",
                        label: "Pinned",
                        icon: "pin.fill",
                        color: .accentRed
                    )
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Clipboard items list
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
                        LazyVStack(spacing: 8) {
                            ForEach(filteredItems) { item in
                                ClipboardItemCard(item: item, clipboardManager: clipboardManager)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                    .background(Color.subtleBackground.opacity(0.4))
                    .cornerRadius(8)
                    .padding(.horizontal, 8)
                }
                
                // Bottom hint
                Text("Press ⌘+Shift+V to access clipboard history anytime")
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.5))
                    .padding(.bottom, 6)
            }
            .padding(.vertical)
        }
        .frame(width: 400, height: 500)
        .preferredColorScheme(.dark)
    }
    
    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 12))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Color.white.opacity(0.5))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.08))
        )
    }
}

struct ClipboardItemCard: View {
    let item: ClipboardItem
    let clipboardManager: ClipboardManager
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Left status icon
            ZStack {
                Circle()
                    .fill(
                        item.isPinned ?
                            Color.accentRed.opacity(0.15) :
                            Color.clear
                    )
                    .frame(width: 24, height: 24)
                
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color.accentRed.opacity(0.8))
                }
            }
            
            // Preview Icon (Text or Image)
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
                Text(item.preview)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                
                Text(timeAgo(from: item.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(Color.white.opacity(0.5))
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: {
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
                
                Button(action: {
                    clipboardManager.setClipboard(item)
                }) {
                    Text("Copy")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(ElegantButtonStyle(color: .accentBlue))
                .opacity(isHovered ? 1 : 0.5)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    item.isPinned ?
                        Color.accentRed.opacity(0.05) :
                        Color.white.opacity(isHovered ? 0.04 : 0)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            item.isPinned ?
                                Color.accentRed.opacity(0.1) :
                                Color.clear,
                            lineWidth: 0.5
                        )
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
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
