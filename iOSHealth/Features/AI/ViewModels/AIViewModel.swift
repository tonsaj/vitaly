import Foundation
import SwiftUI

@MainActor
@Observable
final class AIViewModel {
    // MARK: - Published Properties

    var insights: [AIInsight] = []
    var isLoading = false
    var isGenerating = false
    var isSendingMessage = false
    var errorMessage: String?

    // Chat
    var chatMessages: [ChatMessage] = []
    var currentMessage = ""

    // MARK: - Dependencies

    private let geminiService: GeminiService
    private let firestoreService: FirestoreService
    private let userId: String

    // MARK: - Initialization

    init(geminiService: GeminiService = GeminiService(),
         firestoreService: FirestoreService = FirestoreService(),
         userId: String) {
        self.geminiService = geminiService
        self.firestoreService = firestoreService
        self.userId = userId
    }

    // MARK: - Insights Management

    func loadInsights() async {
        isLoading = true
        errorMessage = nil

        do {
            insights = try await firestoreService.fetchInsights(userId: userId, limit: 50)
        } catch {
            errorMessage = "Kunde inte ladda insikter: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refreshInsights() async {
        await loadInsights()
    }

    func generateDailyInsight(sleep: SleepData?, activity: ActivityData?, heart: HeartData?) async {
        isGenerating = true
        errorMessage = nil

        do {
            let insight = try await geminiService.generateDailySummary(
                sleep: sleep,
                activity: activity,
                heart: heart
            )

            try await firestoreService.saveInsight(userId: userId, insight: insight)
            await loadInsights()
        } catch {
            errorMessage = "Kunde inte generera insikt: \(error.localizedDescription)"
        }

        isGenerating = false
    }

    func generateSleepAnalysis(sleepData: [SleepData]) async {
        isGenerating = true
        errorMessage = nil

        do {
            let insight = try await geminiService.analyzeSleep(sleepData: sleepData)
            try await firestoreService.saveInsight(userId: userId, insight: insight)
            await loadInsights()
        } catch {
            errorMessage = "Kunde inte generera sömnanalys: \(error.localizedDescription)"
        }

        isGenerating = false
    }

    func generateRecoveryAdvice(sleep: SleepData?, heart: HeartData?, recentActivity: [ActivityData]) async {
        isGenerating = true
        errorMessage = nil

        do {
            let insight = try await geminiService.generateRecoveryAdvice(
                sleep: sleep,
                heart: heart,
                recentActivity: recentActivity
            )
            try await firestoreService.saveInsight(userId: userId, insight: insight)
            await loadInsights()
        } catch {
            errorMessage = "Kunde inte generera återhämtningsråd: \(error.localizedDescription)"
        }

        isGenerating = false
    }

    func generateWeeklyReport(sleepData: [SleepData], activityData: [ActivityData], heartData: [HeartData]) async {
        isGenerating = true
        errorMessage = nil

        do {
            let insight = try await geminiService.generateWeeklyReport(
                sleepData: sleepData,
                activityData: activityData,
                heartData: heartData
            )
            try await firestoreService.saveInsight(userId: userId, insight: insight)
            await loadInsights()
        } catch {
            errorMessage = "Kunde inte generera veckorapport: \(error.localizedDescription)"
        }

        isGenerating = false
    }

    func markAsRead(_ insight: AIInsight) async {
        guard let insightId = insight.id, !insight.isRead else { return }

        do {
            try await firestoreService.markInsightAsRead(userId: userId, insightId: insightId)

            if let index = insights.firstIndex(where: { $0.id == insightId }) {
                insights[index].isRead = true
            }
        } catch {
            print("Failed to mark insight as read: \(error)")
        }
    }

    var unreadCount: Int {
        insights.filter { !$0.isRead }.count
    }

    // MARK: - Chat Management

    func sendMessage(healthContext: HealthContext) async {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let messageText = currentMessage
        currentMessage = ""

        let userMessage = ChatMessage(
            id: UUID().uuidString,
            content: messageText,
            isUser: true,
            timestamp: Date()
        )

        chatMessages.append(userMessage)
        isSendingMessage = true

        do {
            let response = try await geminiService.chat(message: messageText, context: healthContext)

            let aiMessage = ChatMessage(
                id: UUID().uuidString,
                content: response,
                isUser: false,
                timestamp: Date()
            )

            chatMessages.append(aiMessage)
        } catch {
            errorMessage = "Kunde inte skicka meddelande: \(error.localizedDescription)"

            let errorMessage = ChatMessage(
                id: UUID().uuidString,
                content: "Förlåt, jag kunde inte behandla din förfrågan. Försök igen senare.",
                isUser: false,
                timestamp: Date()
            )

            chatMessages.append(errorMessage)
        }

        isSendingMessage = false
    }

    func clearChat() {
        chatMessages.removeAll()
        errorMessage = nil
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
