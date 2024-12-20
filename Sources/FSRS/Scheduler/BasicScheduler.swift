//
//  BasicScheduler.swift
//
//  Created by nkq on 10/14/24.
//

import Foundation

class BasicScheduler: AbstractScheduler {
    override func newState(grade: Rating) -> RecordLogItem {
        if let item = next[grade] { return item }
        var next = current.newCard
        next.difficulty = algorithm.initDifficulty(grade)
        next.stability = algorithm.initStability(g: grade)
        switch grade {
        case .again:
            next.scheduledDays = 0
            next.due = Date.dateScheduler(now: reviewTime, t: 1)
            next.state = .learning
        case .hard:
            next.scheduledDays = 0
            next.due = Date.dateScheduler(now: reviewTime, t: 5)
            next.state = .learning
        case .good:
            next.scheduledDays = 0
            next.due = Date.dateScheduler(now: reviewTime, t: 10)
            next.state = .learning
        case .easy:
            let easyInterval = algorithm.nextInterval(
                s: next.stability,
                elapsedDays: current.elapsedDays
            )
            next.scheduledDays = Double(easyInterval)
            next.due = Date.dateScheduler(now: reviewTime, t: Double(easyInterval), unit: .days)
            next.state = .review
        case .manual: break
        }
        return .init(card: next, log: buildLog(rating: grade))
    }

    override func learningState(grade: Rating) -> RecordLogItem {
        if let item = next[grade] { return item }
        var next = current.newCard
        let interval = current.elapsedDays
        next.difficulty = algorithm.nextDifficulty(d: last.difficulty, g: grade)
        next.stability = algorithm.nextShortTermStability(s: last.stability, g: grade)
        switch grade {
        case .again:
            next.scheduledDays = 0
            next.due = Date.dateScheduler(now: reviewTime, t: 5)
            next.state = last.state
        case .hard:
            next.scheduledDays = 0
            next.due = Date.dateScheduler(now: reviewTime, t: 10)
            next.state = last.state
        case .good:
            let goodInterval = algorithm.nextInterval(
                s: next.stability,
                elapsedDays: interval
            )
            next.scheduledDays = Double(goodInterval)
            next.due = Date.dateScheduler(now: reviewTime, t: Double(goodInterval), unit: .days)
            next.state = .review
        case .easy:
            let goodStability = algorithm.nextShortTermStability(
                s: last.stability,
                g: .good
            )
            let goodInterval = algorithm.nextInterval(
                s: goodStability,
                elapsedDays: interval
            )
            let easyInterval = max(algorithm.nextInterval(
                s: next.stability,
                elapsedDays: interval
            ), goodInterval + 1)
            next.scheduledDays = Double(easyInterval)
            next.due = Date.dateScheduler(now: reviewTime, t: Double(easyInterval), unit: .days)
            next.state = .review
        case .manual: break
        }
        return .init(card: next, log: buildLog(rating: grade))
    }

    override func reviewState(grade: Rating) -> RecordLogItem {
        if let item = next[grade] { return item }
        let interval = current.elapsedDays
        let retrievability = algorithm.forgettingCurve(
            elapsedDays: interval, stability: last.stability
        )
        let nextArray = Array(repeating: current.newCard, count: 4)
        var nextAgain = nextArray[0]
        var nextHard = nextArray[1]
        var nextGood = nextArray[2]
        var nextEasy = nextArray[3]
        
        nextDs(
            &nextAgain, &nextHard, &nextGood, &nextEasy,
            difficulty: last.difficulty,
            stability: last.stability,
            retrievability: retrievability
        )
        
        nextInterval(&nextAgain, &nextHard, &nextGood, &nextEasy, interval: interval)
        nextState(&nextAgain, &nextHard, &nextGood, &nextEasy)
        
        nextAgain.lapses += 1
        
        let itemAgain = RecordLogItem(
            card: nextAgain,
            log: buildLog(rating: .again)
        )
        let itemHard = RecordLogItem(
            card: nextHard,
            log: buildLog(rating: .hard)
        )
        let itemGood = RecordLogItem(
            card: nextGood,
            log: buildLog(rating: .good)
        )
        let itemEasy = RecordLogItem(
            card: nextEasy,
            log: buildLog(rating: .easy)
        )
        
        next[.again] = itemAgain
        next[.hard] = itemHard
        next[.good] = itemGood
        next[.easy] = itemEasy

        return next[grade]!
    }

    private func nextDs(
        _ nextAgain: inout Card,
        _ nextHard: inout Card,
        _ nextGood: inout Card,
        _ nextEasy: inout Card,
        difficulty: Double,
        stability: Double,
        retrievability: Double
    ) {
        nextAgain.difficulty = algorithm.nextDifficulty(d: difficulty, g: .again)
        let nextSMin = stability / exp(algorithm.parameters.w[17] * algorithm.parameters.w[18])
        nextAgain.stability = min(nextSMin.toFixedNumber(8), algorithm.nextForgetStability(d: difficulty, s: stability, r: retrievability))
        
        nextHard.difficulty = algorithm.nextDifficulty(d: difficulty, g: .hard)
        nextHard.stability = algorithm.nextRecallStability(
            d: difficulty, s: stability, r: retrievability, g: .hard
        )
        
        nextGood.difficulty = algorithm.nextDifficulty(d: difficulty, g: .good)
        nextGood.stability = algorithm.nextRecallStability(
            d: difficulty, s: stability, r: retrievability, g: .good
        )
        
        nextEasy.difficulty = algorithm.nextDifficulty(d: difficulty, g: .easy)
        nextEasy.stability = algorithm.nextRecallStability(
            d: difficulty, s: stability, r: retrievability, g: .easy
        )
    }

    private func nextInterval(
        _ nextAgain: inout Card,
        _ nextHard: inout Card,
        _ nextGood: inout Card,
        _ nextEasy: inout Card,
        interval: Double
    ) {
        var hardInterval = algorithm.nextInterval(
            s: nextHard.stability, elapsedDays: interval
        )
        var goodInterval = algorithm.nextInterval(
            s: nextGood.stability, elapsedDays: interval
        )
        hardInterval = min(hardInterval, goodInterval)
        goodInterval = max(goodInterval, hardInterval + 1)
        let easyInteval = max(
            algorithm.nextInterval(s: nextEasy.stability, elapsedDays: interval),
            goodInterval + 1
        )
        nextAgain.scheduledDays = 0
        nextAgain.due = Date.dateScheduler(now: reviewTime, t: 5)
        
        nextHard.scheduledDays = Double(hardInterval)
        nextHard.due = Date.dateScheduler(now: reviewTime, t: Double(hardInterval), unit: .days)
        
        nextGood.scheduledDays = Double(goodInterval)
        nextGood.due = Date.dateScheduler(now: reviewTime, t: Double(goodInterval), unit: .days)
        
        nextEasy.scheduledDays = Double(easyInteval)
        nextEasy.due = Date.dateScheduler(now: reviewTime, t: Double(easyInteval), unit: .days)
    }

    private func nextState(
        _ nextAgain: inout Card,
        _ nextHard: inout Card,
        _ nextGood: inout Card,
        _ nextEasy: inout Card
    ) {
        nextAgain.state = .relearning
        nextHard.state = .review
        nextGood.state = .review
        nextEasy.state = .review
    }
}
