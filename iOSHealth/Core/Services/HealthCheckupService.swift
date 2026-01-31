import Foundation
import FirebaseFirestore

@MainActor
@Observable
final class HealthCheckupService {
    var checkups: [HealthCheckup] = []
    var isLoading = false
    var error: String?

    private let db = Firestore.firestore()
    private var userId: String?

    func setUserId(_ userId: String?) {
        self.userId = userId
        if userId != nil {
            Task {
                await fetchCheckups()
            }
        } else {
            checkups = []
        }
    }

    // MARK: - Fetch Checkups
    func fetchCheckups(limit: Int = 50) async {
        guard let userId = userId else { return }

        isLoading = true
        error = nil

        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("healthCheckups")
                .order(by: "date", descending: true)
                .limit(to: limit)
                .getDocuments()

            checkups = snapshot.documents.compactMap { doc in
                try? doc.data(as: HealthCheckup.self)
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Save Checkup
    func saveCheckup(_ checkup: HealthCheckup) async throws {
        guard let userId = userId else {
            throw HealthCheckupError.notAuthenticated
        }

        var checkupToSave = checkup
        checkupToSave.updatedAt = Date()

        if let existingId = checkup.id {
            try db.collection("users")
                .document(userId)
                .collection("healthCheckups")
                .document(existingId)
                .setData(from: checkupToSave, merge: true)
        } else {
            let docRef = db.collection("users")
                .document(userId)
                .collection("healthCheckups")
                .document()

            try docRef.setData(from: checkupToSave)
        }

        await fetchCheckups()
    }

    // MARK: - Delete Checkup
    func deleteCheckup(_ checkup: HealthCheckup) async throws {
        guard let userId = userId,
              let checkupId = checkup.id else {
            throw HealthCheckupError.notAuthenticated
        }

        try await db.collection("users")
            .document(userId)
            .collection("healthCheckups")
            .document(checkupId)
            .delete()

        await fetchCheckups()
    }

    // MARK: - Convenience Accessors
    var latestCheckup: HealthCheckup? {
        checkups.first
    }

    func latestValue(for name: String) -> LabValue? {
        for checkup in checkups {
            if let value = checkup.labValues.first(where: {
                $0.name.lowercased() == name.lowercased()
            }) {
                return value
            }
        }
        return nil
    }
}

enum HealthCheckupError: LocalizedError {
    case notAuthenticated
    case parseFailed
    case noResponse

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to save health checkups"
        case .parseFailed:
            return "Could not parse the document"
        case .noResponse:
            return "No response from AI"
        }
    }
}
