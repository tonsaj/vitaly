//
//  FitnessViewModel.swift
//  Vitaly
//
//  Created by Claude on 2026-01-12.
//

import Foundation
import SwiftUI
import Observation

// MARK: - Helper Structures

/// Represents a day in the activity calendar
struct ActivityDay: Identifiable {
    let id = UUID()
    let date: Date
    let activityCount: Int
    let isToday: Bool
}

/// Represents a point in the activity trend
struct ActivityTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let cumulativeMinutes: Double
    let target: Double
}

/// Activity data for a specific day
struct DayActivityData {
    let calories: Double
    let exerciseMinutes: Int
    let steps: Int
    let workouts: [DayWorkout]
}

/// Workout session for a day
struct DayWorkout: Identifiable {
    let id = UUID()
    let type: String
    let duration: Int // minutes
    let calories: Double
    let icon: String

    var formattedDuration: String {
        if duration >= 60 {
            let hours = duration / 60
            let mins = duration % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(duration) min"
    }
}

// MARK: - ViewModel

@Observable
class FitnessViewModel {
    // MARK: - State

    var isLoading = false

    // MARK: - Calendar Data

    var activityDays: [ActivityDay] = []
    var previousMonthName: String = ""
    var currentMonthName: String = ""

    // MARK: - Activity Time

    var totalActivityTimeFormatted: String = "0h 0m"
    var dateRangeText: String = ""
    var targetTimeFormatted: String = "5h"
    var activityTrend: [ActivityTrendPoint] = []

    // MARK: - Strain

    var strainPerformanceText: String = "0%"
    var strainStatus: String = "Normal"
    var strainStatusColor: Color = .gray
    var strainHistory: [Double] = []

    // MARK: - Cardio Load

    var cardioLoad: Int = 0
    var cardioLoadStatus: String = "Balanced"
    var cardioLoadHistory: [Double] = []

    // MARK: - Cardio Focus

    var cardioFocusType: String = "Low Aerobic"
    var cardioFocusPercent: Int = 0
    var lowAerobicPercent: Int = 0
    var highAerobicPercent: Int = 0
    var anaerobicPercent: Int = 0

    // MARK: - Heart Rate Recovery

    var heartRateRecovery: Int = 0
    var hrrStatus: String = "Normal"
    var hrrHistory: [Double] = []

    // MARK: - AI Summary

    var aiSummary: String?
    var isLoadingAI = false
    private var hasLoadedAI = false

    // MARK: - Daily activity data (for calendar clicks)
    private var dailyActivityData: [Date: DayActivityData] = [:]

    // MARK: - Services

    private let healthKitService = HealthKitService()

    // MARK: - Public Methods

    /// Get activity data for a specific day
    func getActivityData(for date: Date) -> DayActivityData? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return dailyActivityData[startOfDay]
    }

    // MARK: - Initialization

    init() {
        setupInitialData()
    }

    // MARK: - Data Loading

    /// Load all fitness data from HealthKit
    @MainActor
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load data in parallel
            async let activityData = loadActivityCalendar()
            async let trendData = loadActivityTrend()
            async let strainData = loadStrainData()
            async let cardioData = loadCardioData()
            async let hrrData = loadHeartRateRecovery()

            // Wait for all results
            _ = try await (activityData, trendData, strainData, cardioData, hrrData)

