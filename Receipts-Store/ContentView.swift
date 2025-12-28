//
//  ContentView.swift
//  Receipts-Store
//
//  Created by Mher Movsisyan on 2025-12-27.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ReceiptsListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Receipt.self, inMemory: true)
}
