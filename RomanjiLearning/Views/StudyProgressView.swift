import SwiftUI
import Charts

struct StudyProgressView: View {
    @Environment(PhraseManager.self) private var phraseManager
    @Environment(ProgressManager.self) private var progressManager

    @State private var ringProgress: Double = 0

    private var percentage: Double {
        guard phraseManager.totalCount > 0 else { return 0 }
        return Double(progressManager.phrasesViewed.count) / Double(phraseManager.totalCount)
    }

    private var categoryStats: [CategoryStat] {
        phraseManager.categories.map { category in
            let viewedInCategory = phraseManager.phrases
                .filter { $0.category == category && progressManager.phrasesViewed.contains($0.id.uuidString) }
                .count
            return CategoryStat(category: category, count: viewedInCategory)
        }
        .sorted { $0.count > $1.count }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                progressRing
                statsGrid
                categoryChart
            }
            .padding()
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.themeBackground.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(duration: 1.0).delay(0.2)) {
                ringProgress = percentage
            }
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.themeTextSecondary.opacity(0.12), lineWidth: 14)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.themeIndigo, .themeSakura]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(Int(percentage * 100))%")
                    .font(.rounded(size: 40, weight: .bold))
                    .foregroundStyle(.themeText)

                Text("\(progressManager.phrasesViewed.count) / \(phraseManager.totalCount)")
                    .font(.rounded(.caption))
                    .foregroundStyle(.themeTextSecondary)

                Text("phrases seen")
                    .font(.rounded(.caption2))
                    .foregroundStyle(.themeTextSecondary.opacity(0.7))
            }
        }
        .frame(width: 180, height: 180)
        .padding(.top, 8)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(title: "Total Reviews", value: "\(progressManager.totalReviews)", icon: "book.fill", color: .themeIndigo)
            statCard(title: "Current Streak", value: "\(progressManager.currentStreak)", icon: "flame.fill", color: .themeVermillion)
            statCard(title: "Longest Streak", value: "\(progressManager.longestStreak)", icon: "trophy.fill", color: .themeSakura)
            statCard(title: "Phrases Seen", value: "\(progressManager.phrasesViewed.count)", icon: "eye.fill", color: .themeMatcha)
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }

            HStack {
                Text(value)
                    .font(.rounded(size: 28, weight: .bold))
                    .foregroundStyle(.themeText)
                Spacer()
            }

            HStack {
                Text(title)
                    .font(.rounded(.caption))
                    .foregroundStyle(.themeTextSecondary)
                Spacer()
            }
        }
        .padding()
        .themeCard(cornerRadius: 14)
    }

    // MARK: - Category Chart

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PHRASES VIEWED BY CATEGORY")
                .font(.smallCapsCategory)
                .tracking(1)
                .foregroundStyle(.themeTextSecondary)

            if categoryStats.isEmpty {
                Text("No data yet")
                    .font(.rounded(.subheadline))
                    .foregroundStyle(.themeTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart(categoryStats) { stat in
                    BarMark(
                        x: .value("Viewed", stat.count),
                        y: .value("Category", stat.category)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.themeIndigo, .themeSakura],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
                }
                .chartXAxisLabel("Phrases viewed")
                .frame(height: CGFloat(categoryStats.count) * 32 + 40)
            }
        }
        .padding()
        .themeCard(cornerRadius: 14)
    }
}

// MARK: - Supporting Types

private struct CategoryStat: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
}
