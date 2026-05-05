//
//  FSRSForgetTests.swift
//  FSRS
//
//  Created by nkq on 10/19/24.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSForgetTests {
    let f: FSRS
    let calendar: Calendar = {
        var res = Calendar.current
        res.timeZone = TimeZone(secondsFromGMT: 0)!
        return res
    }()

    init() {
        f = FSRS(parameters: .init(
            w: [
                1.14, 1.01, 5.44, 14.67, 5.3024, 1.5662, 1.2503, 0.0028, 1.5489, 0.1763,
                0.9953, 2.7473, 0.0179, 0.3105, 0.3976, 0.0, 2.0902,
            ],
            enableFuzz: false
        ))
    }

    @Test func forget() {
        let card = FSRSDefaults().createEmptyCard()

        let now = calendar.date(from: DateComponents(year: 2022, month: 12, day: 29, hour: 12, minute: 30))!
        let forgetNow = calendar.date(from: DateComponents(year: 2023, month: 12, day: 30, hour: 12, minute: 30))!
        let schedulingCards = f.repeat(card: card, now: now)

        let grades: [Rating] = [.again, .hard, .good, .easy]

        for grade in grades {
            let forgetCard = f.forget(card: schedulingCards[grade]?.card ?? Card(), now: forgetNow, resetCount: true)
            #expect(forgetCard.card == Card(
                due: forgetNow,
                elapsedDays: 0,
                reps: 0,
                lastReview: schedulingCards[grade]?.card.lastReview
            ))
            #expect(forgetCard.log.rating == .manual)
            let err = #expect(throws: FSRSError.self) {
                _ = try f.rollback(card: forgetCard.card, log: forgetCard.log)
            }
            #expect(err?.errorReason == .invalidRating)
        }

        for grade in grades {
            let forgetCard = f.forget(card: schedulingCards[grade]?.card ?? Card(), now: forgetNow)
            #expect(forgetCard.card == Card(
                due: forgetNow,
                elapsedDays: schedulingCards[grade]?.card.elapsedDays ?? 0,
                reps: schedulingCards[grade]?.card.reps ?? 0,
                lastReview: schedulingCards[grade]?.card.lastReview
            ))
            #expect(forgetCard.log.rating == .manual)
            let err = #expect(throws: FSRSError.self) {
                _ = try f.rollback(card: forgetCard.card, log: forgetCard.log)
            }
            #expect(err?.errorReason == .invalidRating)
        }
    }

    @Test func newCardForgetResetTrue() {
        let card = FSRSDefaults().createEmptyCard()
        let forgetNow = calendar.date(from: DateComponents(year: 2023, month: 12, day: 30, hour: 12, minute: 30))!
        let forgetCard = f.forget(card: card, now: forgetNow, resetCount: true)
        #expect(forgetCard.card == Card(due: forgetNow, elapsedDays: 0, reps: 0))
    }

    @Test func newCardForget() {
        let card = FSRSDefaults().createEmptyCard()
        let forgetNow = calendar.date(from: DateComponents(year: 2023, month: 12, day: 30, hour: 12, minute: 30))!
        let forgetCard = f.forget(card: card, now: forgetNow, resetCount: true)
        #expect(forgetCard.card == Card(due: forgetNow))
    }
}
