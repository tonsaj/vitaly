import Foundation
import FirebaseFirestore

@MainActor
@Observable
final class BodyMeasurementService {
    var measurements: [BodyMeasurement] = []
    var isLoading = false
    var error: String?

    private let db = Firestore.firestore()
    private var userId: String?

    func setUserId(_ userId: String?) {
        self.userId = userId
        if userId != nil {
            Task {
                await fetchMeasurements()
            }
        } else {
            measurements = []
        }
    }

    // MARK: - Fetch Measurements
    func fetchMeasurements(limit: Int = 30) async {
        guard let userId = userId else { return }

        // Prevent a smaller fetch from overwriting a larger dataset
        let currentCount = measurements.count
        if isLoading && limit <= currentCount { return }

        isLoading = true
        error = nil

        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("bodyMeasurements")
                .order(by: "date", descending: true)
                .limit(to: limit)
                .getDocuments()

            let fetched = snapshot.documents.compactMap { doc in
                try? doc.data(as: BodyMeasurement.self)
            }

            // Only update if we got at least as many results as we already have,
            // or if this is a fresh fetch (no existing data)
            if fetched.count >= currentCount || currentCount == 0 {
                measurements = fetched
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Get Measurement for Date
    func getMeasurement(for date: Date) -> BodyMeasurement? {
        let calendar = Calendar.current
        return measurements.first { measurement in
            calendar.isDate(measurement.date, inSameDayAs: date)
        }
    }

    // MARK: - Save Measurement
    func saveMeasurement(_ measurement: BodyMeasurement) async throws {
        guard let userId = userId else {
            throw MeasurementError.notAuthenticated
        }

        var measurementToSave = measurement
        measurementToSave.updatedAt = Date()

        // Check if measurement for this date already exists
        if let existingId = getMeasurement(for: measurement.date)?.id {
            measurementToSave.id = existingId
            try db.collection("users")
                .document(userId)
                .collection("bodyMeasurements")
                .document(existingId)
                .setData(from: measurementToSave, merge: true)
        } else {
            let docRef = db.collection("users")
                .document(userId)
                .collection("bodyMeasurements")
                .document(measurement.dateKey)

            try docRef.setData(from: measurementToSave)
        }

        // Refresh data
        await fetchMeasurements()
    }

    // MARK: - Delete Measurement
    func deleteMeasurement(_ measurement: BodyMeasurement) async throws {
        guard let userId = userId,
              let measurementId = measurement.id else {
            throw MeasurementError.notAuthenticated
        }

        try await db.collection("users")
            .document(userId)
            .collection("bodyMeasurements")
            .document(measurementId)
            .delete()

        await fetchMeasurements()
    }

    // MARK: - Get Latest
    var latestWeight: Double? {
        measurements.first(where: { $0.weight != nil })?.weight
    }

    var latestWaist: Double? {
        measurements.first(where: { $0.waistCircumference != nil })?.waistCircumference
    }

    // MARK: - Trends
    func weightTrend(days: Int = 7) -> [Double] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!

        return measurements
            .filter { $0.date >= startDate && $0.weight != nil }
            .sorted { $0.date < $1.date }
            .compactMap { $0.weight }
    }

    func waistTrend(days: Int = 7) -> [Double] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!

        return measurements
            .filter { $0.date >= startDate && $0.waistCircumference != nil }
            .sorted { $0.date < $1.date }
            .compactMap { $0.waistCircumference }
    }
}

enum MeasurementError: LocalizedError {
    case notAuthenticated
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Du måste vara inloggad för att spara mätningar"
        case .saveFailed:
            return "Kunde inte spara mätningen"
        }
    }
}
