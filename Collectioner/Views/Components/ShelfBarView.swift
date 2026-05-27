import SwiftUI

struct ShelfBarView: View {
    let color: Color
    var height: CGFloat = 74
    var clipSize: CGFloat = 16

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .glassEffect(.clear.tint(color.opacity(0.25)), in: .rect(cornerRadius: 20))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.horizontal, 12)

            HStack {
                MetallicClipView(size: clipSize)
                Spacer()
                MetallicClipView(size: clipSize)
            }
            .padding(.horizontal, 24)
            .compositingGroup()
        }
        .frame(height: height)
        .offset(y: -10)
    }
}

// MARK: - Metallic Clip

struct MetallicClipView: View {
    let size: CGFloat

    @State private var scrollY: CGFloat = 400

    private var highlightAngle: CGFloat {
        scrollY / 350 * .pi
    }

    private var highlightCenter: UnitPoint {
        let orbitRadius: CGFloat = 0.15
        let cx = 0.5 + orbitRadius * cos(highlightAngle)
        let cy = 0.5 + orbitRadius * sin(highlightAngle)
        return UnitPoint(x: cx, y: cy)
    }

    private let brushedStops: [Color] = [
        Color(white: 0.78), Color(white: 0.92), Color(white: 0.68),
        Color(white: 0.88), Color(white: 0.72), Color(white: 0.94),
        Color(white: 0.65), Color(white: 0.90), Color(white: 0.70),
        Color(white: 0.93), Color(white: 0.67), Color(white: 0.85),
        Color(white: 0.78),
    ]

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: brushedStops,
                        center: .center
                    )
                )
                .rotationEffect(.radians(highlightAngle * 0.4))

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color.white.opacity(0.15),
                            Color.clear,
                        ],
                        center: highlightCenter,
                        startRadius: 0,
                        endRadius: size * 0.55
                    )
                )

            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            Color(white: 0.48), Color(white: 0.78),
                            Color(white: 0.42), Color(white: 0.72),
                            Color(white: 0.48),
                        ],
                        center: .center
                    ),
                    lineWidth: size * 0.08
                )
                .rotationEffect(.radians(highlightAngle * 0.3))

            Circle()
                .strokeBorder(Color(white: 0.6).opacity(0.4), lineWidth: 0.5)
                .padding(size * 0.18)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .global).midY
        } action: { newValue in
            scrollY = newValue
        }
    }
}
