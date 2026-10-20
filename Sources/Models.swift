import SwiftUI

struct ShiftType: Identifiable, Hashable {
    let id: String
    let name: String
    let startMinutes: Int
    let endMinutes: Int
    let colorHex: String
    let isWork: Bool

    var color: Color { Color(hex: colorHex) }

    var hours: Double {
        guard isWork else { return 0 }
        var d = endMinutes - startMinutes
        if d <= 0 { d += 24 * 60 }
        return Double(d) / 60.0
    }

    var isNight: Bool {
        isWork && startMinutes >= 19 * 60
    }

    var shortLabel: String {
        guard isWork else { return name }
        return "\(ShiftType.clock(startMinutes))–\(ShiftType.clock(endMinutes))"
    }

    static func clock(_ minutes: Int) -> String {
        let h = (minutes / 60) % 24
        let m = minutes % 60
        return m == 0 ? "\(h)" : String(format: "%d:%02d", h, m)
    }

    static let defaults: [ShiftType] = [
        ShiftType(id: "d7-15", name: "Morning 7–15", startMinutes: 7 * 60, endMinutes: 15 * 60, colorHex: "#F5A623", isWork: true),
        ShiftType(id: "d15-22", name: "Afternoon 15–22", startMinutes: 15 * 60, endMinutes: 22 * 60, colorHex: "#4A90D9", isWork: true),
        ShiftType(id: "n22-7", name: "Night 22–7", startMinutes: 22 * 60, endMinutes: 7 * 60, colorHex: "#5856D6", isWork: true),
        ShiftType(id: "l7-19", name: "Long day 7–19", startMinutes: 7 * 60, endMinutes: 19 * 60, colorHex: "#2E9E6B", isWork: true),
        ShiftType(id: "n19-7", name: "Long night 19–7", startMinutes: 19 * 60, endMinutes: 7 * 60, colorHex: "#AF52DE", isWork: true),
        ShiftType(id: "leave", name: "Leave", startMinutes: 0, endMinutes: 0, colorHex: "#8E8E93", isWork: false)
    ]
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }
}

extension Calendar {
    /// Calendar with Monday as the first day of the week.
    static let app: Calendar = {
        var c = Calendar.current
        c.firstWeekday = 2
        return c
    }()

    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
