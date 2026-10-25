import SwiftUI
import MapKit

struct PlacePicker: View {
    let title: String
    let onSelect: (SavedPlace) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var searching = false
    @State private var message: String?

    init(title: String, initialQuery: String = "", onSelect: @escaping (SavedPlace) -> Void) {
        self.title = title
        self.onSelect = onSelect
        self._query = State(initialValue: initialQuery)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Address or place, including city", text: $query)
                        .onSubmit { Task { await search() } }
                        .disabled(searching)
                    Button("Search Apple Maps") { Task { await search() } }
                        .disabled(searching || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } footer: {
                    Text("Include a city or full address, then choose the correct result. Searches are sent to Apple Maps.")
                }
                if searching { ProgressView("Searching…") }
                if let message { Text(message).foregroundStyle(.secondary) }
                ForEach(results.indices, id: \.self) { index in
                    let item = results[index]
                    Button {
                        onSelect(SavedPlace(item: item))
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "Place").foregroundStyle(.primary)
                            Text(item.placemark.title ?? "")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar { ToolbarItem(placement: .cancellationAction) {
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
