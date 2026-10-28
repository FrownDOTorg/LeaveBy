import SwiftUI
import MapKit

struct PlacePicker: View {
    let showsShortcuts: Bool
    let title: String
    let onSelect: (SavedPlace) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var location = CurrentPlace()
    @FocusState private var keyboardFocused: Bool
    @State private var favorites = FavoritePlaces.load()
    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var searching = false
    @State private var message: String?

    init(title: String, initialQuery: String = "", showsShortcuts: Bool = true, onSelect: @escaping (SavedPlace) -> Void) {
        self.showsShortcuts = showsShortcuts
        self.title = title
        self.onSelect = onSelect
        self._query = State(initialValue: initialQuery)
    }

    var body: some View {
        NavigationStack {
            List {
                if showsShortcuts {
                    Section("Quick places") {
                        Button { keyboardFocused = false; location.request() } label: {
                            if location.busy { ProgressView("Finding you...") }
                            else { Label("Use My Location", systemImage: "location.fill") }
                        }.disabled(location.busy)
                        if let message = location.message { Text(message).font(.footnote).foregroundStyle(LeaveByColors.muted) }
                        ForEach(FavoritePlaces.names, id: \.self) { name in
                            if let place = favorites[name] {
                                Button(name) { onSelect(place); dismiss() }
                            }
                        }
                        NavigationLink("Set up Home, Work & Gym") { FavoritePlacesView() }
                    }.listRowBackground(LeaveByColors.card)
                }

                Section {
                    TextField("Address or place, including city", text: $query).focused($keyboardFocused)
                        .onSubmit { Task { await search() } }
                        .disabled(searching)
                    Button("Search Apple Maps") { Task { await search() } }
                        .disabled(searching || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } footer: {
                    Text("Include a city or full address, then choose the correct result. Searches are sent to Apple Maps.")
                }
                .listRowBackground(LeaveByColors.card)
                if searching { ProgressView("Searching…") }
                if let message { Text(message).foregroundStyle(LeaveByColors.muted) }
                ForEach(results.indices, id: \.self) { index in
                    let item = results[index]
                    Button {
                        onSelect(SavedPlace(item: item))
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "Place").foregroundStyle(LeaveByColors.text)
                            Text(item.placemark.title ?? "")
                                .font(.caption).foregroundStyle(LeaveByColors.muted)
                        }
                    }
                }
                .listRowBackground(LeaveByColors.card)
            }
            .onAppear { favorites = FavoritePlaces.load() }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: location.place) { _, place in if let place { onSelect(place); dismiss() } }
            .leaveByColors()
            .navigationTitle(title)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Hide keyboard") { keyboardFocused = false } }
                ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            } }
        }
    }

    @MainActor private func search() async {
        let submitted = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submitted.isEmpty, !searching else { return }
        searching = true
        results = []
        message = nil
        defer { searching = false }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = submitted
        do {
            let response = try await MKLocalSearch(request: request).start()
            results = response.mapItems
            if results.isEmpty { message = "No matches just yet. Try adding the street address and city." }
        } catch {
            message = "We couldn't reach Apple Maps just now. Check your connection, then give it another try."
        }
    }
}
