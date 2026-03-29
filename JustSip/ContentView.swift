import SwiftUI
import SwiftData
import UserNotifications
import UIKit

struct ContentView: View {
    @State private var isPresentingAddEntry = false
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(AppTab.home)
                .tabItem {
                    Label("首页", systemImage: "house")
                }

            StatisticsView()
                .tag(AppTab.statistics)
                .tabItem {
                    Label("统计", systemImage: "chart.bar")
                }

            ProfileView()
                .tag(AppTab.profile)
                .tabItem {
                    Label("我的", systemImage: "person")
                }
        }
        .overlay(alignment: .bottom) {
            if selectedTab == .home {
                addEntryButton
                    .padding(.bottom, 64)
            }
        }
        .sheet(isPresented: $isPresentingAddEntry) {
            AddEntryView()
        }
    }

    private var addEntryButton: some View {
        Button {
            isPresentingAddEntry = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.justSipAccent)
                        .shadow(color: Color.justSipShadowColor.opacity(0.9), radius: 12, x: 0, y: 6)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("新增咖啡记录")
    }
}

private enum AppTab {
    case home
    case statistics
    case profile
}

private struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: [SortDescriptor(\CoffeeEntry.date, order: .reverse)])
    private var entries: [CoffeeEntry]
    @AppStorage("coffeeReminderEnabled") private var reminderEnabled = false
    @AppStorage("coffeeReminderHour") private var reminderHour = 9
    @AppStorage("coffeeReminderMinute") private var reminderMinute = 30
    @State private var entryToEdit: CoffeeEntry?
    @State private var isPresentingReminderSheet = false
    @State private var reminderAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    private let entryInsertionTransition = AnyTransition.offset(x: 0, y: 18).combined(with: .opacity)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.justSipBackground
                    .ignoresSafeArea()

                Group {
                    if entries.isEmpty {
                        ScrollView {
                            VStack(spacing: 16) {
                                TodayOverviewCard(summary: todayOverview)
                                emptyState
                            }
                            .padding(20)
                        }
                    } else {
                        List {
                            Section {
                                TodayOverviewCard(summary: todayOverview)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)

                                ForEach(todayEntries) { entry in
                                    CoffeeEntryRow(entry: entry)
                                        .transition(.asymmetric(insertion: entryInsertionTransition, removal: .opacity))
                                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .swipeActions(allowsFullSwipe: false) {
                                            Button("删除", role: .destructive) {
                                                deleteEntry(entry)
                                            }

                                            Button("编辑") {
                                                entryToEdit = entry
                                            }
                                            .tint(Color.justSipAccent)
                                        }
                                }
                                .onDelete { offsets in
                                    deleteEntries(at: offsets, from: todayEntries)
                                }
                            } header: {
                                sectionHeader("今天")
                            }

                            ForEach(pastSections) { section in
                                Section {
                                    ForEach(section.entries) { entry in
                                        CoffeeEntryRow(entry: entry)
                                            .transition(.asymmetric(insertion: entryInsertionTransition, removal: .opacity))
                                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                            .swipeActions(allowsFullSwipe: false) {
                                                Button("删除", role: .destructive) {
                                                    deleteEntry(entry)
                                                }

                                                Button("编辑") {
                                                    entryToEdit = entry
                                                }
                                                .tint(Color.justSipAccent)
                                            }
                                    }
                                    .onDelete { offsets in
                                        deleteEntries(at: offsets, from: section.entries)
                                    }
                                } header: {
                                    sectionHeader(section.title)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .listSectionSpacing(12)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .animation(.snappy(duration: 0.24, extraBounce: 0), value: entryAnimationIDs)
                    }
                }
            }
            .navigationTitle("咖一下")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingReminderSheet = true
                    } label: {
                        Image(systemName: reminderEnabled ? "bell.badge.fill" : "bell")
                            .foregroundStyle(reminderEnabled ? Color.justSipAccent : .primary)
                    }
                    .accessibilityLabel(reminderEnabled ? "已开启咖啡提醒" : "设置咖啡提醒")
                }
            }
            .sheet(item: $entryToEdit) { entry in
                AddEntryView(entryToEdit: entry)
            }
            .sheet(isPresented: $isPresentingReminderSheet) {
                reminderSheet
            }
            .task {
                await refreshReminderAuthorization()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else {
                    return
                }

                Task {
                    await refreshReminderAuthorization()
                }
            }
            .onChange(of: reminderTimeKey) { _, _ in
                Task {
                    await rescheduleReminderIfNeeded()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("☕")
                .font(.system(size: 42))

            Text("还没有咖啡记录 ☕️")
                .font(.title3.weight(.semibold))

            Text("喝下第一杯，开始记录今天的咖啡时刻。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    private var todayEntries: [CoffeeEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDateInToday($0.date) }
    }

    private var pastSections: [EntrySection] {
        let calendar = Calendar.current
        var yesterdayEntries: [CoffeeEntry] = []
        var earlierEntries: [CoffeeEntry] = []

        for entry in entries {
            if calendar.isDateInYesterday(entry.date) {
                yesterdayEntries.append(entry)
            } else if !calendar.isDateInToday(entry.date) {
                earlierEntries.append(entry)
            }
        }

        return [
            EntrySection(title: "昨天", entries: yesterdayEntries),
            EntrySection(title: "更早", entries: earlierEntries),
        ]
        .filter { !$0.entries.isEmpty }
    }

    private var todayOverview: TodayOverview {
        let streak = entries.streakSummary()

        guard let latestTodayEntry = todayEntries.first else {
            return TodayOverview(
                coffeeCount: 0,
                moodEmoji: "🙂",
                moodText: "暂无记录",
                streakDays: streak.days,
                hasRecordedToday: streak.hasRecordedToday
            )
        }

        return TodayOverview(
            coffeeCount: todayEntries.count,
            moodEmoji: latestTodayEntry.localizedMoodEmoji,
            moodText: latestTodayEntry.localizedMood,
            streakDays: streak.days,
            hasRecordedToday: streak.hasRecordedToday
        )
    }

    private var entryAnimationIDs: [UUID] {
        entries.map(\.id)
    }

    private var reminderCard: some View {
        CoffeeReminderCard(
            isEnabled: reminderEnabled,
            authorizationStatus: reminderAuthorizationStatus,
            reminderTime: reminderDate,
            timeText: formattedReminderTime,
            toggleBinding: Binding(
                get: { reminderEnabled },
                set: { newValue in
                    Task {
                        await updateReminderEnabled(newValue)
                    }
                }
            ),
            openSettings: openSystemSettings
        )
    }

    private var reminderSheet: some View {
        NavigationStack {
            ZStack {
                Color.justSipBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        reminderCard

                        VStack(alignment: .leading, spacing: 10) {
                            Text("提醒说明")
                                .font(.headline.weight(.semibold))

                            Text("开启后，App 会在你设定的时间提醒你喝咖啡，也方便你顺手完成当天记录。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.justSipCardBackground)
                                .shadow(color: Color.justSipShadowColor, radius: 10, x: 0, y: 4)
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("咖啡提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        isPresentingReminderSheet = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var reminderDate: Binding<Date> {
        Binding(
            get: {
                let calendar = Calendar.current
                return calendar.date(
                    bySettingHour: reminderHour,
                    minute: reminderMinute,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = components.hour ?? 9
                reminderMinute = components.minute ?? 30
            }
        )
    }

    private var reminderTimeKey: String {
        "\(reminderHour):\(reminderMinute)"
    }

    private var formattedReminderTime: String {
        let calendar = Calendar.current
        let date = calendar.date(
            bySettingHour: reminderHour,
            minute: reminderMinute,
            second: 0,
            of: .now
        ) ?? .now

        return date.formatted(.dateTime.hour().minute().locale(Locale(identifier: "zh_CN")))
    }

    private func deleteEntries(at offsets: IndexSet, from sectionEntries: [CoffeeEntry]) {
        for index in offsets {
            modelContext.delete(sectionEntries[index])
        }

        do {
            try modelContext.save()
        } catch {
            // Keep the interaction simple for now; if saving fails, the list stays as-is.
        }
    }

    private func deleteEntry(_ entry: CoffeeEntry) {
        modelContext.delete(entry)

        do {
            try modelContext.save()
        } catch {
            // Keep the interaction simple for now; if saving fails, the list stays as-is.
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
            .padding(.leading, 2)
    }

    private func updateReminderEnabled(_ newValue: Bool) async {
        if newValue {
            let isAuthorized = await CoffeeReminderScheduler.requestAuthorizationIfNeeded()
            let latestStatus = await CoffeeReminderScheduler.authorizationStatus()

            await MainActor.run {
                reminderAuthorizationStatus = latestStatus
            }

            guard isAuthorized else {
                await MainActor.run {
                    reminderEnabled = false
                }
                return
            }

            do {
                try await CoffeeReminderScheduler.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
                await MainActor.run {
                    reminderEnabled = true
                }
            } catch {
                await MainActor.run {
                    reminderEnabled = false
                }
            }
        } else {
            CoffeeReminderScheduler.cancelReminder()
            await MainActor.run {
                reminderEnabled = false
            }
        }
    }

    private func refreshReminderAuthorization() async {
        let status = await CoffeeReminderScheduler.authorizationStatus()

        await MainActor.run {
            reminderAuthorizationStatus = status

            if status != .authorized && status != .provisional && reminderEnabled {
                reminderEnabled = false
            }
        }
    }

    private func rescheduleReminderIfNeeded() async {
        guard reminderEnabled else {
            return
        }

        let status = await CoffeeReminderScheduler.authorizationStatus()
        guard status == .authorized || status == .provisional else {
            return
        }

        try? await CoffeeReminderScheduler.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
    }

    private func openSystemSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(settingsURL)
    }
}

private struct EntrySection: Identifiable {
    let title: String
    let entries: [CoffeeEntry]

    var id: String { title }
}

private struct TodayOverview {
    let coffeeCount: Int
    let moodEmoji: String
    let moodText: String
    let streakDays: Int
    let hasRecordedToday: Bool

    var energyLevel: CoffeeEnergyLevel {
        CoffeeEnergyLevel(coffeeCount: coffeeCount)
    }
}

private struct TodayOverviewCard: View {
    let summary: TodayOverview

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            energySection

            HStack(spacing: 12) {
                overviewItem(title: "今日已喝", value: "☕️ \(summary.coffeeCount) 杯")

                Divider()

                overviewItem(title: "当前心情", value: "\(summary.moodEmoji) \(summary.moodText)")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("🔥 连续 \(summary.streakDays) 天")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.justSipAccent)

                if !summary.hasRecordedToday {
                    Text("今天还没喝咖啡哦")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.justSipInsetBackground)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.justSipOverviewBackground)
        )
    }

    private var energySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日咖啡能量")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(summary.energyLevel.title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(summary.energyLevel.tint)
                }

                Spacer()

                Text("\(summary.coffeeCount) 点")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.justSipTrackBackground)

                    Capsule(style: .continuous)
                        .fill(summary.energyLevel.tint)
                        .frame(width: max(0, proxy.size.width * summary.energyLevel.progress))
                }
            }
            .frame(height: 12)

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < min(summary.coffeeCount, 3) ? "cup.and.saucer.fill" : "cup.and.saucer")
                        .font(.body)
                        .foregroundStyle(index < min(summary.coffeeCount, 3) ? summary.energyLevel.tint : .secondary.opacity(0.35))
                }

                Text(summary.energyLevel.message)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.justSipInsetBackground)
        )
    }

    private func overviewItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CoffeeEnergyLevel {
    let title: String
    let message: String
    let tint: Color
    let progress: CGFloat

    init(coffeeCount: Int) {
        switch coffeeCount {
        case 3...:
            title = "高能量"
            message = "火力全开，今天状态很满"
            tint = Color.justSipAccent
            progress = 1.0
        case 2:
            title = "正常"
            message = "节奏刚刚好，继续保持"
            tint = Color.justSipAccent.opacity(0.82)
            progress = 2.0 / 3.0
        case 1:
            title = "低能量"
            message = "已经启动，慢慢进入状态"
            tint = Color.justSipAccent.opacity(0.62)
            progress = 1.0 / 3.0
        default:
            title = "待充能"
            message = "还没开喝，今天来一杯吧"
            tint = Color.secondary.opacity(0.35)
            progress = 0
        }
    }
}

