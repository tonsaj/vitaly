import SwiftUI

/// Animated sunburst logo with pulsing rays and gradient colors
struct AnimatedSunburstLogo: View {
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.5

    var rayCount: Int = 16
    var animate: Bool = true

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.vitalyPrimary.opacity(glowOpacity * 0.4),
                                Color.vitalySecondary.opacity(glowOpacity * 0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: size * 0.2,
                            endRadius: size * 0.6
                        )
                    )
                    .blur(radius: 20)
                    .scaleEffect(pulseScale * 1.1)

                // Rotating rays
                ZStack {
                    ForEach(0..<rayCount, id: \.self) { index in
                        RayShape(index: index, total: rayCount)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors(for: index),
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: size, height: size)
                    }
                }
                .rotationEffect(.degrees(rotation))
                .scaleEffect(pulseScale)

                // Center circle with gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.vitalyPrimary,
                                Color.vitalySecondary,
                                Color.vitalyTertiary.opacity(0.9)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.15
                        )
                    )
                    .frame(width: size * 0.3, height: size * 0.3)
                    .shadow(
                        color: Color.vitalyPrimary.opacity(0.5),
                        radius: 15,
                        x: 0,
                        y: 0
                    )

                // Inner highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.2, height: size * 0.2)
                    .offset(y: -size * 0.03)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            if animate {
                startAnimations()
            }
        }
    }

    private func gradientColors(for index: Int) -> [Color] {
        let isEven = index % 2 == 0
        if isEven {
            return [
                Color.vitalyPrimary,
                Color.vitalySecondary.opacity(0.8)
            ]
        } else {
            return [
                Color.vitalySecondary,
                Color.vitalyTertiary.opacity(0.7)
            ]
        }
    }

    private func startAnimations() {
        // Slow rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotation = 360
        }

        // Pulse effect
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            glowOpacity = 0.8
        }
    }
}

/// Individual ray shape for the sunburst
struct RayShape: Shape {
    let index: Int
    let total: Int

    func path(in rect: CGRect) -> Path {
        Path { path in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let angle = (2 * .pi / Double(total)) * Double(index)
            let nextAngle = (2 * .pi / Double(total)) * Double(index + 1)

            let size = min(rect.width, rect.height)
            let innerRadius = size * 0.15
            let outerRadius = size * 0.45

            let innerPoint1 = CGPoint(
                x: center.x + cos(angle) * innerRadius,
                y: center.y + sin(angle) * innerRadius
            )
            let innerPoint2 = CGPoint(
                x: center.x + cos(nextAngle) * innerRadius,
                y: center.y + sin(nextAngle) * innerRadius
            )

            let midAngle = (angle + nextAngle) / 2
            let outerPoint = CGPoint(
                x: center.x + cos(midAngle) * outerRadius,
                y: center.y + sin(midAngle) * outerRadius
            )

            path.move(to: innerPoint1)

            // Calculate control points for smooth curves
            let angleDelta = nextAngle - angle
            let midRadius = (innerRadius + outerRadius) / 2

            let controlAngle1 = angle + angleDelta * 0.3
            let control1 = CGPoint(
                x: center.x + cos(controlAngle1) * midRadius,
                y: center.y + sin(controlAngle1) * midRadius
            )

            let controlAngle2 = angle + angleDelta * 0.7
            let control2 = CGPoint(
                x: center.x + cos(controlAngle2) * midRadius,
                y: center.y + sin(controlAngle2) * midRadius
            )

            path.addQuadCurve(to: outerPoint, control: control1)
            path.addQuadCurve(to: innerPoint2, control: control2)
            path.closeSubpath()
        }
    }
}

/// Static sunburst logo (non-animated)
struct StaticSunburstLogo: View {
    var size: CGFloat = 100

    var body: some View {
        AnimatedSunburstLogo(animate: false)
            .frame(width: size, height: size)
    }
}

/// Mini sunburst icon for use in buttons or small spaces
struct MiniSunburstIcon: View {
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.vitalyPrimary,
                                Color.vitalySecondary
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: size * 0.35)
                    .offset(y: -size * 0.25)
                    .rotationEffect(.degrees(Double(index) * 45))
            }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.vitalyPrimary,
                            Color.vitalySecondary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.4, height: size * 0.4)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview
#Preview("Animated Logo") {
    ZStack {
        Color.vitalyBackground
            .ignoresSafeArea()

        AnimatedSunburstLogo()
            .frame(width: 200, height: 200)
    }
    .preferredColorScheme(.dark)
}

#Preview("Static Logo") {
    ZStack {
        Color.vitalyBackground
            .ignoresSafeArea()

        VStack(spacing: 40) {
            StaticSunburstLogo(size: 150)

            StaticSunburstLogo(size: 100)

            StaticSunburstLogo(size: 60)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Mini Icons") {
    ZStack {
        Color.vitalyBackground
            .ignoresSafeArea()

        HStack(spacing: 20) {
            MiniSunburstIcon(size: 32)
            MiniSunburstIcon(size: 24)
            MiniSunburstIcon(size: 16)
        }
    }
    .preferredColorScheme(.dark)
}
