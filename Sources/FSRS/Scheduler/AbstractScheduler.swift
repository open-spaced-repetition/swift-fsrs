//
//  AbstractSch.swift
//
//  Created by nkq on 10/13/24.
//

import Foundation

class AbstractScheduler: IScheduler {
    var preview: IPreview {
        get throws {
            .init(recordLog: [
                .again: try review(.again),
                .hard: try review(.hard),
                .good: try review(.good),
                .easy: try review(.easy)
            ])
        }
    }
    var last: Card
    var current: Card
    var reviewTime: Date
    var next: [Rating: RecordLogItem] = [:]
    var algorithm: FSRSAlgorithm
    /// Per-call PRNG seed. Owned by the scheduler (which is created fresh per
    /// review) so concurrent calls on a shared `FSRSAlgorithm` don't race.
    let seed: String

    init(
        card: Card,
        reviewTime: Date,
        algorithm: FSRSAlgorithm
    ) {
        self.algorithm = algorithm
        self.last = card.newCard
        self.current = card.newCard
        self.reviewTime = reviewTime

        var interval = 0.0
        if current.state != .new && current.lastReview != nil {
            interval = Date.dateDiffInDays(from: current.lastReview, to: reviewTime)
        }
        self.current.lastReview = reviewTime
        self.current.elapsedDays = interval
        self.current.reps += 1
        let reviewTimeMilliseconds = Int64(reviewTime.timeIntervalSince1970 * 1_000)
        let memoryProduct = Self.javaScriptNumberString(current.difficulty * current.stability)
        self.seed = "\(reviewTimeMilliseconds)_\(current.reps)_\(memoryProduct)"
    }

    /// Match the common JavaScript `Number#toString` cases used in the
    /// ts-fsrs default seed. Swift includes `.0` for integral Doubles, which
    /// changes the Alea stream even though the numeric value is identical.
    private static func javaScriptNumberString(_ value: Double) -> String {
        if value == 0 { return "0" }
        if value.isFinite, value.rounded(.towardZero) == value, abs(value) < 1e21 {
            return String(format: "%.0f", locale: Locale(identifier: "en_US_POSIX"), value)
        }
        return String(value)
    }

    func review(_ g: Rating) throws -> RecordLogItem {
        switch last.state {
        case .new:
            return try newState(grade: g)
        case .learning, .relearning:
            return try learningState(grade: g)
        case .review:
            return try reviewState(grade: g)
        }
    }

    func newState(grade: Rating) throws -> RecordLogItem {
        print("subclass must override")
        return .init(card: Card(), log: ReviewLog(rating: .manual, state: .new, due: Date(), review: Date()))
    }
    func learningState(grade: Rating) throws -> RecordLogItem {
        print("subclass must override")
        return .init(card: Card(), log: ReviewLog(rating: .manual, state: .new, due: Date(), review: Date()))
    }
    func reviewState(grade: Rating) throws -> RecordLogItem {
        print("subclass must override")
        return .init(card: Card(), log: ReviewLog(rating: .manual, state: .new, due: Date(), review: Date()))
    }
    
    func buildLog(rating: Rating) -> ReviewLog {
        .init(rating: rating,
              state: current.state,
              due: last.lastReview == nil ? last.due : last.lastReview ?? Date(),
              stability: current.stability,
              difficulty: current.difficulty,
              elapsedDays: current.elapsedDays,
              lastElapsedDays: last.elapsedDays,
              scheduledDays: current.scheduledDays,
              learningSteps: current.learningSteps,
              review: reviewTime
        )
    }
}
