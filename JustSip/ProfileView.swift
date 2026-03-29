import SwiftUI

struct ProfileView: View {
    @AppStorage("profileNickname") private var nickname = "咖友小周"
    @AppStorage("profileSignature") private var signature = "今天也记一杯喜欢的咖啡"
    @AppStorage("profileAvatarStyleID") private var avatarStyleID = ProfileAvatarStyle.defaultStyle.id
    @AppStorage("profileFeedbackDraft") private var feedbackDraft = ""

    @State private var isPresentingProfileEditor = false
    @State private var isPresentingAvatarPicker = false
    @State private var isPresentingFeedback = false
    @State private var draftNickname = ""
    @State private var draftSignature = ""
    @State private var draftFeedback = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.justSipBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        profileCard
                        actionsCard
                        versionFooter
                    }
                    .padding(20)
                }
            }
            .navigationTitle("我的")
            .sheet(isPresented: $isPresentingProfileEditor) {
                profileEditorSheet
            }
            .sheet(isPresented: $isPresentingAvatarPicker) {
                avatarPickerSheet
            }
            .sheet(isPresented: $isPresentingFeedback) {
                feedbackSheet
            }
        }
    }

    private var profileCard: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()

                Button("编辑资料") {
                    presentProfileEditor()
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.justSipAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .stroke(Color.justSipAccent.opacity(0.45), lineWidth: 1)
                )
            }

            Button {
                isPresentingAvatarPicker = true
            } label: {
                avatarView(size: 82, showsHint: true)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            VStack(spacing: 8) {
                Text(nickname)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(signature)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(cardBackground)
    }

    private func presentProfileEditor() {
        draftNickname = nickname
        draftSignature = signature
        isPresentingProfileEditor = true
    }

    private var actionsCard: some View {
        VStack(spacing: 0) {
            actionRow(title: "问题反馈", icon: "bubble.left.and.exclamationmark.bubble.right") {
                draftFeedback = feedbackDraft
                isPresentingFeedback = true
            }

            divider

            actionRow(title: "设置", icon: "gearshape") {
            }
        }
        .background(cardBackground)
    }

    private var versionFooter: some View {
        Text("版本 \(versionString)")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            .padding(.bottom, 12)
    }

    private func actionRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .frame(width: 22)
                    .foregroundStyle(Color.justSipAccent)

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Divider()
            .padding(.leading, 50)
    }

    private func avatarView(size: CGFloat, showsHint: Bool) -> some View {
        let style = selectedAvatarStyle

        return ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(style.backgroundColor)
                    .frame(width: size, height: size)

                Image(systemName: style.symbolName)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(style.symbolColor)
            }

            if showsHint {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.justSipAccent, Color.justSipCardBackground)
                    .background(Color.justSipCardBackground, in: Circle())
                    .offset(x: 2, y: 2)
            }
        }
    }

    private var profileEditorSheet: some View {
        NavigationStack {
            ZStack {
                Color.justSipBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        editorCard(
                            title: "昵称",
                            subtitle: "换一个更像你的称呼"
                        ) {
                            TextField("输入昵称", text: $draftNickname)
                                .textInputAutocapitalization(.never)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.justSipInsetBackground)
                                )
                        }

                        editorCard(
                            title: "个性签名",
                            subtitle: "留下一句属于今天的咖啡心情"
                        ) {
                            TextField("写一句想说的话", text: $draftSignature, axis: .vertical)
                                .lineLimit(3...5)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.justSipInsetBackground)
                                )
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        isPresentingProfileEditor = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        nickname = normalizedNickname
                        signature = normalizedSignature
                        isPresentingProfileEditor = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var avatarPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.justSipBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 14)], spacing: 14) {
                        ForEach(ProfileAvatarStyle.allCases) { style in
                            Button {
                                avatarStyleID = style.id
                                isPresentingAvatarPicker = false
                            } label: {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(style.backgroundColor)
                                            .frame(width: 72, height: 72)

                                        Image(systemName: style.symbolName)
                                            .font(.system(size: 28, weight: .semibold))
                                            .foregroundStyle(style.symbolColor)
                                    }

                                    Text(style.title)
                                        .font(.footnote.weight(.medium))
                                        .foregroundStyle(.primary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 132)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.justSipCardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(
                                            style.id == avatarStyleID ? Color.justSipAccent : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("选择头像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        isPresentingAvatarPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var feedbackSheet: some View {
        NavigationStack {
            ZStack {
                Color.justSipBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        editorCard(
                            title: "问题反馈",
                            subtitle: "把你遇到的问题或想法记下来"
                        ) {
                            TextField("例如：某个页面间距太挤，或者想加提醒功能", text: $draftFeedback, axis: .vertical)
                                .lineLimit(5...8)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.justSipInsetBackground)
                                )
                        }

                        if !feedbackDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            editorCard(
                                title: "上次保存",
                                subtitle: "你最近一次记录的问题反馈"
                            ) {
                                Text(feedbackDraft)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.justSipInsetBackground)
                                    )
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("问题反馈")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        isPresentingFeedback = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        feedbackDraft = draftFeedback.trimmingCharacters(in: .whitespacesAndNewlines)
                        isPresentingFeedback = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func editorCard<Content: View>(
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
        .background(cardBackground)
        .padding(.top, 2)
    }

    private var selectedAvatarStyle: ProfileAvatarStyle {
        ProfileAvatarStyle.allCases.first(where: { $0.id == avatarStyleID }) ?? .defaultStyle
    }

    private var normalizedNickname: String {
        let trimmed = draftNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "咖友小周" : trimmed
    }

    private var normalizedSignature: String {
        let trimmed = draftSignature.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "今天也记一杯喜欢的咖啡" : trimmed
    }

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.justSipCardBackground)
            .shadow(color: Color.justSipShadowColor, radius: 10, x: 0, y: 4)
    }
}

private struct ProfileAvatarStyle: Identifiable, CaseIterable {
    let id: String
    let title: String
    let symbolName: String
    let backgroundColor: Color
    let symbolColor: Color

    static let allCases: [ProfileAvatarStyle] = [
        .init(
            id: "latte",
            title: "拿铁",
            symbolName: "cup.and.saucer.fill",
            backgroundColor: Color.justSipOverviewBackground,
            symbolColor: Color.justSipAccent
        ),
        .init(
            id: "bean",
            title: "咖啡豆",
            symbolName: "circle.hexagongrid.fill",
            backgroundColor: Color.justSipInsetBackground,
            symbolColor: Color.justSipAccent
        ),
        .init(
            id: "sun",
            title: "清晨",
            symbolName: "sun.max.fill",
            backgroundColor: Color.orange.opacity(0.16),
            symbolColor: Color.orange
        ),
        .init(
            id: "spark",
            title: "高能",
            symbolName: "bolt.fill",
            backgroundColor: Color.yellow.opacity(0.16),
            symbolColor: Color(red: 0.84, green: 0.61, blue: 0.18)
        ),
        .init(
            id: "moon",
            title: "夜咖",
            symbolName: "moon.stars.fill",
            backgroundColor: Color.blue.opacity(0.14),
            symbolColor: Color.blue
        ),
        .init(
            id: "leaf",
            title: "放松",
            symbolName: "leaf.fill",
            backgroundColor: Color.green.opacity(0.14),
            symbolColor: Color.green
        ),
    ]

    static let defaultStyle = allCases[0]
}
