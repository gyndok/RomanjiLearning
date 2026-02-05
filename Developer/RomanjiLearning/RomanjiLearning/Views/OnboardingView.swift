import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    onboardingPage(
                        icon: "character.book.closed.fill",
                        title: "Learn 500+ Japanese Phrases",
                        subtitle: "Master essential travel phrases with flashcards, organized by real-world scenarios like airports, restaurants, and hotels.",
                        accent: .themeIndigo
                    ).tag(0)

                    onboardingPage(
                        icon: "hand.tap.fill",
                        title: "Flip, Listen, and Practice",
                        subtitle: "Tap to flip cards, swipe to navigate, and listen to native pronunciation. Learn at your own pace with audio playback.",
                        accent: .themeSakura
                    ).tag(1)

                    onboardingPage(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Track Your Progress",
                        subtitle: "Spaced repetition keeps you on track. Review cards at the perfect time to lock knowledge into long-term memory.",
                        accent: .themeVermillion
                    ).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(duration: 0.4), value: currentPage)

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.themeIndigo : Color.themeIndigo.opacity(0.25))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                if currentPage == 2 {
                    Button {
                        withAnimation(.spring(duration: 0.4)) {
                            hasSeenOnboarding = true
                        }
                    } label: {
                        Text("Get Started")
                            .font(.rounded(.headline, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(LinearGradient.sakuraIndigo)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.scale)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            currentPage += 1
                        }
                    } label: {
                        Text("Next")
                            .font(.rounded(.headline, weight: .medium))
                            .foregroundStyle(Color.themeIndigo)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.themeIndigo, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.scale)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    private func onboardingPage(icon: String, title: String, subtitle: String, accent: Color) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(accent.opacity(0.1))
                    .frame(width: 140, height: 140)
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(accent)
            }

            Text(title)
                .font(.rounded(.title, weight: .bold))
                .foregroundStyle(Color.themeText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Text(subtitle)
                .font(.rounded(.body))
                .foregroundStyle(Color.themeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)

            Spacer()
            Spacer()
        }
    }
}
