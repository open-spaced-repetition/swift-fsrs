//
//  LongTermScheduler.swift
//
//  Created by nkq on 10/14/24.
//

import Foundation

class LongTermScheduler: AbstractScheduler {
    override func newState(grade: Rating) -> RecordLogItem {
        if let item = next[grade] { return item }
        
        current.scheduledDays = 0
        current.elapsedDays = 0
        
        let nextArray = Array(repeating: current.newCard, count: 4)
        var nextAgain = nextArray[0]
        var nextHard = nextArray[1]
        var nextGood = nextArray[2]
        var nextEasy = nextArray[3]
        
        initDs(&nextAgain, &nextHard, &nextGood, &nextEasy)
        
        let firstInterval = 0.0
        
        nextInterval(&nextAgain, &nextHard, &nextGood, &nextEasy, interval: firstInterval)
        
        nextState(&nextAgain, &nextHard, &nextGood, &nextEasy)
        
        updateNext(&nextAgain, &nextHard, &nextGood, &nextEasy)
        
        return next[grade]!
    }
    
    override func learningState(grade: Rating) -> RecordLogItem {
        reviewState(grade: grade)
    }
    
    override func reviewState(grade: Rating) -> RecordLogItem {
        if let item = next[grade] { return item }
        
        let interval = current.elapsedDays
        let retrievability = algorithm.forgettingCurve(elapsedDays: interval, stability: last.stability)
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
        
        updateNext(&nextAgain, &nextHard, &nextGood, &nextEasy)
        
        return next[grade]!
    }
    
    private func initDs(
        _ nextAgain: inout Card,
        _ nextHard: inout Card,
        _ nextGood: inout Card,
        _ nextEasy: inout Card
    ) {
        nextAgain.difficulty = algorithm.initDifficulty(.again)
        nextAgain.stability = algorithm.initStability(g: .again)
        
        nextHard.difficulty = algorithm.initDifficulty(.hard)
        nextHard.stability = algorithm.initStability(g: .hard)
        
        nextGood.difficulty = algorithm.initDifficulty(.good)
        nextGood.stability = algorithm.initStability(g: .good)
        
        nextEasy.difficulty = algorithm.initDifficulty(.easy)
        nextEasy.stability = algorithm.initStability(g: .easy)
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
        let sAfterAll = algorithm.nextForgetStability(d: difficulty, s: stability, r: retrievability)
        nextAgain.stability = FSRSHelper.clamp(stability, FSRSDefaults.S_MIN, sAfterAll)
        
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
        let againInterval = algorithm.nextInterval(s: nextAgain.stability, elapsedDays: interval)
        let hardInterval = algorithm.nextInterval(s: nextHard.stability, elapsedDays: interval)
        let goodInterval = algorithm.nextInterval(s: nextGood.stability, elapsedDays: interval)
        let easyInterval = algorithm.nextInterval(s: nextEasy.stability, elapsedDays: interval)
        
        
        let newAgainInterval = min(againInterval, hardInterval)
        let newHardInterval = max(hardInterval, (againInterval + 1))
        let newGoodInterval = max(goodInterval, (hardInterval + 1))
        let newEasyInterval = max(easyInterval, (goodInterval + 1))

        nextAgain.scheduledDays = Double(newAgainInterval)
        nextAgain.due = Date.dateScheduler(now: reviewTime, t: Double(newAgainInterval), unit: .days)
        
        nextHard.scheduledDays = Double(newHardInterval)
        nextHard.due = Date.dateScheduler(now: reviewTime, t: Double(newHardInterval), unit: .days)
        
        nextGood.scheduledDays = Double(newGoodInterval)
        nextGood.due = Date.dateScheduler(now: reviewTime, t: Double(newGoodInterval), unit: .days)
        
        nextEasy.scheduledDays = Double(newEasyInterval)
        nextEasy.due = Date.dateScheduler(now: reviewTime, t: Double(newEasyInterval), unit: .days)
    }

    private func nextState(
        _ nextAgain: inout Card,
        _ nextHard: inout Card,
        _ nextGood: inout Card,
        _ nextEasy: inout Card
    ) {
        nextAgain.state = .review
        nextHard.state = .review
        nextGood.state = .review
        nextEasy.state = .review
    }

    private func updateNext(
        _ nextAgain: inout Card,
        _ nextHard: inout Card,
        _ nextGood: inout Card,
        _ nextEasy: inout Card
    ) {
        let again = RecordLogItem(card: nextAgain, log: buildLog(rating: .again))
        let hard = RecordLogItem(card: nextHard, log: buildLog(rating: .hard))
        let good = RecordLogItem(card: nextGood, log: buildLog(rating: .good))
        let easy = RecordLogItem(card: nextEasy, log: buildLog(rating: .easy))
        
        next[.again] = again
        next[.hard] = hard
        next[.good] = good
        next[.easy] = easy
    }
}
