import Foundation

public struct FSRS {
    public let parameters: Parameters
    
    public init(parameters: Parameters = .init()) {
        self.parameters = parameters
    }
    
    public func scheduler(card: Card, now: Date) -> ImplScheduler {
        if parameters.isShortTermEnabled {
            return BasicScheduler(parameters: parameters, card: card, now: now)
        } else {
            return LongtermScheduler(parameters: parameters, card: card, now: now)
        }
    }
    
    public func `repeat`(card: Card, now: Date) -> RecordLog {
        var scheduler = scheduler(card: card, now: now)
        return scheduler.preview()
    }
    
    public func next(card: Card, now: Date, rating: Rating) -> SchedulingInfo {
        var scheduler = scheduler(card: card, now: now)
        return scheduler.review(rating: rating)
    }
}
