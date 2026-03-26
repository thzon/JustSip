import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("lastSelectedMood") private var lastSelectedMood = "开心"
    private let entryToEdit: CoffeeEntry?

    @State private var coffeeType = coffeeTypes[0]
    @State private var mood = moodOptions[0].title
    @State private var note = ""

    init(entryToEdit: CoffeeEntry? = nil) {
        self.entryToEdit = entryToEdit
        _coffeeType = State(initialValue: entryToEdit?.coffeeType ?? Self.coffeeTypes[0])
        _mood = State(initialValue: entryToEdit?.mood ?? Self.moodOptions[0].title)
        _note = State(initialValue: entryToEdit?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.justSipBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    customHeader

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            sectionCard(
                                title: "咖啡类型",
                                subtitle: "选择今天想认真记住的那一杯"
                            ) {
                                coffeeTypePickerRow
                            }

                            sectionCard(
                                title: "今天的心情",
                                subtitle: "让这一杯，也带一点情绪的温度"
                            ) {
                                moodPickerGrid
                            }

                            sectionCard(
                                title: "备注",
                                subtitle: "写下味道、场景，或者这一刻的小情绪"
                            ) {
                                noteEditor
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 26)
                        .padding(.bottom, 32)
                    }
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 30,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 30,
                            style: .continuous
                        )
                        .fill(Color.justSipBackground)
                        .ignoresSafeArea(edges: .bottom)
                    )
                    .offset(y: -18)
                    .padding(.bottom, -18)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                guard entryToEdit == nil else {
                    return
                }

                guard Self.moodOptions.contains(where: { $0.title == lastSelectedMood }) else {
                    return
                }
                mood = lastSelectedMood
            }
        }
    }

    private var customHeader: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top

            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color.justSipOverviewBackground,
                        Color.justSipBackground,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(.ultraThinMaterial.opacity(0.55))
                .ignoresSafeArea(edges: .top)

                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .center) {
                        Button("取消") {
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(minHeight: 36)

                        Spacer()

                        Button(entryToEdit == nil ? "保存" : "更新") {
                            saveEntry()
                        }
                        .buttonStyle(SaveCapsuleButtonStyle())
                        .disabled(!canSave)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(entryToEdit == nil ? "记录一杯咖啡 ☕️" : "更新这一杯咖啡 ☕️")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text(entryToEdit == nil ? "记录你的咖啡与心情" : "把这一刻的味道和心情重新整理一下")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.top, topInset + 16)
                .padding(.bottom, 38)
            }
        }
        .frame(height: 212, alignment: .bottom)
    }

    private var canSave: Bool {
        !coffeeType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var coffeeTypePickerRow: some View {
        Menu {
            ForEach(Self.coffeeTypes, id: \.self) { type in
                Button(Self.localizedCoffeeTypeLabel(for: type)) {
                    coffeeType = type
                }
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今天喝了什么")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("选择一种咖啡类型")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(Self.localizedCoffeeTypeLabel(for: coffeeType))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.justSipInsetBackground)
            )
        }
        .buttonStyle(.plain)
    }

    private var moodPickerGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
            ForEach(Self.moodOptions, id: \.title) { option in
                Button {
                    withAnimation(.snappy(duration: 0.18, extraBounce: 0.08)) {
                        mood = option.title
                    }
                    lastSelectedMood = option.title
                } label: {
                    VStack(spacing: 6) {
                        Text(option.emoji)
                            .font(.title3)
                            .scaleEffect(mood == option.title ? 1.08 : 1.0)

                        Text(option.title)
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, minHeight: 68)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(mood == option.title ? Color.accentColor.opacity(0.16) : Color.justSipInsetBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(mood == option.title ? Color.accentColor : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .animation(.snappy(duration: 0.18, extraBounce: 0.08), value: mood)
            }
        }
    }

    private var noteEditor: some View {
        TextField("写点什么（可选）", text: $note, axis: .vertical)
            .lineLimit(4...7)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.justSipInsetBackground)
            )
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.justSipCardBackground)
                .shadow(color: Color.justSipShadowColor, radius: 10, x: 0, y: 4)
        )
    }

    private var persistedMoodTitle: String {
        if Self.moodOptions.contains(where: { $0.title == lastSelectedMood }) {
            return lastSelectedMood
        }

        return Self.moodOptions[0].title
    }

    private func saveEntry() {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNote = trimmedNote.isEmpty ? nil : trimmedNote

        do {
            try saveEntry(coffeeType: coffeeType, mood: mood, note: normalizedNote)
            dismiss()
        } catch {
            // Keep the flow lightweight for now; if saving fails, stay on screen.
        }
    }

    private func saveEntry(coffeeType: String, mood: String, note: String?) throws {
        if let entryToEdit {
            entryToEdit.coffeeType = coffeeType
            entryToEdit.mood = mood
            entryToEdit.note = note
        } else {
            let entry = CoffeeEntry(
                date: .now,
                coffeeType: coffeeType,
                mood: mood,
                note: note
            )

            withAnimation(.snappy(duration: 0.24, extraBounce: 0)) {
                modelContext.insert(entry)
            }
        }
        try modelContext.save()
        lastSelectedMood = mood
    }
}

private struct SaveCapsuleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(isEnabled ? 1.0 : 0.72))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(isEnabled ? Color.justSipAccent : Color.justSipAccent.opacity(0.45))
                    .shadow(
                        color: isEnabled ? Color.justSipShadowColor.opacity(0.8) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .scaleEffect(configuration.isPressed && isEnabled ? 0.96 : 1.0)
            .animation(.snappy(duration: 0.16, extraBounce: 0), value: configuration.isPressed)
    }
}

private extension AddEntryView {
    static func localizedCoffeeTypeLabel(for type: String) -> String {
        switch type {
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
            return type
        }
    }

    static let coffeeTypes = [
        "Latte",
        "Americano",
        "Cappuccino",
        "Mocha",
        "Other",
    ]

    static let moodOptions = [
        MoodOption(title: "开心", emoji: "😊"),
        MoodOption(title: "放松", emoji: "😌"),
        MoodOption(title: "困", emoji: "😴"),
        MoodOption(title: "累", emoji: "😵"),
        MoodOption(title: "焦虑", emoji: "😤"),
    ]
}

private struct MoodOption {
    let title: String
    let emoji: String
}

#Preview {
    NavigationStack {
        AddEntryView()
    }
    .modelContainer(PreviewContainer.make())
}

private enum PreviewContainer {
    static func make() -> ModelContainer {
        let schema = Schema([CoffeeEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
