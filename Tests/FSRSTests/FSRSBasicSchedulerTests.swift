//
//  FSRSBasicSchedulerTests.swift
//  FSRS
//
//  Created by nkq on 10/20/24.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSBasicSchedulerTests {

    enum InitialState: String, CaseIterable, Sendable {
        case new
        case learning
        case review
    }

    /// Build the starting card for each scenario. `new` is a fresh card;
    /// `learning` is a fresh card after one `.again` review; `review` is a
    /// fresh card after one `.easy` review.
    private static func makeCard(_ state: InitialState, now: Date, algorithm: FSRS) -> Card {
        let empty = FSRSDefaults().createEmptyCard(now: now)
        switch state {
        case .new:
            return empty
        case .learning:
            return BasicScheduler(card: empty, reviewTime: now, algorithm: algorithm).review(.again).card
        case .review:
            return BasicScheduler(card: empty, reviewTime: now, algorithm: algorithm).review(.easy).card
        }
    }

    @Test(arguments: InitialState.allCases)
    func previewMatchesPerGradeReview(initialState: InitialState) {
        let params = FSRSDefaults().generatorParameters()
        let algorithm = FSRS(parameters: params)
        let now = Date()
        let card = Self.makeCard(initialState, now: now, algorithm: algorithm)
        let basicScheduler = BasicScheduler(card: card, reviewTime: now, algorithm: algorithm)

        let preview = basicScheduler.preview
        let again = basicScheduler.review(.again)
        let hard = basicScheduler.review(.hard)
        let good = basicScheduler.review(.good)
        let easy = basicScheduler.review(.easy)

        let expected: [Rating: Card] = [
            .again: again.card,
            .hard: hard.card,
            .good: good.card,
            .easy: easy.card,
        ]

        #expect(preview.recordLog[.again]?.card == expected[.again])
        #expect(preview.recordLog[.good]?.card == expected[.good])
        #expect(preview.recordLog[.easy]?.card == expected[.easy])
        #expect(preview.recordLog[.hard]?.card == expected[.hard])

        for item in preview.recordLog {
            let expectedItem = basicScheduler.review(item.value.log.rating)
            #expect(item.value == expectedItem)
        }
    }
}
