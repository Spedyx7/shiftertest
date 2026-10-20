import SwiftUI

struct DayID: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSince1970 }
}

struct CalendarView: View {
    @EnvironmentObject var store: ShiftStore

    @State private var monthStart = Calendar.app.startOfMonth(for: Date())
    @State private var editingDay: DayID?
    @State private var showPattern = false
    @State private var confirmClear = false

    private let cal = Calendar.app
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var days: [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: monthStart) else { return [] }
        let weekday = cal.component(.weekday, from: monthStart)
        let offset = (weekday - cal.firstWeekday + 7) % 7
        var result: [Date?] = Array(repeating: nil, count: offset)
        for d in range {
            if let date = cal.date(byAdding: .day, value: d - 1, to: monthStart) {
                result.append(date)
            }
        }
        return result
    }

    private var weekdayHeaders: [String] {
        let symbols = cal.shortWeekdaySymbols
        let shift = cal.firstWeekday - 1
        return Array(symbols[shift...]) + Array(symbols[..<shift])
    }

    var body: some View {
        let stats = store.stats(forMonth: monthStart)

        ScrollView {
            VStack(spacing: 12) {
                header

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(weekdayHeaders, id: \.self) { name in
                        Text(name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(days.enumerated()), id: \.offset) { item in
                        if let date = item.element {
                            DayCell(
                                date: date,
                                shift: store.shift(on: date),
                                isToday: cal.isDateInToday(date)
                            )
                            .onTapGesture {
                                editingDay = DayID(date: date)
                            }
                        } else {
                            Color.clear.frame(minHeight: 56)
                        }
                    }
                }

                statsCard(stats)
            }
            .padding()
        }
        .navigationTitle("Shifts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Today") {
                    monthStart = cal.startOfMonth(for: Date())
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showPattern = true
                    } label: {
                        Label("Fill with pattern", systemImage: "repeat")
                    }
                    Button(role: .destructive) {
                        confirmClear = true
                    } label: {
                        Label("Clear this month", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $editingDay) { day in
            DayEditor(date: day.date)
        }
        .sheet(isPresented: $showPattern) {
            PatternView()
        }
        .confirmationDialog("Clear all shifts in this month?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear month", role: .destructive) {
                store.clearMonth(monthStart)
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private var header: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding(8)
            }

            Spacer()

            Text(monthStart.formatted(.dateTime.month(.wide).year()))
                .font(.title2.bold())

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .padding(8)
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = cal.date(byAdding: .month, value: value, to: monthStart) {
            monthStart = newMonth
        }
    }

    private func statsCard(_ stats: MonthStats) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This month")
                .font(.headline)

            HStack {
                Text("Hours")
                Spacer()
                Text("\(Int(stats.hours.rounded())) h").bold()
            }
            HStack {
                Text("Night shifts")
                Spacer()
                Text("\(stats.nights)").bold()
            }

            Divider()

            ForEach(store.types) { t in
                if let count = stats.counts[t.id], count > 0 {
                    HStack {
                        Circle().fill(t.color).frame(width: 10, height: 10)
                        Text(t.name)
                        Spacer()
                        Text("\(count)")
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DayCell: View {
    let date: Date
    let shift: ShiftType?
    let isToday: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.app.component(.day, from: date))")
                .font(.subheadline.weight(isToday ? .bold : .regular))
                .foregroundStyle(isToday ? Color.white : Color.primary)
                .frame(width: 26, height: 26)
                .background(Circle().fill(isToday ? Color.accentColor : Color.clear))

            if let shift = shift {
                Text(shift.shortLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(shift.color.opacity(0.9), in: RoundedRectangle(cornerRadius: 5))
            } else {
                Spacer().frame(height: 16)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .contentShape(Rectangle())
    }
}

struct DayEditor: View {
    @EnvironmentObject var store: ShiftStore
    @Environment(\.dismiss) private var dismiss

    let date: Date

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.types) { t in
                    Button {
                        store.set(t.id, on: date)
                        dismiss()
                    } label: {
                        HStack {
                            Circle().fill(t.color).frame(width: 14, height: 14)
                            VStack(alignment: .leading) {
                                Text(t.name)
                                if t.isWork {
                                    Text("\(Int(t.hours)) h")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if store.shift(on: date)?.id == t.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Button("Clear day", role: .destructive) {
                    store.set(nil, on: date)
                    dismiss()
                }
            }
            .navigationTitle(date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
