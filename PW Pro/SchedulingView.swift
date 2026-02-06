import SwiftUI

struct SchedulingView: View {
    @EnvironmentObject var estimatesStore: EstimatesStore
    @EnvironmentObject var scheduleStore: ScheduleStore

    @State private var showingImportSheet = false
    @State private var showingManualSheet = false
    @State private var showingReport = false
    @State private var reportLines: [String] = []
    @State private var isBatching = false

    var body: some View {
        NavigationStack {
            List {
                if scheduleStore.items.isEmpty {
                    Text("No scheduled jobs")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(scheduleStore.items) { item in
                        VStack(alignment: .leading) {
                            Text(item.ownerName)
                                .font(.headline)
                            Text(item.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(item.scope)
                                .font(.caption)
                            Text(item.date, style: .date) + Text(" ") + Text(item.date, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            if let lat = item.latitude, let lon = item.longitude {
                                Text(String(format: "Lat: %.5f Lon: %.5f", lat, lon))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete { idx in
                        idx.map { scheduleStore.items.remove(at: $0) }
                    }
                }
            }
            .navigationTitle("Scheduling")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Import Approved Estimate") { showingImportSheet = true }
                        Button("Add Manual Job") { showingManualSheet = true }
                        Button {
                            isBatching = true
                            scheduleStore.batchGeocodeAllAndReport(force: false) { lines in
                                DispatchQueue.main.async {
                                    self.reportLines = lines
                                    self.isBatching = false
                                    self.showingReport = true
                                }
                            }
                        } label: {
                            Label("Batch Geocode Missing", systemImage: "mappin.and.ellipse")
                        }
                        Button {
                            isBatching = true
                            scheduleStore.batchGeocodeAllAndReport(force: true) { lines in
                                DispatchQueue.main.async {
                                    self.reportLines = lines
                                    self.isBatching = false
                                    self.showingReport = true
                                }
                            }
                        } label: {
                            Label("Batch Geocode All", systemImage: "globe")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportEstimateSheet(estimates: estimatesStore.estimates) { estimate, date in
                    guard let est = estimate else { return }
                    let item = ScheduleItem(ownerName: est.propertyOwnerName ?? "(Unknown)", address: est.propertyAddress ?? "", scope: est.scopeOfWork, date: date, estimateID: est.id)
                    scheduleStore.add(item)
                    showingImportSheet = false
                }
            }
            .sheet(isPresented: $showingManualSheet) {
                ManualScheduleSheet { item in
                    scheduleStore.add(item)
                    showingManualSheet = false
                }
            }
            .sheet(isPresented: $showingReport) {
                NavigationStack {
                    List(reportLines, id: \.self) { line in
                        Text(line)
                            .font(.system(.body, design: .monospaced))
                    }
                    .navigationTitle(isBatching ? "Geocoding..." : "Geocode Report")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingReport = false } } }
                }
            }
        }
    }
}

struct ImportEstimateSheet: View {
    let estimates: [Estimate]
    var onAdd: (Estimate?, Date) -> Void
    @State private var selectedID: UUID? = nil
    @State private var pickDate = Date()
    var body: some View {
        NavigationStack {
            Form {
                Section("Choose approved estimate") {
                    if estimates.filter({ $0.approved }).isEmpty {
                        Text("No approved estimates available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(estimates.filter({ $0.approved })) { est in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(est.propertyOwnerName ?? "(Unknown)")
                                    Text(est.propertyAddress ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedID == est.id { Image(systemName: "checkmark") }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedID = est.id }
                        }
                    }
                }

                Section("Schedule") {
                    DatePicker("Date & Time", selection: $pickDate)
                }
            }
            .navigationTitle("Import Estimate")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Add") {
                let chosen = estimates.first(where: { $0.id == selectedID })
                onAdd(chosen, pickDate)
            } } }
        }
    }
}

struct ManualScheduleSheet: View {
    var onSave: (ScheduleItem) -> Void
    @State private var owner = ""
    @State private var address = ""
    @State private var scope = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Property Owner", text: $owner)
                TextField("Address", text: $address)
                TextField("Scope of Work", text: $scope)
                DatePicker("Date & Time", selection: $date)
            }
            .navigationTitle("New Schedule")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") {
                let item = ScheduleItem(ownerName: owner.isEmpty ? "(Unknown)" : owner, address: address, scope: scope, date: date)
                onSave(item)
            } } }
        }
    }
}

struct SchedulingView_Previews: PreviewProvider {
    static var previews: some View {
        SchedulingView()
    }
}
