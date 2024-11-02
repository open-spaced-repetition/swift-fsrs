import Foundation

struct BasicScheduler {
    private(set) var scheduler: Scheduler
    
    init(parameters: Parameters, card: Card, now: Date) {
        self.scheduler = Scheduler(parameters: parameters, card: card, now: now)
    }
    
    private mutating func newState(rating: Rating) -> SchedulingInfo {
        if let info = scheduler.next[rating] {
            return info
        }
        
        var next = scheduler.current
        next.difficulty = scheduler.parameters.initDifficulty(rating: rating)
        next.stability = scheduler.parameters.initStability(rating: rating)
        
        switch rating {
        case .again:
            next.scheduledDays = 0
            next.due = scheduler.now.addingMinutes(1)
            next.state = .learning
        case .hard:
            next.scheduledDays = 0
            next.due = scheduler.now.addingMinutes(5)
            next.state = .learning
        case .good:
            next.scheduledDays = 0
            next.due = scheduler.now.addingMinutes(10)
            next.state = .learning
        case .easy:
            let easyInterval = scheduler
                .parameters
                .nextInterval(stability: next.stability, elapsedDays: next.elapsedDays)
            next.scheduledDays = Int64(easyInterval)
            next.due = scheduler.now.addingDays(Int64(easyInterval))
            next.state = .review
        }
        
        let item = SchedulingInfo(
            card: next,
            reviewLog: scheduler.buildLog(rating: rating)
        )
        
        scheduler.next[rating] = item
        return item
    }
    
    private mutating func learningState(rating: Rating) -> SchedulingInfo {
        if let info = scheduler.next[rating] {
            return info
        }
        
        let interval = scheduler.current.elapsedDays
        
        var next = scheduler.current
        next.difficulty = scheduler.parameters.nextDifficulty(difficulty: scheduler.last.difficulty, rating: rating)
        next.stability = scheduler.parameters.shortTermStability(stability: scheduler.last.stability, rating: rating)
        
        switch rating {
        case .again:
            next.scheduledDays = 0
            next.due = scheduler.now.addingMinutes(5)
            next.state = scheduler.last.state
        case .hard:
            next.scheduledDays = 0
            next.due = scheduler.now.addingMinutes(10)
            next.state = scheduler.last.state
        case .good:
            let goodInterval = scheduler
                .parameters
                .nextInterval(stability: next.stability, elapsedDays: interval)
            next.scheduledDays = Int64(goodInterval)
            next.due = scheduler.now.addingDays(Int64(goodInterval))
            next.state = .review
        case .easy:
            let goodStability = scheduler
                .parameters
                .shortTermStability(stability: scheduler.last.stability, rating: .good)
            let goodInterval = scheduler
                .parameters
                .nextInterval(stability: goodStability, elapsedDays: interval)
            let easyInterval = max(
                scheduler
                    .parameters
                    .nextInterval(stability: next.stability, elapsedDays: interval),
                goodInterval + 1
            )
            next.scheduledDays = Int64(easyInterval)
            next.due = scheduler.now.addingDays(Int64(easyInterval))
            next.state = .review
        }
        
        let item = SchedulingInfo(
            card: next,
            reviewLog: scheduler.buildLog(rating: rating)
        )
        
        scheduler.next[rating] = item
        return item
    }
    
    private mutating func reviewState(rating: Rating) -> SchedulingInfo {
        if let info = scheduler.next[rating] {
            return info
        }
        
        let next = scheduler.current
        let interval = scheduler.current.elapsedDays
        let stability = scheduler.last.stability
        let difficulty = scheduler.last.difficulty
        let retrievability = scheduler.last.retrievability(for: scheduler.now)
        
        var nextAgain = next
        var nextHard = next
        var nextGood = next
        var nextEasy = next
        
        nextDifficultyStability(
            nextAgain: &nextAgain,
            nextHard: &nextHard,
            nextGood: &nextGood,
            nextEasy: &nextEasy,
            difficulty: difficulty,
            stability: stability,
            retrievability: retrievability
        )
        nextInterval(
            nextAgain: &nextAgain,
            nextHard: &nextHard,
            nextGood: &nextGood,
            nextEasy: &nextEasy,
            elapsedDays: interval
        )
        Self.nextState(
            nextAgain: &nextAgain,
            nextHard: &nextHard,
            nextGood: &nextGood,
            nextEasy: &nextEasy
        )
        nextAgain.lapses += 1
        
        let itemAgain = SchedulingInfo(
            card: nextAgain,
            reviewLog: scheduler.buildLog(rating: .again)
        )
        let itemHard = SchedulingInfo(
            card: nextHard,
            reviewLog: scheduler.buildLog(rating: .hard)
        )
        let itemGood = SchedulingInfo(
            card: nextGood,
            reviewLog: scheduler.buildLog(rating: .good)
        )
        let itemEasy = SchedulingInfo(
            card: nextEasy,
            reviewLog: scheduler.buildLog(rating: .easy)
        )
        
        scheduler.next[.again] = itemAgain
        scheduler.next[.hard] = itemHard
        scheduler.next[.good] = itemGood
        scheduler.next[.easy] = itemEasy
        
        return scheduler.next[rating]!
    }
    
