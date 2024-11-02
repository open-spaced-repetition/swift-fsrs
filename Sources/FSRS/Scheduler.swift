import Foundation

struct Scheduler {
    var parameters: Parameters
    var last: Card
    var current: Card
    var now: Date
    var next: RecordLog
    
    init(
        parameters: Parameters,
        card: Card,
        now: Date
    ) {
        let elapsedDays = switch card.state {
        case .new:
            Int64(0)
        default:
            Int64(Calendar.current.dateComponents([.day], from: card.lastReview, to: now).day ?? 0)
        }
        var currentCard = card
        currentCard.elapsedDays = elapsedDays
        currentCard.reps = card.reps + 1
        currentCard.lastReview = now
        
        let seed: Seed = "\(Int64(now.timeIntervalSince1970))_\(currentCard.reps)_\(currentCard.difficulty * currentCard.stability)"
        
        var parameters = parameters
        parameters.seed = seed
        
        self.parameters = parameters
        self.last = card
        self.current = currentCard
        self.now = now
        self.next = RecordLog()
    }
    
    func buildLog(rating: Rating) -> ReviewLog {
        ReviewLog(
            rating: rating,
            elapsedDays: current.elapsedDays,
            scheduledDays: current.scheduledDays,
            state: current.state,
            reviewedDate: now
        )
    }
}

public protocol ImplScheduler {
    mutating func review(rating: Rating) -> SchedulingInfo
}

public extension ImplScheduler {
    mutating func preview() -> RecordLog {
        RecordLog(uniqueKeysWithValues: Rating.allCases
            .map { ($0, review(rating: $0)) }
        )
    }
}
