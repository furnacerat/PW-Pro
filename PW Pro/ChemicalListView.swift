import SwiftUI

struct ChemicalListView: View {
    @State private var chemicals: [Chemical] = []

    var body: some View {
        List {
            ForEach(chemicals, id: \.id) { chem in
                NavigationLink(destination: ChemicalDetailView(chemical: chem)) {
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(String(chem.name.prefix(1)))
                                    .font(.headline)
                                    .foregroundColor(.accentColor)
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(chem.name)
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.primary)
                            Text(chem.shortDescription)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            if let brands = chem.brands, !brands.isEmpty {
                                HStack(spacing: 6) {
                                    ForEach(brands.prefix(3), id: \.self) { b in
                                        Text(b)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.secondary.opacity(0.12))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Chemical List")
        .listStyle(.insetGrouped)
        .onAppear {
            // Load from ChemicalData; this ensures we pick up bundle or dev fallback at runtime
            self.chemicals = ChemicalData.chemicals
        }
    }
}

struct ChemicalDetailView: View {
    let chemical: Chemical

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(chemical.name)
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)

                if let brands = chemical.brands, !brands.isEmpty {
                    HStack {
                        ForEach(brands, id: \.self) { b in
                            Text(b)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.12))
                                .cornerRadius(12)
                        }
                    }
                }

                Text(chemical.shortDescription)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Uses")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                    Text(chemical.uses)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Precautions")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                    Text(chemical.precautions)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Mixing Note")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                    Text(chemical.mixingNote)
                }

                if let sds = chemical.sdsURL, let url = URL(string: sds) {
                    Link("View SDS", destination: url)
                        .padding(.top)
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
    }
}

struct ChemicalListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { ChemicalListView() }
    }
}
