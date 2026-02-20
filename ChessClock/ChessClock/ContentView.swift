//
//  ContentView.swift
//  ChessClock
//
//  Created by Luc Lacombe on 2/20/26.
//

import SwiftUI

// Temporary piece test view — will be replaced by ClockView in Phase 2
struct ContentView: View {
    private let pieces = ["wK","wQ","wR","wB","wN","wP",
                          "bK","bQ","bR","bB","bN","bP"]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(60)), count: 6), spacing: 8) {
            ForEach(pieces, id: \.self) { name in
                Image(name)
                    .resizable()
                    .frame(width: 48, height: 48)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
