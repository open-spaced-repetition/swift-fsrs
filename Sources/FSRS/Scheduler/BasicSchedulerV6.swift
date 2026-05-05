//
//  BasicSchedulerV6.swift
//
//  v6 BasicScheduler. Mirrors ts-fsrs's basic_scheduler.ts: delegates state
//  transitions to algorithm.nextState and applies configurable
//  learning/relearning steps via basicLearningStepsStrategy.
//

import Foundation

class BasicSchedulerV6: AbstractScheduler {

    private func getStepInfo(
        grade: Rating,
        fromState state: CardState,
        curStep: Int
    ) -> (scheduledMinutes: Int, nextStep: Int) {
        let strategy = basicLearningStepsStrategy(
            params: algorithm.parameters,
            state: state,
            curStep: curStep
        )
        let outcome = strategy[grade]
        return (
            scheduledMinutes: max(0, outcome?.scheduledMinutes ?? 0),
            nextStep: max(0, outcome?.nextStep ?? 0)
        )
    }

    private func applyLearningSteps(
        nextCard: inout Card,
        grade: Rating,
        toState: CardState
    ) {
        let info = getStepInfo(
            grade: grade,
            fromState: current.state,
            curStep: current.learningSteps
        )
        let mins = info.scheduledMinutes
        let nextSteps = info.nextStep

        if mins > 0 && mins < 1440 /** 1 day */ {
            nextCard.learningSteps = nextSteps
            nextCard.scheduledDays = 0
            nextCard.state = toState
            nextCard.due = Date.dateScheduler(now: reviewTime, t: Double(mins), unit: .minutes)
        } else {
            nextCard.state = .review
            if mins >= 1440 {
                nextCard.learningSteps = nextSteps
                nextCard.due = Date.dateScheduler(now: reviewTime, t: Double(mins), unit: .minutes)
                nextCard.scheduledDays = Double(mins / 1440)
            } else {
                nextCard.learningSteps = 0
                let interval = algorithm.nextInterval(
                    s: nextCard.stability,
                    elapsedDays: current.elapsedDays
                )
                nextCard.scheduledDays = Double(interval)
                nextCard.due = Date.dateScheduler(now: reviewTime, t: Double(interval), unit: .days)
            }
        }
    }

    /// Compute the next memory state via `algorithm.nextState`. v6's
    /// `nextState` handles the new-card init, manual-rating short-circuit,
    /// short-term path, again-clamp, and recall path internally — keeping
    /// the scheduler thin.
    private func nextDs(t: Double, grade: Rating) -> Card {
        var card = current.newCard
        do {
            let memoryState = FSRSState(stability: current.stability, difficulty: current.difficulty)
            let nextState = try algorithm.nextState(memoryState: memoryState, t: t, g: grade)
            card.difficulty = nextState.difficulty
            card.stability = nextState.stability
        } catch {
            // Defensive: shouldn't trigger for cards routed through this scheduler.
            print(error.localizedDescription)
        }
        return card
    }

    override func newState(grade: Rating) -> RecordLogItem {
        if let item = next[grade] { return item }
        var card = nextDs(t: current.elapsedDays, grade: grade)
        applyLearningSteps(nextCard: &card, grade: grade, toState: .learning)
        let item = RecordLogItem(card: card, log: buildLog(rating: grade))
        next[grade] = item
        return item
    }

    override func learningState(grade: Rating) -> RecordLogItem {
        if let item = next[grade] { return item }
        var card = nextDs(t: current.elapsedDays, grade: grade)
        applyLearningSteps(nextCard: &card, grade: grade, toState: last.state)
        let item = RecordLogItem(card: card, log: buildLog(rating: grade))
        next[grade] = item
        return item
    }

    override func reviewState(grade: Rating) -> RecordLogItem {
        if let item = next[grade] { return item }
        let interval = current.elapsedDays

        var nextAgain = nextDs(t: interval, grade: .again)
        var nextHard = nextDs(t: interval, grade: .hard)
        var nextGood = nextDs(t: interval, grade: .good)
        var nextEasy = nextDs(t: interval, grade: .easy)

        nextIntervalReview(&nextHard, &nextGood, &nextEasy, interval: interval)
        nextStateReview(&nextHard, &nextGood, &nextEasy)
        applyLearningSteps(nextCard: &nextAgain, grade: .again, toState: .relearning)
        nextAgain.lapses += 1

        next[.again] = RecordLogItem(card: nextAgain, log: buildLog(rating: .again))
        next[.hard] = RecordLogItem(card: nextHard, log: buildLog(rating: .hard))
        next[.good] = RecordLogItem(card: nextGood, log: buildLog(rating: .good))
        next[.easy] = RecordLogItem(card: nextEasy, log: buildLog(rating: .easy))

        return next[grade]!
    }

    private func nextIntervalReview(
        _ nextHard: inout Card,
        _ nextGood: inout Card,
        _ nextEasy: inout Card,
        interval: Double
    ) {
        var hardInterval = algorithm.nextInterval(s: nextHard.stability, elapsedDays: interval)
        var goodInterval = algorithm.nextInterval(s: nextGood.stability, elapsedDays: interval)
        hardInterval = min(hardInterval, goodInterval)
        goodInterval = max(goodInterval, hardInterval + 1)
        let easyInterval = max(
            algorithm.nextInterval(s: nextEasy.stability, elapsedDays: interval),
            goodInterval + 1
        )

        nextHard.scheduledDays = Double(hardInterval)
        nextHard.due = Date.dateScheduler(now: reviewTime, t: Double(hardInterval), unit: .days)
        nextGood.scheduledDays = Double(goodInterval)
        nextGood.due = Date.dateScheduler(now: reviewTime, t: Double(goodInterval), unit: .days)
        nextEasy.scheduledDays = Double(easyInterval)
        nextEasy.due = Date.dateScheduler(now: reviewTime, t: Double(easyInterval), unit: .days)
    }

    private func nextStateReview(
        _ nextHard: inout Card,
        _ nextGood: inout Card,
        _ nextEasy: inout Card
    ) {
        nextHard.state = .review
        nextHard.learningSteps = 0
        nextGood.state = .review
        nextGood.learningSteps = 0
        nextEasy.state = .review
        nextEasy.learningSteps = 0
    }
}
