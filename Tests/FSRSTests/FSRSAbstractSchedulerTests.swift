//
//  FSRSAbstractSchedulerTests.swift
//  FSRS
//
//  Created by nkq on 10/20/24.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSAbstractSchedulerTests {
    @Test func symbolIterator() throws {
        let now = Date()
        let card = FSRSDefaults().createEmptyCard(now: now)
        let f = FSRS(parameters: .init())
        let preview = f.repeat(card: card, now: now)
        let again = try f.next(card: card, now: now, grade: .again)
        let hard = try f.next(card: card, now: now, grade: .hard)
        let good = try f.next(card: card, now: now, grade: .good)
        let easy = try f.next(card: card, now: now, grade: .easy)

        let expectPreview: [Rating: Card] = [
            .again: again.card,
            .hard: hard.card,
            .good: good.card,
            .easy: easy.card,
        ]

        #expect(preview.recordLog[.again]?.card == expectPreview[.again])
        #expect(preview.recordLog[.good]?.card == expectPreview[.good])
        #expect(preview.recordLog[.easy]?.card == expectPreview[.easy])
        #expect(preview.recordLog[.hard]?.card == expectPreview[.hard])

        for item in preview.recordLog {
            let expectedCard = expectPreview[item.value.log.rating]
            #expect(item.value.card == expectedCard)
        }
    }
}
