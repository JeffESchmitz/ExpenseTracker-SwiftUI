//
//  SFSymbolPicker.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import SwiftUI

struct SFSymbolPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    let selectedSymbol: String
    let onSymbolSelected: (String) -> Void
    
    private let suggestedSymbols = [
        "fork.knife", "car.fill", "popcorn.fill", "bag.fill", "creditcard.fill",
        "house.fill", "cart.fill", "fuelpump.fill", "dollarsign.circle.fill", "gift.fill",
        "stethoscope", "gamecontroller.fill", "wifi", "theatermasks.fill", "music.note",
        "book.fill", "airplane", "bicycle", "pawprint.fill", "leaf.fill",
        "hammer.fill", "paintbrush.fill", "wrench.fill", "lightbulb.fill", "camera.fill"
    ]
    
    private let commonSymbols = [
        "doc.text.fill", "folder.fill", "tray.fill", "archivebox.fill", "paperplane.fill",
        "tray.full.fill", "externaldrive.fill", "internaldrive.fill", "opticaldiscdrive.fill", "tv.fill",
        "desktopcomputer", "laptopcomputer", "pc", "server.rack", "display",
        "printer.fill", "scanner.fill", "faxmachine", "phone.fill", "iphone",
        "ipad", "applewatch", "airpods", "homepod.fill", "appletv.fill",
        "clock.fill", "alarm.fill", "stopwatch.fill", "timer", "hourglass",
        "calendar", "note.text", "bookmark.fill", "graduationcap.fill", "pencil",
        "lasso", "crop", "wand.and.rays", "slider.horizontal.3", "knob",
        "speaker.fill", "hifispeaker.fill", "headphones", "earbuds", "airpodspro",
        "beats.headphones", "beats.earphones", "beats.studiobud.left", "homepod.mini.fill", "radio.fill",
        "guitars.fill", "pianokeys", "drum.fill", "violin", "trumpet.fill",
        "globe", "network", "antenna.radiowaves.left.and.right", "bolt.fill", "sun.max.fill",
        "moon.fill", "cloud.fill", "flame.fill", "drop.fill", "snowflake",
        "tornado", "hurricane", "thermometer", "umbrella.fill", "rainbow",
        "star.fill", "heart.fill", "suit.heart.fill", "diamond.fill", "club.fill",
        "spade.fill", "crown.fill", "gem", "key.fill", "lock.fill"
    ]
    
    private var filteredSymbols: [String] {
        if searchText.isEmpty {
            return []
        }
        
        let searchQuery = searchText.lowercased()
        return commonSymbols.filter { symbol in
            symbol.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search symbols...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Suggested Symbols Section
                        if searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Suggested")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                    ForEach(suggestedSymbols, id: \.self) { symbol in
                                        symbolTile(symbol)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Search Results Section
                        if !searchText.isEmpty && !filteredSymbols.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Search Results")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                    ForEach(filteredSymbols, id: \.self) { symbol in
                                        symbolTile(symbol)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        if !searchText.isEmpty && filteredSymbols.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                Text("No symbols found")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                Text("Try a different search term")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Select Symbol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func symbolTile(_ symbol: String) -> some View {
        Button {
            onSymbolSelected(symbol)
            dismiss()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(selectedSymbol == symbol ? .blue.opacity(0.2) : .clear)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedSymbol == symbol ? .blue : .clear, lineWidth: 2)
                    )
                
                Text(symbol)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Symbol: \(symbol)")
        .accessibilityAddTraits(selectedSymbol == symbol ? [.isSelected] : [])
    }
}

#Preview {
    SFSymbolPicker(selectedSymbol: "fork.knife") { _ in }
}