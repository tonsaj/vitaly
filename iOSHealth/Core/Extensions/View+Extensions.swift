import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    func metricCardStyle(for type: MetricType) -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(type.vitalyGradient, lineWidth: 1)
                            .opacity(0.3)
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    func vitalyButtonStyle() -> some View {
        self
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(LinearGradient.vitalyGradient)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.vitalyPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    func vitalySecondaryButtonStyle() -> some View {
        self
            .foregroundStyle(Color.vitalyPrimary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.vitalyPrimary, lineWidth: 2)
            )
    }

    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - VitalyCard

/// Dark glassmorphic card style matching Vitaly design
struct VitalyCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20

    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.vitalyCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
    }
}

/// Hero card with gradient background
struct VitalyHeroCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 24

    init(cornerRadius: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient.vitalyHeroGradient)
            )
    }
}

/// List row style for dark theme
struct VitalyListRow<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.vitalyCardBackground)
            .cornerRadius(16)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
    }
}

// MARK: - Sunburst Icons

/// Sunburst-style icon with organic flowing rays
struct SunburstIcon: View {
    var rayCount: Int = 12
    var innerRadius: CGFloat = 0.3
    var outerRadius: CGFloat = 1.0
    var color: Color = .vitalyPrimary

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            Canvas { context, _ in
                // Draw sunburst rays
                for i in 0..<rayCount {
                    let angle = (2 * .pi / Double(rayCount)) * Double(i)
                    let nextAngle = (2 * .pi / Double(rayCount)) * Double(i + 1)

                    let path = Path { p in
                        let innerPoint1 = CGPoint(
                            x: center.x + cos(angle) * size * innerRadius / 2,
                            y: center.y + sin(angle) * size * innerRadius / 2
                        )
                        let innerPoint2 = CGPoint(
                            x: center.x + cos(nextAngle) * size * innerRadius / 2,
                            y: center.y + sin(nextAngle) * size * innerRadius / 2
                        )

                        let midAngle = (angle + nextAngle) / 2
                        let outerPoint = CGPoint(
                            x: center.x + cos(midAngle) * size * outerRadius / 2,
                            y: center.y + sin(midAngle) * size * outerRadius / 2
                        )

                        p.move(to: innerPoint1)
                        p.addQuadCurve(to: outerPoint, control: CGPoint(
                            x: center.x + cos(angle) * size * 0.6 / 2,
                            y: center.y + sin(angle) * size * 0.6 / 2
                        ))
                        p.addQuadCurve(to: innerPoint2, control: CGPoint(
                            x: center.x + cos(nextAngle) * size * 0.6 / 2,
                            y: center.y + sin(nextAngle) * size * 0.6 / 2
                        ))
                        p.closeSubpath()
                    }

                    let opacity = i % 2 == 0 ? 1.0 : 0.7
                    context.fill(path, with: .color(color.opacity(opacity)))
                }

                let centerCircle = Path { p in
                    p.addEllipse(in: CGRect(
                        x: center.x - size * innerRadius / 2,
                        y: center.y - size * innerRadius / 2,
                        width: size * innerRadius,
                        height: size * innerRadius
                    ))
                }
                context.fill(centerCircle, with: .color(color))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// Alternative simpler sunburst using shapes
struct SimpleSunburstIcon: View {
    var color: Color = .vitalyPrimary

    var body: some View {
        ZStack {
            ForEach(0..<12) { i in
                Capsule()
                    .fill(color.opacity(i % 2 == 0 ? 1.0 : 0.7))
                    .frame(width: 3, height: 20)
                    .offset(y: -25)
                    .rotationEffect(.degrees(Double(i) * 30))
            }

            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
        }
    }
}

// MARK: - Wave Shapes

/// Organic flowing wave shape for hero sections
struct WaveShape: Shape {
    var waveHeight: CGFloat = 30
    var phase: CGFloat = 0

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height

            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: width, y: height - waveHeight))

            let waveCount: CGFloat = 2.5
            let stepX = width / (waveCount * 4)

            for i in 0...Int(waveCount * 4) {
                let x = CGFloat(i) * stepX
                let relativeX = x / width
                let sine = sin((relativeX * waveCount * 2 * .pi) + phase)
                let y = height - waveHeight + (sine * waveHeight)

                if i == 0 {
                    path.addLine(to: CGPoint(x: x, y: y))
                } else {
                    let previousX = CGFloat(i - 1) * stepX
                    let controlPointX = (previousX + x) / 2

                    path.addQuadCurve(
                        to: CGPoint(x: x, y: y),
                        control: CGPoint(x: controlPointX, y: height - waveHeight)
                    )
                }
            }

            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
    }
}

/// Alternative organic blob-like wave shape
struct BlobWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height

            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: width, y: height * 0.75))

            path.addCurve(
                to: CGPoint(x: width * 0.6, y: height * 0.9),
                control1: CGPoint(x: width * 0.9, y: height * 0.7),
                control2: CGPoint(x: width * 0.75, y: height * 0.85)
            )

            path.addCurve(
                to: CGPoint(x: 0, y: height * 0.8),
                control1: CGPoint(x: width * 0.4, y: height * 0.95),
                control2: CGPoint(x: width * 0.2, y: height * 0.75)
            )

            path.closeSubpath()
        }
    }
}

/// Layered wave with multiple curves
struct LayeredWaveShape: Shape {
    var amplitude: CGFloat = 20
    var frequency: CGFloat = 1.5

    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height
            let midHeight = height * 0.85

            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: width, y: midHeight))

            let steps = 100
            for i in 0...steps {
                let x = (CGFloat(i) / CGFloat(steps)) * width
                let relativeX = x / width
                let sine = sin(relativeX * frequency * 2 * .pi)
                let y = midHeight + (sine * amplitude)

                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
    }
}
