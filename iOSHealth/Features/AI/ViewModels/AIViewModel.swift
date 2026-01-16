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

    // Extended context for background data (weight, GLP-1, etc)
    var extendedContext: ExtendedHealthContext?

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
            errorMessage = "Could not load insights: \(error.localizedDescription)"
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
                heart: heart,
                extendedContext: extendedContext
            )

            try await firestoreService.saveInsight(userId: userId, insight: insight)
            await loadInsights()
        } catch {
            errorMessage = "Could not generate insight: \(error.localizedDescription)"
        }

        isGenerating = false
    }

    func generateSleepAnalysis(sleepData: [SleepData]) async {
        isGenerating = true
        errorMessage = nil

        do {
            let insight = try await geminiService.analyzeSleep(
                sleepData: sleepData,
                extendedContext: extendedContext
            )
            try await firestoreService.saveInsight(userId: userId, insight: insight)
            await loadInsights()
        } catch {
            errorMessage = "Could not generate sleep analysis: \(error.localizedDescription)"
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
                recentActivity: recentActivity,
                extendedContext: extendedContext
            )
            try await firestoreService.saveInsight(userId: userId, insight: insight)
            await loadInsights()
        } catch {
            errorMessage = "Could not generate recovery advice: \(error.localizedDescription)"
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
            errorMessage = "Could not generate weekly report: \(error.localizedDescription)"
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

    // MARK: - Deep Analysis

    func generateDeepAnalysis(
        insightType: InsightType,
        sleepData: [SleepData],
        activityData: [ActivityData],
        heartData: [HeartData],
        userProfile: UserHealthProfile? = nil
    ) async {
        isGenerating = true
        errorMessage = nil

        do {
            let insight = try await geminiService.generateDeepAnalysis(
                insightType: insightType,
                sleepData: sleepData,
                activityData: activityData,
                heartData: heartData,
                userProfile: userProfile
            )
            try await firestoreService.saveInsight(userId: userId, insight: insight)
            await loadInsights()
        } catch {
            errorMessage = "Could not generate deep analysis: \(error.localizedDescription)"
        }

        isGenerating = false
    }

    // MARK: - Chat Management

    func sendMessage(healthContext: ExtendedHealthContext) async {
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
            errorMessage = "Could not send message: \(error.localizedDescription)"

            let errorMessage = ChatMessage(
                id: UUID().uuidString,
                content: "Sorry, I couldn't process your request. Please try again later.",
                isUser: false,
                timestamp: Date()
            )

            chatMessages.append(errorMessage)
        }

        isSendingMessage = false
    }

    // Legacy support for simple HealthContext
    func sendMessage(healthContext: HealthContext) async {
        let extendedContext = ExtendedHealthContext(
            todaySleep: healthContext.sleep,
            todayActivity: healthContext.activity,
            todayHeart: healthContext.heart,
            sleepHistory: [],
            activityHistory: [],
            heartHistory: []
        )
        await sendMessage(healthContext: extendedContext)
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
