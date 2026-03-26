import Foundation
import SwiftData

@Model
final class CoffeeEntry {
    var id: UUID
    var date: Date
    var coffeeType: String
    var mood: String
    var note: String?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        coffeeType: String,
        mood: String,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.coffeeType = coffeeType
        self.mood = mood
        self.note = note
    }
}

struct CoffeeStreakSummary {
    let days: Int
    let hasRecordedToday: Bool
}

extension Collection where Element == CoffeeEntry {
    func streakSummary(
        calendar: Calendar = .current,
        referenceDate: Date = .now
    ) -> CoffeeStreakSummary {
        let recordedDays = Set(map { calendar.startOfDay(for: $0.date) })
        let today = calendar.startOfDay(for: referenceDate)
        let hasRecordedToday = recordedDays.contains(today)

        let anchorDay: Date
        if hasRecordedToday {
            anchorDay = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  recordedDays.contains(yesterday) {
            anchorDay = yesterday
        } else {
            return CoffeeStreakSummary(days: 0, hasRecordedToday: false)
        }

        var streakDays = 0
        var currentDay = anchorDay

        while recordedDays.contains(currentDay) {
            streakDays += 1

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else {
                break
            }

            currentDay = previousDay
        }

        return CoffeeStreakSummary(days: streakDays, hasRecordedToday: hasRecordedToday)
    }
}
