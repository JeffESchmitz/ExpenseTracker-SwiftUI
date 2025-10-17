//
//  ColorPalette.swift
//  ExpenseTracker
//
//  Created by Jeff E. Schmitz on 8/29/25.
//

import SwiftUI

struct ColorPalette: View {
    let selectedColor: String
    let onColorSelected: (String) -> Void

    private let colors = [
        ("green", Color.green),
        ("blue", Color.blue),
        ("orange", Color.orange),
        ("pink", Color.pink),
        ("red", Color.red),
        ("purple", Color.purple),
        ("teal", Color.teal),
        ("yellow", Color.yellow),
        ("indigo", Color.indigo),
        ("brown", Color.brown),
        ("gray", Color.gray)
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(colors, id: \.0) { colorName, color in
                colorSwatch(colorName: colorName, color: color)
            }
        }
    }

    private func colorSwatch(colorName: String, color: Color) -> some View {
        Button {
            onColorSelected(colorName)
        } label: {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(selectedColor == colorName ? Color.primary : Color.clear, lineWidth: 3)
                )
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 1)
                )
                .shadow(radius: selectedColor == colorName ? 3 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Color: \(colorName)")
        .accessibilityAddTraits(selectedColor == colorName ? [.isSelected] : [])
    }
}

#Preview {
    ColorPalette(selectedColor: "blue") { _ in }
        .padding()
}
