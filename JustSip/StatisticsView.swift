import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Query(sort: [SortDescriptor(\CoffeeEntry.date, order: .reverse)])
    private var entries: [CoffeeEntry]

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.firstWeekday = 2
        return calendar
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.justSipBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        summaryCard
                        weekCard
                        moodCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("统计")
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日咖啡数量")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(todayCount)")
                    .font(.system(size: 46, weight: .bold, design: .rounded))

                Text("杯")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(todayCount == 0 ? "今天还没有新增咖啡记录" : "今天已经记录了 \(todayCount) 杯咖啡")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("本周咖啡记录")
                .font(.headline)

            Text("按本周每天的记录数简单统计")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(weekStats) { stat in
                    VStack(spacing: 8) {
                        Text("\(stat.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(stat.count == 0 ? Color.justSipMutedFill : Color.justSipAccent.opacity(0.82))
                            .frame(height: stat.barHeight)

                        Text(stat.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 148, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
    }

    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("心情分布")
                .font(.headline)

            if moodStats.isEmpty {
                Text("还没有记录")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("基于已有记录做简单汇总")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                    ForEach(moodStats) { stat in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(stat.emoji) \(stat.count) 次")
                                .font(.headline)

                            Text(stat.title)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.justSipInsetBackground)
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
    }

    private var todayCount: Int {
        entries.filter { calendar.isDateInToday($0.date) }.count
    }

    private var weekStats: [WeekStat] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: .now) else {
            return []
        }

        let counts = (0..<7).compactMap { dayOffset -> WeekStat? in
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekInterval.start) else {
                return nil
            }

            let count = entries.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
            let label = date.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "zh_CN")))
            return WeekStat(label: label, count: count)
        }

        let maxCount = max(counts.map(\.count).max() ?? 0, 1)
        return counts.map { WeekStat(label: $0.label, count: $0.count, maxCount: maxCount) }
    }

    private var moodStats: [MoodStat] {
        let grouped = Dictionary(grouping: entries, by: \.localizedMood)

        return grouped
            .map { key, value in
                MoodStat(title: key, emoji: value.first?.localizedMoodEmoji ?? "🙂", count: value.count)
            }
            .sorted { $0.count > $1.count }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.justSipCardBackground)
            .shadow(color: Color.justSipShadowColor, radius: 10, x: 0, y: 4)
    }
}

private struct WeekStat: Identifiable {
    let label: String
    let count: Int
    var maxCount: Int = 1

    var id: String { label }

    var barHeight: CGFloat {
        let ratio = CGFloat(count) / CGFloat(max(maxCount, 1))
        return max(count == 0 ? 10 : 18, 92 * ratio)
    }
}

private struct MoodStat: Identifiable {
    let title: String
    let emoji: String
    let count: Int

    var id: String { title }
}
