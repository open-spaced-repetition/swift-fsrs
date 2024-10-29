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

    var stringValue: String {
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

    var stringValue: String {
        switch self {
        case .manual: return "manual"
        case .again: return "again"
        case .hard: return "hard"
        case .good: return "good"
        case .easy: return "easy"
        }
    }
}

public struct ReviewLog: Equatable, Codable {
    var rating: Rating          // Rating of the review (Again, Hard, Good, Easy)
    var state: CardState?       // State of the review (New, Learning, Review, Relearning)
    var due: Date?              // Date of the last scheduling
    var stability: Double?      // Memory stability during the review
    var difficulty: Double?     // Difficulty of the card during the review
    var elapsedDays: Double     // Number of days elapsed since the last review
    var lastElapsedDays: Double // Number of days between the last two reviews
    var scheduledDays: Double   // Number of days until the next review
    var review: Date            // Date of the review

    public init(
        rating: Rating,
        state: CardState? = nil,
        due: Date? = nil,
        stability: Double? = nil,
        difficulty: Double? = nil,
        elapsedDays: Double = 0,
        lastElapsedDays: Double = 0,
        scheduledDays: Double = 0,
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
        self.review = review
    }

    var newLog: ReviewLog {
        ReviewLog(
            rating: rating,
            state: state,
            due: due,
            stability: stability,
            difficulty: difficulty,
            elapsedDays: elapsedDays,
            lastElapsedDays: lastElapsedDays,
            scheduledDays: scheduledDays,
            review: review
        )
    }
}

public struct Card: Equatable, Codable {
    public var due: Date             // Date when the card is next due for review
    public var stability: Double     // A measure of how well the information is retained
    public var difficulty: Double    // Reflects the inherent difficulty of the card content
    public var elapsedDays: Double   // Days since the card was last reviewed
    public var scheduledDays: Double // The interval at which the card is next scheduled
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
        self.reps = reps
        self.lapses = lapses
        self.state = state
        self.lastReview = lastReview
    }

    var newCard: Card {
        Card(
            due: due,
            stability: stability,
            difficulty: difficulty,
            elapsedDays: elapsedDays,
            scheduledDays: scheduledDays,
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

public struct RecordLogItem: Codable, Equatable {
    var card: Card
    var log: ReviewLog
}

public typealias RecordLog = [Rating: RecordLogItem]

public struct FSRSParameters: Codable, Equatable {
    var requestRetention: Double
    var maximumInterval: Double
    var w: [Double]
    var enableFuzz: Bool
    var enableShortTerm: Bool
    
    init(
        requestRetention: Double? = nil,
        maximumInterval: Double? = nil,
        w: [Double]? = nil,
        enableFuzz: Bool? = nil,
        enableShortTerm: Bool? = nil
    ) {
        let defaults = FSRSDefaults()
        self.requestRetention = requestRetention ?? defaults.defaultRequestRetention
        self.maximumInterval = maximumInterval ?? defaults.defaultMaximumInterval
        self.w = w ?? defaults.defaultW
        self.enableFuzz = enableFuzz ?? defaults.defaultEnableFuzz
        self.enableShortTerm = enableShortTerm ?? defaults.defaultEnableShortTerm
    }
}

public struct FSRSReview: Codable {
    /**
     * 0-4: Manual, Again, Hard, Good, Easy
     * = revlog.rating
     */
    var rating: Rating
    /**
     * The number of days that passed
     * = revlog.elapsed_days
     * = round(revlog[-1].review - revlog[-2].review)
     */
    var deltaT: Double
}
