import SwiftUI

struct AIChatView: View {
    @Bindable var viewModel: AIViewModel
    let healthContext: ExtendedHealthContext

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
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.vitalyCardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.vitalyTextPrimary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            viewModel.clearChat()
                        } label: {
                            Label("Clear chat", systemImage: "trash")
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
                Text("Hi! I'm your AI health assistant")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.vitalyTextPrimary)

                Text("Ask me questions about your health data and get personalized advice.")
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
            .scrollBounceBehavior(.basedOnSize)
            .clipped()
            .contentShape(Rectangle())
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
            TextField("Ask a question...", text: $viewModel.currentMessage, axis: .vertical)
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
        Hi! I'm here to help you understand your health data and provide personalized advice.

        \(contextInfo)

        What would you like to know more about?
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

        // Today's data
        if let sleep = healthContext.todaySleep {
            info.append("Today's sleep: \(sleep.formattedDuration) (\(sleep.quality.displayText))")
        }

        if let activity = healthContext.todayActivity {
            info.append("Today's steps: \(activity.steps)")
        }

        if let heart = healthContext.todayHeart {
            info.append("Resting heart rate: \(Int(heart.restingHeartRate)) bpm")
        }

        // Historical summary
        if !healthContext.sleepHistory.isEmpty {
            let avgSleep = healthContext.sleepHistory.reduce(0) { $0 + $1.totalHours } / Double(healthContext.sleepHistory.count)
            info.append("Sleep avg (30 days): \(String(format: "%.1f", avgSleep)) hours")
        }

        if !healthContext.activityHistory.isEmpty {
            let avgSteps = healthContext.activityHistory.reduce(0) { $0 + $1.steps } / healthContext.activityHistory.count
            info.append("Steps avg (30 days): \(avgSteps)/day")
        }

        if info.isEmpty {
            return "I don't have any health data to analyze right now, but you can still ask general health questions."
        } else {
            return "I have access to your health data:\n" + info.map { "• \($0)" }.joined(separator: "\n")
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
                    content: "How can I improve my sleep?",
                    isUser: true,
                    timestamp: Date().addingTimeInterval(-120)
                ),
                ChatMessage(
                    id: "2",
                    content: """
                    Based on your sleep data, I see that you average 6.5 hours of sleep per night. \
                    For optimal recovery, I recommend 7-9 hours.

                    Here are some tips: Try going to bed at the same time every night. \
                    Avoid screens at least 1 hour before bedtime. Keep the bedroom cool (16-19°C).
                    """,
                    isUser: false,
                    timestamp: Date().addingTimeInterval(-60)
                )
            ]
            return vm
        }(),
        healthContext: ExtendedHealthContext(
            todaySleep: nil,
            todayActivity: nil,
            todayHeart: nil,
            sleepHistory: [],
            activityHistory: [],
            heartHistory: []
        )
    )
}
