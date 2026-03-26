import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.justSipBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        profileCard
                        actionsCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("我的")
        }
    }

    private var profileCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.16))
                    .frame(width: 72, height: 72)

                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 6) {
                Text("咖友小周")
                    .font(.title3.weight(.semibold))

                Text("今天也记一杯喜欢的咖啡")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(cardBackground)
    }

    private var actionsCard: some View {
        VStack(spacing: 0) {
            actionRow(title: "设置", icon: "gearshape")

            Divider()
                .padding(.leading, 50)

            actionRow(title: "数据导出（即将支持）", icon: "square.and.arrow.up")
        }
        .background(cardBackground)
    }

    private func actionRow(title: String, icon: String) -> some View {
        Button {
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .frame(width: 22)
                    .foregroundStyle(Color.accentColor)

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

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.justSipCardBackground)
            .shadow(color: Color.justSipShadowColor, radius: 10, x: 0, y: 4)
    }
}
