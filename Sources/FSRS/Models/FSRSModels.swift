//
//  FSRSModels.swift
//
//  Created by nkq on 10/13/24.
//

import Foundation

public enum CardState: Int, Codable {
      case new = 0
      case learning = 1
      case review = 2
      case relearning = 3

    public var stringValue: String {
        switch self {
        case .new: return "new"
        case .learning: return "learning"
        case .review: return "review"
        case .relearning: return "relearning"
        }
    }
}

public enum Rating: Int, Codable, Equatable, CaseIterable  {
    case manual = 0, again = 1, hard, good, easy

    public var stringValue: String {
        switch self {
        case .manual: return "manual"
        case .again: return "again"
        case .hard: return "hard"
        case .good: return "good"
        case .easy: return "easy"
        }
    }
}

public struct ReviewLog: Equatable, Codable, Hashable {
    public var rating: Rating          // Rating of the review (Again, Hard, Good, Easy)
    public var state: CardState?       // State of the review (New, Learning, Review, Relearning)
    public var due: Date?              // Date of the last scheduling
    public var stability: Double?      // Memory stability during the review
    public var difficulty: Double?     // Difficulty of the card during the review
    public var elapsedDays: Double     // Number of days elapsed since the last review
    public var lastElapsedDays: Double // Number of days between the last two reviews
    public var scheduledDays: Double   // Number of days until the next review
    /// Tracks the current (re)learning step index. Always 0 in v5 (the v5
    /// scheduler doesn't expose configurable steps); meaningful only under v6.
    public var learningSteps: Int      // 0 = not in a step
    public var review: Date            // Date of the review

    public init(
        rating: Rating,
        state: CardState? = nil,
        due: Date? = nil,
        stability: Double? = nil,
        difficulty: Double? = nil,
        elapsedDays: Double = 0,
        lastElapsedDays: Double = 0,
        scheduledDays: Double = 0,
        learningSteps: Int = 0,
        review: Date
    ) {
        self.rating = rating
        self.state = state
        self.due = due
        self.stability = stability
        self.difficulty = difficulty
        self.elapsedDays = elapsedDays
        self.lastElapsedDays = lastElapsedDays
        self.scheduledDays = scheduledDays
        self.learningSteps = learningSteps
        self.review = review
    }

    enum CodingKeys: String, CodingKey {
        case rating, state, due, stability, difficulty
        case elapsedDays, lastElapsedDays, scheduledDays, learningSteps, review
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.rating = try c.decode(Rating.self, forKey: .rating)
        self.state = try c.decodeIfPresent(CardState.self, forKey: .state)
        self.due = try c.decodeIfPresent(Date.self, forKey: .due)
        self.stability = try c.decodeIfPresent(Double.self, forKey: .stability)
        self.difficulty = try c.decodeIfPresent(Double.self, forKey: .difficulty)
        self.elapsedDays = try c.decodeIfPresent(Double.self, forKey: .elapsedDays) ?? 0
        self.lastElapsedDays = try c.decodeIfPresent(Double.self, forKey: .lastElapsedDays) ?? 0
        self.scheduledDays = try c.decodeIfPresent(Double.self, forKey: .scheduledDays) ?? 0
        self.learningSteps = try c.decodeIfPresent(Int.self, forKey: .learningSteps) ?? 0
        self.review = try c.decode(Date.self, forKey: .review)
    }

    public var newLog: ReviewLog {
        ReviewLog(
            rating: rating,
            state: state,
            due: due,
            stability: stability,
            difficulty: difficulty,
            elapsedDays: elapsedDays,
            lastElapsedDays: lastElapsedDays,
            scheduledDays: scheduledDays,
            learningSteps: learningSteps,
            review: review
        )
    }
}

public struct Card: Equatable, Codable, Hashable {
    public var due: Date             // Date when the card is next due for review
    public var stability: Double     // A measure of how well the information is retained
    public var difficulty: Double    // Reflects the inherent difficulty of the card content
    public var elapsedDays: Double   // Days since the card was last reviewed
    public var scheduledDays: Double // The interval at which the card is next scheduled
    /// Index of the current (re)learning step. 0 means "not currently in a
    /// step". Always 0 under v5; meaningful under v6's `BasicSchedulerV6`.
    public var learningSteps: Int
    public var reps: Int             // Total number of times the card has been reviewed
    public var lapses: Int           // Times the card was forgotten or remembered incorrectly
    public var state: CardState      // The current state of the card (New, Learning, Review, Relearning)
    public var lastReview: Date?     // The most recent review date, if applicable

    public init(
        due: Date = Date(),
        stability: Double = 0,
        difficulty: Double = 0,
        elapsedDays: Double = 0,
        scheduledDays: Double = 0,
        learningSteps: Int = 0,
        reps: Int = 0,
        lapses: Int = 0,
        state: CardState = .new,
        lastReview: Date? = nil
    ) {
        self.due = due
        self.stability = stability
        self.difficulty = difficulty
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.learningSteps = learningSteps
        self.reps = reps
        self.lapses = lapses
        self.state = state
        self.lastReview = lastReview
    }