    private func nextDifficultyStability(
        nextAgain: inout Card,
        nextHard: inout Card,
        nextGood: inout Card,
        nextEasy: inout Card,
        difficulty: Float64,
        stability: Float64,
        retrievability: Float64
    ) {
        nextAgain.difficulty = scheduler.parameters.nextDifficulty(difficulty: difficulty, rating: .again)
        nextAgain.stability = scheduler
            .parameters
            .nextForgetStability(
                difficulty: difficulty,
                stability: stability,
                retrievability: retrievability
            )
        
        nextHard.difficulty = scheduler.parameters.nextDifficulty(difficulty: difficulty, rating: .hard)
        nextHard.stability = scheduler
            .parameters
            .nextRecallStability(
                difficulty: difficulty,
                stability: stability,
                retrievability: retrievability,
                rating: .hard
            )
        
        nextGood.difficulty = scheduler
            .parameters
            .nextDifficulty(difficulty: difficulty, rating: .good)
        nextGood.stability = scheduler
            .parameters
            .nextRecallStability(
                difficulty: difficulty,
                stability: stability,
                retrievability: retrievability,
                rating: .good
            )
        
        nextEasy.difficulty = scheduler
            .parameters
            .nextDifficulty(difficulty: difficulty, rating: .easy)
        nextEasy.stability = scheduler
            .parameters
            .nextRecallStability(
                difficulty: difficulty,
                stability: stability,
                retrievability: retrievability,
                rating: .easy
            )
    }
    
    private func nextInterval(
        nextAgain: inout Card,
        nextHard: inout Card,
        nextGood: inout Card,
        nextEasy: inout Card,
        elapsedDays: Int64
    ) {
        var hardInterval = scheduler
            .parameters
            .nextInterval(stability: nextHard.stability, elapsedDays: elapsedDays)
        var goodInterval = scheduler
            .parameters
            .nextInterval(stability: nextGood.stability, elapsedDays: elapsedDays)
        hardInterval = min(hardInterval, goodInterval)
        goodInterval = max(goodInterval, hardInterval + 1)
        let easyInterval = max(
            scheduler
                .parameters
                .nextInterval(stability: nextEasy.stability, elapsedDays: elapsedDays),
            goodInterval + 1
        )
        
        nextAgain.scheduledDays = 0
        nextAgain.due = scheduler.now.addingMinutes(5)
        
        nextHard.scheduledDays = Int64(hardInterval)
        nextHard.due = scheduler.now.addingDays(Int64(hardInterval))
        
        nextGood.scheduledDays = Int64(goodInterval)
        nextGood.due = scheduler.now.addingDays(Int64(goodInterval))
        
        nextEasy.scheduledDays = Int64(easyInterval)
        nextEasy.due = scheduler.now.addingDays(Int64(easyInterval))
    }
    
    private static func nextState(
        nextAgain: inout Card,
        nextHard: inout Card,
        nextGood: inout Card,
        nextEasy: inout Card
    ) {
        nextAgain.state = .relearning
        nextHard.state = .review
        nextGood.state = .review
        nextEasy.state = .review
    }
}

extension BasicScheduler: ImplScheduler {
    mutating func review(rating: Rating) -> SchedulingInfo {
        switch scheduler.last.state {
        case .new:
            return newState(rating: rating)
        case .learning, .relearning:
            return learningState(rating: rating)
        case .review:
            return reviewState(rating: rating)
        }
    }
}