            // Load AI summary after all data is loaded
            await loadAISummary()

        } catch {
            print("Error loading fitness data: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Loading Methods

    /// Load the activity calendar for the last 42 days (6 weeks)
    private func loadActivityCalendar() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Generate the last 42 days (6 weeks)
        var days: [ActivityDay] = []
        var activityDataMap: [Date: DayActivityData] = [:]

        for dayOffset in (0..<42).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Fetch activity data for the day
            let activityData = try await healthKitService.fetchActivityData(for: date)

            // Convert workouts to DayWorkout
            let dayWorkouts = activityData.workouts.map { workout in
                DayWorkout(
                    type: workout.workoutType,
                    duration: Int(workout.duration / 60),
                    calories: workout.calories,
                    icon: workoutIcon(for: workout.workoutType)
                )
            }

            // Save activity data for this day
            let startOfDay = calendar.startOfDay(for: date)
            activityDataMap[startOfDay] = DayActivityData(
                calories: activityData.activeCalories,
                exerciseMinutes: activityData.exerciseMinutes,
                steps: activityData.steps,
                workouts: dayWorkouts
            )

            // Only add days with actual workouts to the calendar
            if !dayWorkouts.isEmpty {
                let activityCount = dayWorkouts.count
                let isToday = calendar.isDateInToday(date)

                days.append(ActivityDay(
                    date: date,
                    activityCount: activityCount,
                    isToday: isToday
                ))
            }
        }

        activityDays = days
        dailyActivityData = activityDataMap

        // Update month labels
        if let firstDate = days.first?.date,
           let lastDate = days.last?.date {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMM"

            previousMonthName = formatter.string(from: firstDate).capitalized
            currentMonthName = formatter.string(from: lastDate).capitalized
        }
    }

    /// Load activity trend for the last week
    private func loadActivityTrend() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

        var trendPoints: [ActivityTrendPoint] = []
        var cumulativeMinutes = 0.0
        let targetPerDay = 300.0 / 7.0 // 5 hours per week

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekAgo) else { continue }

            let activityData = try await healthKitService.fetchActivityData(for: date)
            let dayMinutes = Double(activityData.exerciseMinutes)

            cumulativeMinutes += dayMinutes

            trendPoints.append(ActivityTrendPoint(
                date: date,
                cumulativeMinutes: cumulativeMinutes,
                target: targetPerDay * Double(dayOffset + 1)
            ))
        }

        activityTrend = trendPoints

        // Update total activity time
        let hours = Int(cumulativeMinutes) / 60
        let minutes = Int(cumulativeMinutes) % 60
        totalActivityTimeFormatted = "\(hours)h \(minutes)m"

        // Update date range
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMM"

        if let firstDate = trendPoints.first?.date,
           let lastDate = trendPoints.last?.date {
            dateRangeText = "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
        }
    }

    /// Load strain data
    private func loadStrainData() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

        // Fetch daily strain based on active energy expenditure
        var history: [Double] = []

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekAgo) else { continue }

            let activityData = try await healthKitService.fetchActivityData(for: date)
            let calories = activityData.activeCalories

            // Convert kcal to strain value (0-21 scale)
            let strain = min(21.0, calories / 50.0)
            history.append(strain)
        }

        strainHistory = history

        // Calculate performance change (latest day vs average)
        if let latestStrain = history.last, history.count > 1 {
            let previousAverage = history.dropLast().reduce(0, +) / Double(history.count - 1)
            let change = previousAverage > 0 ? ((latestStrain - previousAverage) / previousAverage) * 100 : 0

            strainPerformanceText = String(format: "%+.0f%%", change)

            // Determine status
            if latestStrain < 10 {
                strainStatus = "Light"
                strainStatusColor = .green
            } else if latestStrain < 14 {
                strainStatus = "Moderate"
                strainStatusColor = .yellow
            } else if latestStrain < 18 {
                strainStatus = "High"
                strainStatusColor = .orange
            } else {
                strainStatus = "Very High"
                strainStatusColor = .red
            }
        }
    }

    /// Load cardio load data
    private func loadCardioData() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Fetch heart rate data to calculate cardio load
        var history: [Double] = []
        var totalLowAerobic = 0.0
        var totalHighAerobic = 0.0
        var totalAnaerobic = 0.0

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset - 6, to: today) else { continue }

            let activityData = try await healthKitService.fetchActivityData(for: date)
            let exerciseTime = Double(activityData.exerciseMinutes)

            // Calculate cardio load based on exercise time (simplified model)
            let load = exerciseTime * 0.5
            history.append(load)

            // Simulate training zones (would need actual heart rate data)
            let lowAerobic = exerciseTime * 0.6
            let highAerobic = exerciseTime * 0.3
            let anaerobic = exerciseTime * 0.1

            totalLowAerobic += lowAerobic
            totalHighAerobic += highAerobic
            totalAnaerobic += anaerobic
        }

        cardioLoadHistory = history
        cardioLoad = Int(history.last ?? 0)

        // Determine status based on last week
        if cardioLoad < 50 {
            cardioLoadStatus = "Under Training"
        } else if cardioLoad < 150 {
            cardioLoadStatus = "Balanced"
        } else {
            cardioLoadStatus = "Overtraining"
        }

        // Calculate focus percentages
        let totalTime = totalLowAerobic + totalHighAerobic + totalAnaerobic
        if totalTime > 0 {
            lowAerobicPercent = Int((totalLowAerobic / totalTime) * 100)
            highAerobicPercent = Int((totalHighAerobic / totalTime) * 100)
            anaerobicPercent = Int((totalAnaerobic / totalTime) * 100)

            // Determine primary focus
            if lowAerobicPercent >= highAerobicPercent && lowAerobicPercent >= anaerobicPercent {
                cardioFocusType = "Low Aerobic"
                cardioFocusPercent = lowAerobicPercent
            } else if highAerobicPercent >= anaerobicPercent {
                cardioFocusType = "High Aerobic"
                cardioFocusPercent = highAerobicPercent
            } else {
                cardioFocusType = "Anaerobic"
                cardioFocusPercent = anaerobicPercent
            }
        }
    }

    /// Load heart rate recovery data
    private func loadHeartRateRecovery() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Fetch HRR history for the last week
        var history: [Double] = []

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset - 6, to: today) else { continue }

            // Simulate HRR value (would need actual workout data)
            // Normal HRR after 1 minute is 15-25 beats
            let hrr = Double.random(in: 15...25)
            history.append(hrr)
        }

        hrrHistory = history
        heartRateRecovery = Int(history.last ?? 20)

        // Determine status
        if heartRateRecovery < 12 {
            hrrStatus = "Poor Recovery"
        } else if heartRateRecovery < 22 {
            hrrStatus = "Normal"
        } else {
            hrrStatus = "Excellent Recovery"
        }
    }

    /// Load AI summary based on workout data
    @MainActor
    private func loadAISummary() async {
        guard !hasLoadedAI else { return }
        hasLoadedAI = true
        isLoadingAI = true

        do {
            // Calculate workout statistics with 0 handling
            let activeDays = activityDays.filter { $0.activityCount > 0 }.count
            let totalMinutes = activityTrend.last?.cumulativeMinutes ?? 0
            let avgStrain = strainHistory.isEmpty ? 0 : strainHistory.reduce(0, +) / Double(strainHistory.count)

            // Handle 0 values as "no data"
            let activeDaysText = activeDays > 0 ? "\(activeDays) of 7" : "none registered"
            let totalMinutesText = totalMinutes > 0 ? "\(Int(totalMinutes)) minutes" : "missing"
            let avgStrainText = avgStrain > 0 ? "\(String(format: "%.1f", avgStrain))/21" : "missing"
            let cardioFocusText = cardioFocusPercent > 0 ? "\(cardioFocusType) (\(cardioFocusPercent)%)" : "missing"
            let hrrText = heartRateRecovery > 0 ? "\(heartRateRecovery) bpm" : "missing"

            let prompt = """
            Analyze this week's workout data (in English, max 2-3 sentences):
            - Active days: \(activeDaysText)
            - Total training time: \(totalMinutesText)
            - Average strain: \(avgStrainText)
            - Cardio focus: \(cardioFocusText)
            - HRR: \(hrrText)

            Give a brief summary and a tip. If data is missing, mention what data is needed for better analysis.
            """

            aiSummary = try await GeminiService.shared.generateContent(prompt: prompt)
        } catch {
            aiSummary = "Keep training to get personalized insights based on your activity."
        }
        isLoadingAI = false
    }

    // MARK: - Setup

    /// Set up initial dummy data before real data is loaded
    private func setupInitialData() {
        let calendar = Calendar.current
        let today = Date()

        // Initial calendar data - only include days with workouts
        var days: [ActivityDay] = []
        for dayOffset in (0..<42).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let activityCount = Int.random(in: 0...3)
                // Only add days with activity
                if activityCount > 0 {
                    days.append(ActivityDay(
                        date: date,
                        activityCount: activityCount,
                        isToday: dayOffset == 0
                    ))
                }
            }
        }
        activityDays = days

        // Month labels
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM"

        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: today) {
            previousMonthName = formatter.string(from: previousMonth).capitalized
        }
        currentMonthName = formatter.string(from: today).capitalized

        // Initial trend data
        var trendPoints: [ActivityTrendPoint] = []
        let targetPerDay = 300.0 / 7.0

        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: dayOffset - 6, to: today) {
                trendPoints.append(ActivityTrendPoint(
                    date: date,
                    cumulativeMinutes: Double(dayOffset + 1) * 40,
                    target: targetPerDay * Double(dayOffset + 1)
                ))
            }
        }
        activityTrend = trendPoints

        // Initial strain history
        strainHistory = [12.5, 14.2, 13.8, 15.1, 14.5, 13.9, 14.7]

        // Initial cardio load history
        cardioLoadHistory = [85, 92, 88, 95, 90, 87, 93]

        // Initial HRR history
        hrrHistory = [18, 20, 19, 21, 22, 20, 21]
    }

    // MARK: - Helper Methods

    private func workoutIcon(for type: String) -> String {
        switch type.lowercased() {
        case "running":
            return "figure.run"
        case "walking":
            return "figure.walk"
        case "cycling":
            return "figure.outdoor.cycle"
        case "swimming":
            return "figure.pool.swim"
        case "yoga":
            return "figure.yoga"
        case "strength training":
            return "dumbbell.fill"
        case "hiit":
            return "flame.fill"
        case "soccer":
            return "sportscourt.fill"
        case "tennis":
            return "tennis.racket"
        case "golf":
            return "figure.golf"
        case "dance":
            return "figure.dance"
        case "hiking":
            return "figure.hiking"
        default:
            return "figure.mixed.cardio"
        }
    }
}
