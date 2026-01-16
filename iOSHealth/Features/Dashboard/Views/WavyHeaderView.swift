import SwiftUI

/// Dynamic wavy header with pulsing animation and sunset gradients
struct WavyHeaderView: View {
    @State private var phase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0

    let title: String
    let subtitle: String?
    let canGoBack: Bool
    let canGoForward: Bool
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        canGoBack: Bool = true,
        canGoForward: Bool = true,
        onSwipeLeft: @escaping () -> Void = {},
        onSwipeRight: @escaping () -> Void = {}
    ) {
        self.title = title
        self.subtitle = subtitle
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Background waves with gradient
            GeometryReader { geometry in
                ZStack {
                    // Back wave layer
                    AnimatedWaveLayer(
                        phase: phase,
                        amplitude: 25,
                        frequency: 1.2,
                        offset: 0
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.vitalyTertiary.opacity(0.3),
                                Color.vitalySecondary.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                    // Middle wave layer
                    AnimatedWaveLayer(
                        phase: phase + 0.5,
                        amplitude: 20,
                        frequency: 1.5,
                        offset: 10
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.vitalySecondary.opacity(0.4),
                                Color.vitalyPrimary.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Front wave layer
                    AnimatedWaveLayer(
                        phase: phase + 1.0,
                        amplitude: 15,
                        frequency: 1.8,
                        offset: 20
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.vitalyPrimary.opacity(0.5),
                                Color.vitalySecondary.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                .blur(radius: 2)
            }
            .frame(height: 200)

            // Pulsing glow effect
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.vitalyPrimary.opacity(0.3 * pulseScale),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(height: 200)
                .blur(radius: 30)

            // Content overlay - moved to top
            VStack(alignment: .leading, spacing: 8) {
                // Date navigation row with arrows
                HStack(spacing: 16) {
                    // Previous day button
                    Button {
                        onSwipeRight()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(canGoBack ? Color.vitalyPrimary : Color.vitalyTextSecondary.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.vitalyCardBackground.opacity(0.6))
                            )
                    }
                    .disabled(!canGoBack)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.vitalyTextPrimary, Color.vitalyTextPrimary.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.vitalyTextSecondary)
                        }
                    }

                    Spacer()

                    // Next day button
                    Button {
                        onSwipeLeft()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(canGoForward ? Color.vitalyPrimary : Color.vitalyTextSecondary.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.vitalyCardBackground.opacity(0.6))
                            )
                    }
                    .disabled(!canGoForward)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
        }
        .frame(height: 200)
        .background(Color.vitalyBackground)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Wave animation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            phase = 2 * .pi
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
    }
}

/// Animated wave layer with customizable parameters
struct AnimatedWaveLayer: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat
    var offset: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height
            let midHeight = height * 0.7 - offset

            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: width, y: midHeight))

            let steps = 100
            for i in stride(from: steps, through: 0, by: -1) {
                let x = (CGFloat(i) / CGFloat(steps)) * width
                let relativeX = x / width
                let sine = sin((relativeX * frequency * 2 * .pi) + phase)
                let y = midHeight + (sine * amplitude)

                if i == steps {
                    path.addLine(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
    }
}

/// Compact wavy header for internal pages
struct CompactWavyHeader: View {
    @State private var phase: CGFloat = 0
    let title: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Single wave layer
            AnimatedWaveLayer(
                phase: phase,
                amplitude: 15,
                frequency: 1.5,
                offset: 5
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color.vitalyPrimary.opacity(0.4),
                        Color.vitalySecondary.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blur(radius: 1)

            // Title
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.vitalyTextPrimary)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .frame(height: 120)
        .background(Color.vitalyBackground)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = 2 * .pi
            }
        }
    }
}

/// Wavy divider for section breaks
struct WavyDivider: View {
    @State private var phase: CGFloat = 0
    var height: CGFloat = 40

    var body: some View {
        AnimatedWaveLayer(
            phase: phase,
            amplitude: 8,
            frequency: 2.0,
            offset: 0
        )
        .fill(
            LinearGradient(
                colors: [
                    Color.vitalyPrimary.opacity(0.2),
                    Color.vitalySecondary.opacity(0.15)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .frame(height: height)
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                phase = 2 * .pi
            }
        }
    }
}

// MARK: - Preview
#Preview("Full Header") {
    VStack(spacing: 0) {
        WavyHeaderView(
            title: "Välkommen",
            subtitle: "Torsdag, 12 januari"
        )

        Spacer()
    }
    .background(Color.vitalyBackground)
    .preferredColorScheme(.dark)
}

#Preview("Compact Header") {
    VStack(spacing: 0) {
        CompactWavyHeader(title: "Dashboard")

        Spacer()
    }
    .background(Color.vitalyBackground)
    .preferredColorScheme(.dark)
}

#Preview("Wavy Divider") {
    VStack(spacing: 20) {
        Text("Section 1")
            .font(.headline)

        WavyDivider()

        Text("Section 2")
            .font(.headline)

        Spacer()
    }
    .padding()
    .background(Color.vitalyBackground)
    .preferredColorScheme(.dark)
}
