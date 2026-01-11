import Foundation
import FirebaseFirestore

final class FirestoreService {
    private let db = Firestore.firestore()

    // MARK: - Health Data

    func saveHealthData(userId: String, date: Date, sleep: SleepData?, activity: ActivityData?, heart: HeartData?) async throws {
        let dateString = formatDate(date)
        let docRef = db.collection("users").document(userId).collection("healthData").document(dateString)

        var data: [String: Any] = [
            "date": Timestamp(date: date),
            "updatedAt": Timestamp(date: Date())
        ]

        if let sleep = sleep {
            data["sleep"] = try Firestore.Encoder().encode(sleep)
        }

        if let activity = activity {
            data["activity"] = try Firestore.Encoder().encode(activity)
        }

        if let heart = heart {
            data["heart"] = try Firestore.Encoder().encode(heart)
        }

        try await docRef.setData(data, merge: true)
    }

    func fetchHealthData(userId: String, for date: Date) async throws -> (SleepData?, ActivityData?, HeartData?) {
        let dateString = formatDate(date)
        let docRef = db.collection("users").document(userId).collection("healthData").document(dateString)

        let document = try await docRef.getDocument()

        guard document.exists, let data = document.data() else {
            return (nil, nil, nil)
        }

        let sleep = try? (data["sleep"] as? [String: Any]).flatMap {
            try Firestore.Decoder().decode(SleepData.self, from: $0)
        }

        let activity = try? (data["activity"] as? [String: Any]).flatMap {
            try Firestore.Decoder().decode(ActivityData.self, from: $0)
        }

        let heart = try? (data["heart"] as? [String: Any]).flatMap {
            try Firestore.Decoder().decode(HeartData.self, from: $0)
        }

        return (sleep, activity, heart)
    }

    func fetchHealthDataRange(userId: String, from startDate: Date, to endDate: Date) async throws -> [(Date, SleepData?, ActivityData?, HeartData?)] {
        let collectionRef = db.collection("users").document(userId).collection("healthData")

        let query = collectionRef
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThanOrEqualTo: Timestamp(date: endDate))
            .order(by: "date", descending: false)

        let snapshot = try await query.getDocuments()

        return snapshot.documents.compactMap { document in
            guard let data = document.data() as? [String: Any],
                  let timestamp = data["date"] as? Timestamp else {
                return nil
            }

            let date = timestamp.dateValue()

            let sleep = try? (data["sleep"] as? [String: Any]).flatMap {
                try Firestore.Decoder().decode(SleepData.self, from: $0)
            }

            let activity = try? (data["activity"] as? [String: Any]).flatMap {
                try Firestore.Decoder().decode(ActivityData.self, from: $0)
            }

            let heart = try? (data["heart"] as? [String: Any]).flatMap {
                try Firestore.Decoder().decode(HeartData.self, from: $0)
            }

            return (date, sleep, activity, heart)
        }
    }

    // MARK: - Insights

    func saveInsight(userId: String, insight: AIInsight) async throws {
        let collectionRef = db.collection("users").document(userId).collection("insights")
        try collectionRef.addDocument(from: insight)
    }

    func fetchInsights(userId: String, limit: Int = 20) async throws -> [AIInsight] {
        let collectionRef = db.collection("users").document(userId).collection("insights")

        let query = collectionRef
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        let snapshot = try await query.getDocuments()

        return snapshot.documents.compactMap { document in
            try? document.data(as: AIInsight.self)
        }
    }

    func fetchUnreadInsights(userId: String) async throws -> [AIInsight] {
        let collectionRef = db.collection("users").document(userId).collection("insights")

        let query = collectionRef
            .whereField("isRead", isEqualTo: false)
            .order(by: "createdAt", descending: true)

        let snapshot = try await query.getDocuments()

        return snapshot.documents.compactMap { document in
            try? document.data(as: AIInsight.self)
        }
    }

    func markInsightAsRead(userId: String, insightId: String) async throws {
        let docRef = db.collection("users").document(userId).collection("insights").document(insightId)
        try await docRef.updateData(["isRead": true])
    }

    // MARK: - User Profile

    func updateUserProfile(userId: String, updates: [String: Any]) async throws {
        let docRef = db.collection("users").document(userId)
        try await docRef.updateData(updates)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