private struct CoffeeReminderCard: View {
    let isEnabled: Bool
    let authorizationStatus: UNAuthorizationStatus
    let reminderTime: Binding<Date>
    let timeText: String
    let toggleBinding: Binding<Bool>
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("每日咖啡提醒")
                        .font(.headline.weight(.semibold))

                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Toggle("", isOn: toggleBinding)
                    .labelsHidden()
                    .tint(Color.justSipAccent)
            }

            HStack(spacing: 12) {
                Label("提醒时间", systemImage: "bell.badge")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer()

                DatePicker(
                    "",
                    selection: reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .disabled(!canAdjustTime)
                .opacity(canAdjustTime ? 1.0 : 0.5)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.justSipInsetBackground)
            )

            if authorizationStatus == .denied {
                Button {
                    openSettings()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.footnote.weight(.semibold))

                        Text("去系统设置开启通知")
                            .font(.footnote.weight(.semibold))
                    }
                    .foregroundStyle(Color.justSipAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.justSipCardBackground)
                .shadow(color: Color.justSipShadowColor, radius: 10, x: 0, y: 4)
        )
    }

    private var canAdjustTime: Bool {
        authorizationStatus != .denied
    }

    private var statusText: String {
        if authorizationStatus == .denied {
            return "通知权限未开启，请到系统设置中允许提醒"
        }

        if isEnabled {
            return "已设置每天 \(timeText) 提醒你喝杯咖啡"
        }

        return "打开后，每天会在固定时间提醒你来一杯"
    }
}

