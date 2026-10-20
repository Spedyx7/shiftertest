import SwiftUI

struct MonthStats {
    var hours: Double = 0
    var nights: Int = 0
    var counts: [String: Int] = [:]
}

final class ShiftStore: ObservableObject {
    /// "yyyy-MM-dd" -> shift type id
    @Published private(set) var assignments: [String: String] = [:]

    let types: [ShiftType] = ShiftType.defaults

    private let saveKey = "assignments.v1"

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    init() {
        load()
    }

    func key(for date: Date) -> String {
        ShiftStore.keyFormatter.string(from: date)
    }

    func shift(on date: Date) -> ShiftType? {
        guard let id = assignments[key(for: date)] else { return nil }
        return types.first { $0.id == id }
    }

    func set(_ typeID: String?, on date: Date) {
        let k = key(for: date)
        if let typeID = typeID {
            assignments[k] = typeID
        } else {
            assignments.removeValue(forKey: k)
        }
        save()
    }

    func applyPattern(slots: [String?], start: Date, days: Int) {
        guard !slots.isEmpty, days > 0 else { return }
        let cal = Calendar.app
        let first = cal.startOfDay(for: start)
        var copy = assignments
        for i in 0..<days {
            guard let d = cal.date(byAdding: .day, value: i, to: first) else { continue }
            let k = key(for: d)
            if let id = slots[i % slots.count] {
                copy[k] = id
            } else {
                copy.removeValue(forKey: k)
            }
        }
        assignments = copy
        save()
    }

    func clearMonth(_ monthStart: Date) {
        let cal = Calendar.app
        guard let range = cal.range(of: .day, in: .month, for: monthStart) else { return }
        var copy = assignments
        for d in range {
            if let date = cal.date(byAdding: .day, value: d - 1, to: monthStart) {
                copy.removeValue(forKey: key(for: date))
            }
        }
        assignments = copy
        save()
    }

    func stats(forMonth monthStart: Date) -> MonthStats {
        var result = MonthStats()
        let cal = Calendar.app
        guard let range = cal.range(of: .day, in: .month, for: monthStart) else { return result }
        for d in range {
            guard let date = cal.date(byAdding: .day, value: d - 1, to: monthStart),
                  let s = shift(on: date) else { continue }
            result.hours += s.hours
            if s.isNight { result.nights += 1 }
            result.counts[s.id, default: 0] += 1
        }
        return result
    }

    private func save() {
        if let data = try? JSONEncoder().encode(assignments) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else { return }
        assignments = decoded
    }
}
