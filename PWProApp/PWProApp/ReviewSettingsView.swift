import SwiftUI

struct ReviewSettingsView: View {
    @ObservedObject var invoiceManager = InvoiceManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Review Links")) {
                TextField("Google Review Link", text: $invoiceManager.businessSettings.googleReviewLink)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                TextField("Facebook Review Link", text: $invoiceManager.businessSettings.facebookReviewLink)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .listRowBackground(Theme.slate800)
            
            Section(header: Text("Message Template")) {
                TextEditor(text: $invoiceManager.businessSettings.reviewRequestTemplate)
                    .frame(height: 100)
                    .font(.body)
                
                Text("Placeholders: {ClientName}, {BusinessName}, {Link}")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .listRowBackground(Theme.slate800)
            
            Section(header: Text("Preview")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Google Preview:")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    Text(ReputationManager.shared.generateReviewMessage(clientName: "John Doe", platform: .google))
                        .font(.callout)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.slate900)
        .foregroundColor(.white)
        .navigationTitle("Reputation Management")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
