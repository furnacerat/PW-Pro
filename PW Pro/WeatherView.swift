import SwiftUI

struct WeatherView: View {
    @EnvironmentObject var scheduleStore: ScheduleStore
    @StateObject private var weatherStore = WeatherStore()
    @State private var zip: String = UserDefaults.standard.string(forKey: "DefaultZip") ?? ""

    var todaysItems: [ScheduleItem] {
        scheduleStore.items.filter { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Location")) {
                    HStack {
                        TextField("ZIP code", text: $zip)
                            .keyboardType(.numberPad)
                        Button("Fetch") {
                            weatherStore.fetch(zip: zip)
                        }
                    }
                    Button("Save as default") {
                        UserDefaults.standard.set(zip, forKey: "DefaultZip")
                    }
                }

                Section(header: Text("Current Conditions")) {
                    if weatherStore.isLoading {
                        HStack { ProgressView(); Text("Loading...") }
                    } else if let w = weatherStore.current {
                        VStack(alignment: .leading) {
                            Text("Temperature: \(Int(w.temperatureF))°F")
                            Text("Wind: \(String(format: "%.1f", w.windSpeedMph)) mph")
                            if let d = w.description { Text(d.capitalized) }
                            if let t = weatherStore.lastUpdated { Text("Updated: \(t.formatted())") }
                        }
                    } else {
                        Text("No weather data. Enter ZIP and fetch.")
                    }
                }

                Section(header: Text("Today's Schedule (\(todaysItems.count))")) {
                    if todaysItems.isEmpty {
                        Text("No jobs scheduled for today.")
                    } else {
                        ForEach(todaysItems) { item in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(item.ownerName).bold()
                                    Spacer()
                                    Text(item.date, style: .time)
                                }
                                Text(item.address).font(.subheadline).foregroundColor(.secondary)
                                let suggestion = evaluate(item: item, with: weatherStore.current)
                                HStack {
                                    Text(suggestion.message)
                                        .foregroundColor(suggestion.isRecommended ? .green : .red)
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
        .navigationTitle("Weather & Schedule")
        .onAppear {
            if weatherStore.current == nil, let def = UserDefaults.standard.string(forKey: "DefaultZip") {
                zip = def
                weatherStore.fetch(zip: def)
            }
        }
    }

    func evaluate(item: ScheduleItem, with weather: WeatherSnapshot?) -> (isRecommended: Bool, message: String) {
        guard let w = weather else { return (true, "No weather data; use judgment") }
        let scope = item.scope.lowercased()
        let isRoof = scope.contains("roof") || scope.contains("roof wash")

        if isRoof {
            if w.windSpeedMph >= 15 {
                return (false, "Not recommended: wind \(Int(w.windSpeedMph)) mph — risk of overspray")
            }
            if w.temperatureF >= 100 {
                return (false, "Not recommended: high temp \(Int(w.temperatureF))°F — evaporation risk")
            }
            return (true, "Conditions look good for roof work")
        } else {
            if w.windSpeedMph >= 20 {
                return (false, "High wind \(Int(w.windSpeedMph)) mph — caution recommended")
            }
            if w.temperatureF >= 105 {
                return (false, "Extreme heat \(Int(w.temperatureF))°F — caution recommended")
            }
            return (true, "Conditions look acceptable")
        }
    }
}

struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        let store = ScheduleStore()
        store.items = [ScheduleItem(ownerName: "Test", address: "123 Main", scope: "Roof wash", date: Date())]
        return NavigationView { WeatherView().environmentObject(store) }
    }
}
