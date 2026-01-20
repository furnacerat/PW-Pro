//
//  MainMenuView.swift
//  PW Pro
//
//  Created by GitHub Copilot on 1/19/26.
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Field Tools") {
                    NavigationLink("Chemical List", destination: ChemicalListView())
                    NavigationLink("Chemical Calculator", destination: ChemicalCalculatorView())
                    NavigationLink("Estimates", destination: PlaceholderView(title: "Estimates"))
                    NavigationLink("Scheduling", destination: PlaceholderView(title: "Scheduling"))
                    NavigationLink("Weather Guide", destination: PlaceholderView(title: "Weather Guide"))
                    NavigationLink("Measuring", destination: PlaceholderView(title: "Measuring"))
                    NavigationLink("UpCharge", destination: PlaceholderView(title: "UpCharge"))
                }

                Section("Business Suite") {
                    NavigationLink("CRM", destination: PlaceholderView(title: "CRM"))
                    NavigationLink("Invoicing", destination: PlaceholderView(title: "Invoicing"))
                    NavigationLink("Profit/Loss", destination: PlaceholderView(title: "Profit/Loss"))
                    NavigationLink("Team", destination: PlaceholderView(title: "Team"))
                    NavigationLink("Payments", destination: PlaceholderView(title: "Payments"))
                }
            }
            .navigationTitle("Main Menu")
            .listStyle(.insetGrouped)
        }
    }
}

struct PlaceholderView: View {
    let title: String
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title)
                .bold()
            Text("Placeholder screen for \(title).")
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle(title)
    }
}

#Preview {
    MainMenuView()
}