    enum CodingKeys: String, CodingKey {
        case due, stability, difficulty, elapsedDays, scheduledDays
        case learningSteps, reps, lapses, state, lastReview
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.due = try c.decode(Date.self, forKey: .due)
        self.stability = try c.decodeIfPresent(Double.self, forKey: .stability) ?? 0
        self.difficulty = try c.decodeIfPresent(Double.self, forKey: .difficulty) ?? 0
        self.elapsedDays = try c.decodeIfPresent(Double.self, forKey: .elapsedDays) ?? 0
        self.scheduledDays = try c.decodeIfPresent(Double.self, forKey: .scheduledDays) ?? 0
        self.learningSteps = try c.decodeIfPresent(Int.self, forKey: .learningSteps) ?? 0
        self.reps = try c.decodeIfPresent(Int.self, forKey: .reps) ?? 0
        self.lapses = try c.decodeIfPresent(Int.self, forKey: .lapses) ?? 0
        self.state = try c.decodeIfPresent(CardState.self, forKey: .state) ?? .new
        self.lastReview = try c.decodeIfPresent(Date.self, forKey: .lastReview)
    }

    public var newCard: Card {
        Card(
            due: due,
            stability: stability,
            difficulty: difficulty,
            elapsedDays: elapsedDays,
            scheduledDays: scheduledDays,
            learningSteps: learningSteps,
            reps: reps,
            lapses: lapses,
            state: state,
            lastReview: lastReview
        )
    }

    func printLog() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            print(data)
        } catch {
            print("Error serializing JSON: \(error)")
        }
    }
}

public struct RecordLogItem: Codable, Equatable, Hashable {
    public var card: Card
    public var log: ReviewLog
    
    public init(card: Card, log: ReviewLog) {
        self.card = card
        self.log = log
    }
}

public typealias RecordLog = [Rating: RecordLogItem]

public struct FSRSParameters: Codable, Equatable {
    public var requestRetention: Double
    public var maximumInterval: Double
    public var w: [Double]
    public var enableFuzz: Bool
    public var enableShortTerm: Bool
    /// Configurable learning steps applied by the v6 BasicScheduler when
    /// `enableShortTerm` is true. Each entry is a string like `"1m"`, `"10m"`,
    /// `"1h"`, or `"1d"`. Has no effect under v5 (the v5 scheduler uses
    /// hardcoded steps for backward compatibility).
    public var learningSteps: [String]
    /// Configurable relearning steps applied by the v6 BasicScheduler when
    /// transitioning a Review card via `again` back into Relearning. Has no
    /// effect under v5.
    public var relearningSteps: [String]

    public init(
        requestRetention: Double? = nil,
        maximumInterval: Double? = nil,
        w: [Double]? = nil,
        enableFuzz: Bool? = nil,
        enableShortTerm: Bool? = nil,
        learningSteps: [String]? = nil,
        relearningSteps: [String]? = nil
    ) {
        let defaults = FSRSDefaults()
        self.requestRetention = requestRetention ?? defaults.defaultRequestRetention
        self.maximumInterval = maximumInterval ?? defaults.defaultMaximumInterval
        self.w = w ?? defaults.defaultW
        self.enableFuzz = enableFuzz ?? defaults.defaultEnableFuzz
        self.enableShortTerm = enableShortTerm ?? defaults.defaultEnableShortTerm
        self.learningSteps = learningSteps ?? FSRSDefaults.defaultLearningSteps
        self.relearningSteps = relearningSteps ?? FSRSDefaults.defaultRelearningSteps
    }

    enum CodingKeys: String, CodingKey {
        case requestRetention, maximumInterval, w, enableFuzz, enableShortTerm
        case learningSteps, relearningSteps
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = FSRSDefaults()
        self.requestRetention = try c.decodeIfPresent(Double.self, forKey: .requestRetention) ?? defaults.defaultRequestRetention
        self.maximumInterval = try c.decodeIfPresent(Double.self, forKey: .maximumInterval) ?? defaults.defaultMaximumInterval
        self.w = try c.decodeIfPresent([Double].self, forKey: .w) ?? defaults.defaultW
        self.enableFuzz = try c.decodeIfPresent(Bool.self, forKey: .enableFuzz) ?? defaults.defaultEnableFuzz
        self.enableShortTerm = try c.decodeIfPresent(Bool.self, forKey: .enableShortTerm) ?? defaults.defaultEnableShortTerm
        self.learningSteps = try c.decodeIfPresent([String].self, forKey: .learningSteps) ?? FSRSDefaults.defaultLearningSteps
        self.relearningSteps = try c.decodeIfPresent([String].self, forKey: .relearningSteps) ?? FSRSDefaults.defaultRelearningSteps
    }
}

public struct FSRSReview: Codable {
    /**
     * 0-4: Manual, Again, Hard, Good, Easy
     * = revlog.rating
     */
    public var rating: Rating
    /**
     * The number of days that passed
     * = revlog.elapsed_days
     * = round(revlog[-1].review - revlog[-2].review)
     */
    public var deltaT: Double
}

public struct FSRSState: Codable {
    public var stability: Double
    public var difficulty: Double
}
