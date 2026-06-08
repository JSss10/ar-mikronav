// FeedbackService.swift
// ARMikronav
//
// Schreibt BarrierFeedback in die Supabase-Tabelle `user_feedback`.
// Status defaultet serverseitig auf 'pending' (siehe Database/schema.sql).

import Foundation
import Supabase

enum FeedbackServiceError: Error {
    case notAuthenticated
}

final class FeedbackService: @unchecked Sendable {
    static let shared = FeedbackService()

    private let client = SupabaseService.shared.client

    func submit(
        barrierId: UUID,
        type: FeedbackType,
        correctValue: Double?,
        comment: String?
    ) async throws {
        guard let userId = await AuthService.shared.currentUser?.id else {
            throw FeedbackServiceError.notAuthenticated
        }

        let trimmedComment = comment?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let feedback = BarrierFeedback(
            barrierId: barrierId,
            userId: userId,
            feedbackType: type,
            correctValue: type.supportsCorrectValue ? correctValue : nil,
            comment: trimmedComment?.isEmpty == false ? trimmedComment : nil
        )

        try await client
            .from("user_feedback")
            .insert(feedback)
            .execute()
    }
}
