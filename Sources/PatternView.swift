import SwiftUI

struct PatternSlot: Identifiable {
    let id = UUID()
    var shiftID: String?
}

struct PatternView: View {
    @EnvironmentObject var store: ShiftStore
    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Date()
    @State private var days = 28
    @State private var slots: [PatternSlot] = [PatternSlot(shiftID: nil)]

    var body: some View {
        NavigationStack {
            Form {
                Section("Start") {
                    DatePicker("First day of cycle", selection: $startDate, displayedComponents: .date)
                }

                Section {
                    ForEach($slots) { $slot in
                        Picker("Day \(dayNumber(of: slot))", selection: $slot.shiftID) {
                            Text("Off").tag(String?.none)
                            ForEach(store.types) { t in
                                Text(t.name).tag(Optional(t.id))
                            }
                        }
                    }
                    .onDelete { offsets in
                        slots.remove(atOffsets: offsets)
                    }

                    Button {
                        slots.append(PatternSlot(shiftID: nil))
                    } label: {
                        Label("Add day to cycle", systemImage: "plus")
                    }
                } header: {
                    Text("Cycle (one row per day)")
                } footer: {
                    Text("Example: two Morning rows, two Night rows, then four Off rows. The cycle repeats from the start date. Swipe a row to delete it.")
                }

                Section("Length") {
                    Stepper("Fill \(days) days", value: $days, in: 1...365)
                }

                Section {
                    Button("Apply pattern") {
                        store.applyPattern(
                            slots: slots.map { $0.shiftID },
                            start: startDate,
                            days: days
                        )
                        dismiss()
                    }
                    .disabled(slots.isEmpty)
                } footer: {
                    Text("This overwrites existing shifts on those days. Days set to Off are cleared.")
                }
            }
            .navigationTitle("Fill with pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func dayNumber(of slot: PatternSlot) -> Int {
        (slots.firstIndex(where: { $0.id == slot.id }) ?? 0) + 1
    }
}
