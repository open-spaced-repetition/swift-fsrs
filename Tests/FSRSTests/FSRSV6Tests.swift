//
//  FSRSV6Tests.swift
//
//  v6 parity tests modeled on ts-fsrs's FSRS-6.test.ts. Oracle values
//  (intervals, stabilities, difficulties) are taken verbatim from upstream
//  so the Swift port stays bit-comparable to ts-fsrs.
//

import XCTest
@testable import FSRS

final class FSRSV6Tests: XCTestCase {
    var calendar: Calendar = {
        var c = Calendar.current
        c.timeZone = .init(secondsFromGMT: 0)!
        return c
    }()

    // Default v6 weights (matches FSRSDefaults.defaultWv6).
    let w: [Double] = [
        0.212, 1.2931, 2.3065, 8.2956, 6.4133,
        0.8334, 3.0194, 0.001, 1.8722, 0.1666,
        0.796, 1.4835, 0.0614, 0.2629, 1.6483,
        0.6014, 1.8729, 0.5425, 0.0912, 0.0658,
        0.1542,
    ]

    // MARK: - Version detection

    func testVersionDetection() {
        let v5 = FSRS(parameters: .init())
        XCTAssertEqual(v5.version, .v5, "Default (no w) is v5")

        let v6 = FSRS(parameters: .init(w: w))
        XCTAssertEqual(v6.version, .v6, "21-length w is v6")

        XCTAssertEqual(FSRSDefaults.defaultWv6.count, 21)
    }

    // MARK: - First repeat (matches ts-fsrs FSRS-6.test 'first repeat')

    func testFirstRepeat() {
        let f = FSRS(parameters: .init(w: w))
        let card = FSRSDefaults().createEmptyCard()
        let now = calendar.date(from: DateComponents(year: 2022, month: 12, day: 29, hour: 12, minute: 30))!
        let log = f.repeat(card: card, now: now)

        var stability: [Double] = []
        var difficulty: [Double] = []
        var reps: [Int] = []
        var lapses: [Int] = []
        var scheduledDays: [Double] = []
        var states: [CardState] = []
        for grade in [Rating.again, .hard, .good, .easy] {
            let c = log[grade]!.card
            stability.append(c.stability)
            difficulty.append(c.difficulty)
            reps.append(c.reps)
            lapses.append(c.lapses)
            scheduledDays.append(c.scheduledDays)
            states.append(c.state)
        }

        XCTAssertEqual(stability, [0.212, 1.2931, 2.3065, 8.2956])
        // Difficulty rounded to 8 places per algorithm.toFixedNumber(8).
        XCTAssertEqual(difficulty[0], 6.4133, accuracy: 1e-7)
        XCTAssertEqual(difficulty[1], 5.11217071, accuracy: 1e-7)
        XCTAssertEqual(difficulty[2], 2.11810397, accuracy: 1e-7)
        XCTAssertEqual(difficulty[3], 1.0, accuracy: 1e-7)
        XCTAssertEqual(reps, [1, 1, 1, 1])
        XCTAssertEqual(lapses, [0, 0, 0, 0])
        XCTAssertEqual(scheduledDays, [0, 0, 0, 8])
        XCTAssertEqual(states, [.learning, .learning, .learning, .review])
    }

    // MARK: - Interval history (matches ts-fsrs FSRS-6.test 'ivl_history')

    func testIvlHistory() throws {
        let f = FSRS(parameters: .init(w: w))
        var card = FSRSDefaults().createEmptyCard()
        var now = calendar.date(from: DateComponents(year: 2022, month: 12, day: 29, hour: 12, minute: 30))!
        var schedulingCards = f.repeat(card: card, now: now)

        let ratings: [Rating] = [
            .good, .good, .good, .good, .good, .good,
            .again, .again, .good, .good, .good, .good, .good,
        ]

        var ivlHistory: [Int] = []
        for rating in ratings {
            // Cross-check: rollback round-trips, and `next(...)` agrees with `repeat(...)[grade]`.
            for check in [Rating.again, .hard, .good, .easy] {
                let rollback = try f.rollback(
                    card: schedulingCards[check]!.card,
                    log: schedulingCards[check]!.log
                )
                XCTAssertEqual(rollback, card)

                let elapsed = card.lastReview != nil
                    ? Date.dateDiff(now: now, pre: card.lastReview, unit: .days)
                    : 0
                XCTAssertEqual(schedulingCards[check]!.log.elapsedDays, elapsed)

                let tempF = FSRS(parameters: .init(w: w))
                let next = try tempF.next(card: card, now: now, grade: check)
                XCTAssertEqual(schedulingCards[check], next)
            }

            card = schedulingCards[rating]!.card
            ivlHistory.append(Int(card.scheduledDays))
            now = card.due
            schedulingCards = f.repeat(card: card, now: now)
        }

        XCTAssertEqual(ivlHistory, [0, 2, 11, 46, 163, 498, 0, 0, 2, 4, 7, 12, 21])
    }

    // MARK: - Memory state oracles

    private func runMemoryStateSequence(enableShortTerm: Bool) throws -> Card {
        let f = FSRS(parameters: .init(w: w, enableShortTerm: enableShortTerm))
        var card = FSRSDefaults().createEmptyCard()
        var now = calendar.date(from: DateComponents(year: 2022, month: 12, day: 29, hour: 12, minute: 30))!
        let ratings: [Rating] = [.again, .good, .good, .good, .good, .good]
        let intervals: [Double] = [0, 0, 1, 3, 8, 21]

        for (i, rating) in ratings.enumerated() {
            now = Date(timeIntervalSince1970: now.timeIntervalSince1970 + intervals[i] * 86400)
            card = try f.next(card: card, now: now, grade: rating).card
        }
        return card
    }

    func testMemoryStateShortTerm() throws {
        let card = try runMemoryStateSequence(enableShortTerm: true)
        XCTAssertEqual(card.stability, 53.62691, accuracy: 1e-4)
        XCTAssertEqual(card.difficulty, 6.3574867, accuracy: 1e-4)
    }

    func testMemoryStateLongTerm() throws {
        let card = try runMemoryStateSequence(enableShortTerm: false)
        XCTAssertEqual(card.stability, 53.335106, accuracy: 1e-4)
        XCTAssertEqual(card.difficulty, 6.3574867, accuracy: 1e-4)
    }

    // MARK: - Forgetting curve uses learnable decay

    func testForgettingCurveUsesLearnableDecay() {
        // Both versions cross R=0.9 at t=s by construction. The shapes differ:
        // v6's smaller |decay| gives a flatter curve — at t > s, v6 retains
        // *more* than v5 (longer tail). At t < s, v6 forgets faster.
        let v5 = FSRS(parameters: .init())
        let v6 = FSRS(parameters: .init(w: w))

        XCTAssertEqual(v5.forgettingCurve(elapsedDays: 1, stability: 1), 0.9, accuracy: 1e-7)
        XCTAssertEqual(v6.forgettingCurve(elapsedDays: 1, stability: 1), 0.9, accuracy: 1e-4)

        // 10 days into a stability-1 card: v6's flatter tail keeps R higher.
        XCTAssertGreaterThan(
            v6.forgettingCurve(elapsedDays: 10, stability: 1),
            v5.forgettingCurve(elapsedDays: 10, stability: 1)
        )

        // Different decays imply different factors.
        XCTAssertNotEqual(v5.factor, v6.factor)
        XCTAssertEqual(v5.decay, -0.5)
        XCTAssertEqual(v6.decay, -0.1542)
    }
}
