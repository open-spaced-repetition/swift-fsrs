//
//  FSRSV5Tests.swift
//  FSRS
//
//  Created by nkq on 10/19/24.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSV5Tests {
    let f: FSRS
    let calendar: Calendar = {
        var res = Calendar.current
        res.timeZone = TimeZone(secondsFromGMT: 0)!
        return res
    }()
    static let w: [Double] = [
        0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575,
        0.1192, 1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655,
        0.6621,
    ]

    init() {
        f = FSRS(parameters: .init(w: Self.w))
    }

    @Test func ivlHistory() throws {
        var card = FSRSDefaults().createEmptyCard()
        var now = calendar.date(from: DateComponents(year: 2022, month: 12, day: 29, hour: 12, minute: 30))!
        var schedulingCards = f.repeat(card: card, now: now)

        let ratings: [Rating] = [
            .good, .good, .good, .good, .good, .good,
            .again, .again, .good, .good, .good, .good, .good,
        ]

        var ivlHistory: [Int] = []

        for rating in ratings {
            var grades = Rating.allCases
            grades.removeAll(where: { $0 == .manual })
            for check in grades {
                let rollbackCard = try f.rollback(card: schedulingCards[check]!.card, log: schedulingCards[check]!.log)
                #expect(rollbackCard == card)
                let elapsedDays = card.lastReview != nil ? Date.dateDiff(now: now, pre: card.lastReview, unit: .days) : 0
                #expect(schedulingCards[check]!.log.elapsedDays == elapsedDays)
                let tempF = FSRS(parameters: .init(w: Self.w))
                let next = try tempF.next(card: card, now: now, grade: check)
                #expect(schedulingCards[check] == next)
            }

            card = schedulingCards[rating]!.card
            let ivl = card.scheduledDays
            ivlHistory.append(Int(ivl))
            now = card.due
            schedulingCards = f.repeat(card: card, now: now)
        }

        #expect(ivlHistory == [0, 4, 14, 44, 125, 328, 0, 0, 7, 16, 34, 71, 142])
    }

    @Test func memoryState() {
        var card = FSRSDefaults().createEmptyCard()
        var now = calendar.date(from: DateComponents(year: 2022, month: 12, day: 29, hour: 12, minute: 30))!
        var schedulingCards = f.repeat(card: card, now: now)

        let ratings: [Rating] = [.again, .good, .good, .good, .good, .good]
        let intervals: [Int] = [0, 0, 1, 3, 8, 21]

        for (index, rating) in ratings.enumerated() {
            card = schedulingCards[rating]!.card
            now.addTimeInterval(Double(intervals[index]) * 24 * 60 * 60)
            schedulingCards = f.repeat(card: card, now: now)
        }

        let stability = schedulingCards[.good]!.card.stability
        let difficulty = schedulingCards[.good]!.card.difficulty
        expectClose(stability, 48.4848, 0.0001)
        expectClose(difficulty, 7.0866, 0.0001)
    }

    @Test func firstRepeat() {
        let card = FSRSDefaults().createEmptyCard()
        let now = calendar.date(from: DateComponents(year: 2022, month: 12, day: 29, hour: 12, minute: 30))!
        let schedulingCards = f.repeat(card: card, now: now)

        var stability: [Double] = []
        var difficulty: [Double] = []
        var elapsedDays: [Int] = []
        var scheduledDays: [Int] = []
        var reps: [Int] = []
        var lapses: [Int] = []
        var states: [CardState] = []

        for item in schedulingCards.recordLog {
            let firstCard = item.value.card
            stability.append(firstCard.stability.toFixedNumber(5))
            difficulty.append(firstCard.difficulty.toFixedNumber(8))
            reps.append(firstCard.reps)
            lapses.append(firstCard.lapses)
            elapsedDays.append(Int(firstCard.elapsedDays))
            scheduledDays.append(Int(firstCard.scheduledDays))
            states.append(firstCard.state)
        }

        #expect(Set(stability) == Set([0.40255, 1.18385, 3.173, 15.69105]))
        #expect(Set(difficulty) == Set([7.1949, 6.48830527, 5.28243442, 3.22450159]))
        #expect(Set(reps) == Set([1, 1, 1, 1]))
        #expect(Set(lapses) == Set([0, 0, 0, 0]))
        #expect(Set(elapsedDays) == Set([0, 0, 0, 0]))
        #expect(Set(scheduledDays) == Set([0, 0, 0, 16]))
        #expect(Set(states) == Set([.learning, .learning, .learning, .review]))
    }
}

@Suite struct FSRSRetrievabilityTests {
    let fsrs: FSRS
    let dateFormatter: DateFormatter

    init() {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter = df
        fsrs = FSRS(parameters: .init())
    }

    @Test func returnZeroForNewCards() {
        let card = FSRSDefaults().createEmptyCard()
        let now = Date()
        #expect(fsrs.getRetrievability(card: card, now: now).string == "0.00%")
    }

    @Test func retrievabilityPercentageForReviewCards() {
        let card = FSRSDefaults().createEmptyCard(now: dateFormatter.date(from: "2023-12-01 04:00:00")!)
        let sc = fsrs.repeat(card: card, now: dateFormatter.date(from: "2023-12-01 04:05:00")!)
        let expectedResults = ["100.00%", "100.00%", "100.00%", "89.83%"]
        let expectedNumbers = [1.0, 1.0, 1.0, 0.89832125]

        for grade in Rating.allCases where grade != .manual {
            #expect(fsrs.getRetrievability(card: sc[grade]!.card, now: sc[grade]!.card.due).string == expectedResults[grade.rawValue - 1])
            #expect(fsrs.getRetrievability(card: sc[grade]!.card, now: sc[grade]!.card.due).number == expectedNumbers[grade.rawValue - 1])
        }
    }

    @Test func loopAgain() throws {
        var card = FSRSDefaults().createEmptyCard()
        var now = Date()

        for _ in 0..<5 {
            card = try fsrs.next(card: card, now: now, grade: .again).card
            now = card.due

            let retrievability = fsrs.getRetrievability(card: card, now: now).number
            #expect(!retrievability.isNaN)
        }
    }
}

@Suite struct FSRSNextMethodTests {
    let fsrs: FSRS

    init() {
        fsrs = FSRS(parameters: .init())
    }

    @Test func invalidGrade() {
        let card = FSRSDefaults().createEmptyCard()
        let now = Date()
        let invalidGrade = Rating.manual
        let err = #expect(throws: FSRSError.self) {
            _ = try fsrs.next(card: card, now: now, grade: invalidGrade)
        }
        #expect(err?.errorReason == .invalidRating)
    }
}
