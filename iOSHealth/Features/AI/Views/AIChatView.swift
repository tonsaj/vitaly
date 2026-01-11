import SwiftUI

struct AIChatView: View {
    @Bindable var viewModel: AIViewModel
    let healthContext: HealthContext

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vitalyBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages List
                    if viewModel.chatMessages.isEmpty {
                        emptyStateView
                    } else {
                        messagesList
                    }

                    Divider()
                        .background(Color.vitalyTextSecondary.opacity(0.2))

                    // Input Area
                    inputArea
                }
            }
            .navigationTitle("AI-assistent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.vitalyCardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Stäng") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyTextPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            viewModel.clearChat()
                        } label: {
                            Label("Rensa chat", systemImage: "trash")
                        }
                        .disabled(viewModel.chatMessages.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Color.vitalyPrimary)
                    }
                }
            }
            .onAppear {
                if viewModel.chatMessages.isEmpty {
                    addWelcomeMessage()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient.vitalyGradient)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.vitalyPrimary.opacity(0.3), radius: 20, x: 0, y: 10)

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 12) {
                Text("Hej! Jag är din AI-hälsoassistent")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("Ställ mig frågor om din hälsodata och få personliga råd.")
                    .font(.subheadline)
                    .foregroundStyle(Color.vitalyTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.chatMessages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isSendingMessage {
                        typingIndicator
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.chatMessages.count) { _, _ in
                withAnimation {
                    if let lastMessage = viewModel.chatMessages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient.vitalyGradient)
                    .frame(width: 36, height: 36)
                    .shadow(color: Color.vitalyPrimary.opacity(0.3), radius: 6, x: 0, y: 3)

                Image(systemName: "sun.max.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
            }

            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.vitalyTextSecondary)
                        .frame(width: 8, height: 8)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: viewModel.isSendingMessage
                        )
                        .opacity(viewModel.isSendingMessage ? 0.4 : 1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.vitalyCardBackground)
            )

            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Input Area

    private var inputArea: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Ställ en fråga...", text: $viewModel.currentMessage, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.vitalyCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.vitalyTextSecondary.opacity(0.2), lineWidth: 1)
                        )
                )
                .foregroundStyle(Color.vitalyTextPrimary)
                .focused($isInputFocused)
                .lineLimit(1...5)
                .disabled(viewModel.isSendingMessage)

            Button {
                Task {
                    await viewModel.sendMessage(healthContext: healthContext)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(canSendMessage ? LinearGradient.vitalyGradient : LinearGradient(colors: [Color.vitalyTextSecondary.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 44, height: 44)
                        .shadow(color: canSendMessage ? Color.vitalyPrimary.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)

                    Image(systemName: "arrow.up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .disabled(!canSendMessage || viewModel.isSendingMessage)
        }
        .padding(16)
        .background(Color.vitalyBackground)
    }

    // MARK: - Computed Properties

    private var canSendMessage: Bool {
        !viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Helper Functions

    private func addWelcomeMessage() {
        let contextInfo = buildContextInfo()

        let welcomeText = """
        Hej! Jag är här för att hjälpa dig förstå din hälsodata och ge personliga råd.

        \(contextInfo)

        Vad vill du veta mer om?
        """

        let welcomeMessage = ChatMessage(
            id: UUID().uuidString,
            content: welcomeText,
            isUser: false,
            timestamp: Date()
        )

        viewModel.chatMessages.append(welcomeMessage)
    }

    private func buildContextInfo() -> String {
        var info: [String] = []

        if let sleep = healthContext.sleep {
            info.append("Sömn: \(sleep.formattedDuration) (\(sleep.quality.displayText))")
        }

        if let activity = healthContext.activity {
            info.append("Aktivitet: \(activity.steps) steg")
        }

        if let heart = healthContext.heart {
            info.append("Vilopuls: \(Int(heart.restingHeartRate)) bpm")
        }

        if info.isEmpty {
            return "Jag har ingen hälsodata att analysera just nu, men du kan ändå ställa allmänna hälsofrågor."
        } else {
            return "Din senaste hälsodata:\n" + info.map { "• \($0)" }.joined(separator: "\n")
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.isUser {
                Spacer(minLength: 50)
            } else {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient.vitalyGradient)
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.vitalyPrimary.opacity(0.3), radius: 6, x: 0, y: 3)

                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                if !message.isUser {
                    Text("Vitaly AI")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.vitalyPrimary)
                        .padding(.horizontal, 4)
                }

                Text(message.content)
                    .font(.body)
                    .foregroundStyle(message.isUser ? Color.vitalyTextPrimary : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if message.isUser {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.vitalyCardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.vitalyTextSecondary.opacity(0.2), lineWidth: 1)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(LinearGradient.vitalyGradient)
                                    .shadow(color: Color.vitalyPrimary.opacity(0.2), radius: 8, x: 0, y: 4)
                            }
                        }
                    )

                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundStyle(Color.vitalyTextSecondary.opacity(0.7))
                    .padding(.horizontal, 4)
            }

            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    AIChatView(
        viewModel: {
            let vm = AIViewModel(userId: "preview-user")
            vm.chatMessages = [
                ChatMessage(
                    id: "1",
                    content: "Hej! Hur kan jag förbättra min sömn?",
                    isUser: true,
                    timestamp: Date().addingTimeInterval(-120)
                ),
                ChatMessage(
                    id: "2",
                    content: """
                    Baserat på din sömndata ser jag att du i genomsnitt får 6.5 timmar sömn per natt. \
                    För optimal återhämtning rekommenderar jag 7-9 timmar.

                    Här är några tips:
                    • Försök gå och lägg dig vid samma tid varje kväll
                    • Undvik skärmar minst 1 timme innan läggdags
                    • Håll sovrummet svalt (16-19°C)
                    """,
                    isUser: false,
                    timestamp: Date().addingTimeInterval(-60)
                )
            ]
            return vm
        }(),
        healthContext: HealthContext(sleep: nil, activity: nil, heart: nil)
    )
}
