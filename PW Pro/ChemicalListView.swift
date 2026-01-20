import SwiftUI

struct ChemicalListView: View {
    let chemicals = ChemicalData.chemicals

    var body: some View {
        List {
            ForEach(chemicals) { chem in
                NavigationLink(value: chem) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chem.name)
                            .font(.headline)
                        Text(chem.shortDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Chemical List")
        .navigationDestination(for: Chemical.self) { chem in
            ChemicalDetailView(chemical: chem)
        }
    }
}

struct ChemicalDetailView: View {
    let chemical: Chemical

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(chemical.name)
                    .font(.largeTitle)
                    .bold()

                Text(chemical.shortDescription)
                    .font(.headline)

                Group {
                    Text("Uses")
                        .font(.title2)
                        .bold()
                    Text(chemical.uses)
                }

                Group {
                    Text("Precautions")
                        .font(.title2)
                        .bold()
                    Text(chemical.precautions)
                }

                Group {
                    Text("Mixing Note")
                        .font(.title2)
                        .bold()
                    Text(chemical.mixingNote)
                }

                if let sds = chemical.sdsURL {
                    Link("View SDS", destination: URL(string: sds)!)
                        .padding(.top)
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        ChemicalListView()
    }
}
