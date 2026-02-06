//
//  ContentView.swift
//  PW Pro
//
//  Created by Harold Foster on 1/19/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some View {
        Group {
            if isLoggedIn {
                MainMenuView()
            } else {
                LoginView()
            }
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