private enum CoffeeReminderScheduler {
    static let identifier = "justsip.daily.coffee.reminder"

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let status = await authorizationStatus()

        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return await requestAuthorization()
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    static func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        cancelReminder()

        let content = UNMutableNotificationContent()
        content.title = "咖啡时间到了 ☕️"
        content.body = "别忘了来一杯喜欢的咖啡，也顺手记录一下今天的状态。"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    static func cancelReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}

private struct CoffeeEntryRow: View {
    let entry: CoffeeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("☕ \(entry.localizedCoffeeType)")
                    .font(.headline)

                Spacer()

                Text(entry.relativeTimestamp)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("\(entry.localizedMoodEmoji) \(entry.localizedMood)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let note = entry.displayNote {
                Text(note)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.justSipCardBackground)
                .shadow(color: Color.justSipShadowColor, radius: 10, x: 0, y: 4)
        )
    }
}

extension CoffeeEntry {
    var localizedCoffeeType: String {
        switch coffeeType {
        case "Latte":
            return "Latte（拿铁）"
        case "Americano":
            return "Americano（美式）"
        case "Cappuccino":
            return "Cappuccino（卡布奇诺）"
        case "Mocha":
            return "Mocha（摩卡）"
        case "Other":
            return "Other（其他）"
        default:
            return coffeeType
        }
    }

