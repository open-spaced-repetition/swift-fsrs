import Foundation

struct LongtermScheduler {
    private(set) var scheduler: Scheduler
    
    init(parameters: Parameters, card: Card, now: Date) {
        self.scheduler = Scheduler(parameters: parameters, card: card, now: now)
    }
    
    private mutating func newState(rating: Rating) -> SchedulingInfo {
        if let info = scheduler.next[rating] {
            return info
        }

        let next = scheduler.current
        scheduler.current.scheduledDays = 0;
        scheduler.current.elapsedDays = 0;

        var nextAgain = next
        var nextHard = next
        var nextGood = next
        var nextEasy = next

        initDifficultyStability(
            nextAgain: &nextAgain,
            nextHard: &nextHard,
            nextGood: &nextGood,
            nextEasy: &nextEasy
        )
        nextInterval(
            nextAgain: &nextAgain,
            nextHard: &nextHard,
            nextGood: &nextGood,
            nextEasy: &nextEasy,
            elapsedDays: 0
        )
        Self.nextState(
            nextAgain: &nextAgain,
            nextHard: &nextHard,
            nextGood: &nextGood,
            nextEasy: &nextEasy
        )
        updateNext(
            nextAgain: &nextAgain,
            nextHard: &nextHard,
            nextGood: &nextGood,
            nextEasy: &nextEasy
        )

        return scheduler.next[rating]!
    }
    
    private mutating func learningState(rating: Rating) -> SchedulingInfo {
        reviewState(rating: rating)
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

        updateNext(
            nextAgain: &nextAgain,
            nextHard: &nextHard,
            nextGood: &nextGood,
            nextEasy: &nextEasy
        )
        return scheduler.next[rating]!
    }
    
    private func initDifficultyStability(
        nextAgain: inout Card,
        nextHard: inout Card,
        nextGood: inout Card,
        nextEasy: inout Card
    ) {
        nextAgain.difficulty = scheduler.parameters.initDifficulty(rating: .again)
        nextAgain.stability = scheduler.parameters.initStability(rating: .again)

        nextHard.difficulty = scheduler.parameters.initDifficulty(rating: .hard)
        nextHard.stability = scheduler.parameters.initStability(rating: .again)

        nextGood.difficulty = scheduler.parameters.initDifficulty(rating: .good)
        nextGood.stability = scheduler.parameters.initStability(rating: .good)

        nextEasy.difficulty = scheduler.parameters.initDifficulty(rating: .easy)
        nextEasy.stability = scheduler.parameters.initDifficulty(rating: .easy)
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
        nextAgain.difficulty = scheduler
            .parameters
            .nextDifficulty(difficulty: difficulty, rating: .again)
        nextAgain.stability = scheduler
            .parameters
            .nextForgetStability(difficulty: difficulty, stability: stability, retrievability: retrievability)

        nextHard.difficulty = scheduler
            .parameters
            .nextDifficulty(difficulty: difficulty, rating: .hard)
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
        var againInterval = scheduler
            .parameters
            .nextInterval(stability: nextAgain.stability, elapsedDays: elapsedDays)
        var hardInterval = scheduler
            .parameters
            .nextInterval(stability: nextHard.stability, elapsedDays: elapsedDays)
        var goodInterval = scheduler
            .parameters
            .nextInterval(stability: nextGood.stability, elapsedDays: elapsedDays)
        var easyInterval = scheduler
            .parameters
            .nextInterval(stability: nextEasy.stability, elapsedDays: elapsedDays)

        againInterval = min(againInterval, hardInterval)
        hardInterval = max(hardInterval, againInterval + 1)
        goodInterval = max(goodInterval, hardInterval + 1)
        easyInterval = max(easyInterval, goodInterval + 1)

        nextAgain.scheduledDays = Int64(againInterval)
        nextAgain.due = scheduler.now.addingDays(Int64(againInterval))
        
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
        nextAgain.state = .review
        nextHard.state = .review
        nextGood.state = .review
        nextEasy.state = .review
    }
    
    private mutating func updateNext(
        nextAgain: inout Card,
        nextHard: inout Card,
        nextGood: inout Card,
        nextEasy: inout Card
    ) {
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
    }
}

extension LongtermScheduler: ImplScheduler {
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

