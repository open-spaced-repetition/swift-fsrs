import Foundation

@frozen
public enum State: Int, Equatable, Codable {
    case new = 0
    case learning
    case review
    case relearning
}

@frozen
public enum Rating: Int, Equatable, Hashable, Codable, CaseIterable {
    case again = 1
    case hard
    case good
    case easy
}

public struct SchedulingInfo {
    public let card: Card
    public let reviewLog: ReviewLog
    
    public init(card: Card, reviewLog: ReviewLog) {
        self.card = card
        self.reviewLog = reviewLog
    }
}

public typealias RecordLog = [Rating: SchedulingInfo]

public struct ReviewLog: Equatable, Codable {
    public let rating: Rating
    public let elapsedDays: Int64
    public let scheduledDays: Int64
    public let state: State
    public let reviewedDate: Date
    
    init(
        rating: Rating,
        elapsedDays: Int64,
        scheduledDays: Int64,
        state: State,
        reviewedDate: Date
    ) {
        self.rating = rating
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.state = state
        self.reviewedDate = reviewedDate
    }
}

public struct Card: Equatable, Codable {
    public internal(set) var due: Date
    public internal(set) var stability: Float64
    public internal(set) var difficulty: Float64
    public internal(set) var elapsedDays: Int64
    public internal(set) var scheduledDays: Int64
    public internal(set) var reps: Int32
    public internal(set) var lapses: Int32
    public internal(set) var state: State
    public internal(set) var lastReview: Date
    
    public init(
        due: Date = .now,
        stability: Float64 = 0,
        difficulty: Float64 = 0,
        elapsedDays: Int64 = 0,
        scheduledDays: Int64 = 0,
        reps: Int32 = 0,
        lapses: Int32 = 0,
        state: State = .new,
        lastReview: Date = .now
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
    
    func retrievability(for now: Date) -> Float64 {
        switch state {
        case .new:
            return 0
        default:
            let elapsedDays = Int64((now.timeIntervalSince1970 - lastReview.timeIntervalSince1970) / 60 / 60 / 24)
            return Parameters.forgettingCurve(elapsedDays: Float64(elapsedDays), stability: stability)
        }
    }
}