    var localizedMoodEmoji: String {
        switch mood {
        case "Happy", "开心":
            return "😊"
        case "Relaxed", "放松":
            return "😌"
        case "Sleepy", "困":
            return "😴"
        case "Tired", "累":
            return "😵"
        case "Anxious", "焦虑":
            return "😤"
        default:
            return "🙂"
        }
    }

    var localizedMood: String {
        switch mood {
        case "Happy", "开心":
            return "开心"
        case "Relaxed", "放松":
            return "放松"
        case "Sleepy", "困":
            return "困"
        case "Tired", "累":
            return "累"
        case "Anxious", "焦虑":
            return "焦虑"
        default:
            return mood
        }
    }

    var displayNote: String? {
        guard let note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return note
    }

    var relativeTimestamp: String {
        let calendar = Calendar.current
        let timeText = date.formatted(.dateTime.hour().minute().locale(Locale(identifier: "zh_CN")))

        if calendar.isDateInToday(date) {
            return "今天 \(timeText)"
        }

        if calendar.isDateInYesterday(date) {
            return "昨天 \(timeText)"
        }

        return date.formatted(.dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_CN")))
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.makeContainer())
}

private enum PreviewSampleData {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([CoffeeEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)

            sampleEntries.forEach { context.insert($0) }

            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }

    static let sampleEntries: [CoffeeEntry] = [
        CoffeeEntry(
            date: Calendar.current.date(byAdding: .minute, value: -20, to: .now) ?? .now,
            coffeeType: "Latte",
            mood: "开心",
            note: "今天阳光很好，先来一杯热拿铁。"
        ),
        CoffeeEntry(
            date: Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now,
            coffeeType: "Americano",
            mood: "累",
            note: "下午开会前，先补一点精神。"
        ),
        CoffeeEntry(
            date: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
            coffeeType: "Cappuccino",
            mood: "放松",
            note: "周末慢慢喝，整个人都松弛下来。"
        ),
        CoffeeEntry(
            date: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now,
            coffeeType: "Mocha",
            mood: "焦虑",
            note: "事情有点多，甜一点会安心些。"
        ),
        CoffeeEntry(
            date: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now,
            coffeeType: "Other",
            mood: "困",
            note: nil
        ),
    ]
}
