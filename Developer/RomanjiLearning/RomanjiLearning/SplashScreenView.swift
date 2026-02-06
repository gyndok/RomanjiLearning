import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.themeSakura.opacity(0.3),
                    Color.themeSakura.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App icon or logo
                Image(systemName: "character.book.closed.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.themeSakura)
                
                // App name
                Text("Romaji Learning")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                // Tagline
                Text("Learn Japanese")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
