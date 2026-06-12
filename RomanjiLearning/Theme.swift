import SwiftUI

// MARK: - Japan-Inspired Color Palette

extension Color {
    static let themeIndigo = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.25, blue: 0.58, alpha: 1)
            : UIColor(red: 0.10, green: 0.10, blue: 0.31, alpha: 1)
    })

    static let themeSakura = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.68, blue: 0.75, alpha: 1)
            : UIColor(red: 0.95, green: 0.63, blue: 0.70, alpha: 1)
    })

    static let themeVermillion = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.90, green: 0.35, blue: 0.25, alpha: 1)
            : UIColor(red: 0.84, green: 0.29, blue: 0.20, alpha: 1)
    })

    static let themeBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.systemBackground
            : UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1)
    })

    static let themeCardBg = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.secondarySystemGroupedBackground
            : .white
    })

    static let themeText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.93, alpha: 1)
            : UIColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1)
    })

    static let themeTextSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.60, alpha: 1)
            : UIColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1)
    })

    static let themeMatcha = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.43, green: 0.65, blue: 0.43, alpha: 1)
            : UIColor(red: 0.36, green: 0.55, blue: 0.35, alpha: 1)
    })
}

// MARK: - ShapeStyle Convenience (for .foregroundStyle(.themeX) shorthand)

extension ShapeStyle where Self == Color {
    static var themeIndigo: Color { Color.themeIndigo }
    static var themeSakura: Color { Color.themeSakura }
    static var themeVermillion: Color { Color.themeVermillion }
    static var themeBackground: Color { Color.themeBackground }
    static var themeCardBg: Color { Color.themeCardBg }
    static var themeText: Color { Color.themeText }
    static var themeTextSecondary: Color { Color.themeTextSecondary }
    static var themeMatcha: Color { Color.themeMatcha }
}

// MARK: - Typography

extension Font {
    static func rounded(_ style: TextStyle, weight: Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    static func rounded(size: CGFloat, weight: Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func japanese(size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func romaji(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .light, design: .rounded).italic()
    }

    static var smallCapsCategory: Font {
        .system(size: 11, weight: .semibold, design: .rounded)
    }
}

// MARK: - Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scale: ScaleButtonStyle { ScaleButtonStyle() }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

// MARK: - Theme Card Modifier

struct ThemeCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var shadowRadius: CGFloat = 8
    var shadowY: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.themeCardBg)
                    .shadow(color: .black.opacity(0.1), radius: shadowRadius, y: shadowY)
            )
    }
}

extension View {
    func themeCard(cornerRadius: CGFloat = 20, shadowRadius: CGFloat = 8, shadowY: CGFloat = 4) -> some View {
        modifier(ThemeCard(cornerRadius: cornerRadius, shadowRadius: shadowRadius, shadowY: shadowY))
    }
}

// MARK: - Gradients

extension LinearGradient {
    static var sakuraIndigo: LinearGradient {
        LinearGradient(
            colors: [.themeIndigo, .themeSakura],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
