//
//  BasicSchedulerTests.swift
//  FSRS
//
//  Created by nkq on 10/20/24.
//


import XCTest
@testable import FSRS

class FSRSBasicSchedulerTests: XCTestCase {
    var params: FSRSParameters!
    var algorithm: FSRS!
    var now: Date!

    override func setUp() {
        super.setUp()
        params = FSRSDefaults().generatorParameters()
        algorithm = FSRS(parameters: params)
        now = Date()
    }

    func testStateNewExist() {
        let card = FSRSDefaults().createEmptyCard(now: now)
        let basicScheduler = BasicScheduler(card: card, reviewTime: now, algorithm: algorithm)
        let preview = basicScheduler.preview
        let again = basicScheduler.review(.again)
        let hard = basicScheduler.review(.hard)
        let good = basicScheduler.review(.good)
        let easy = basicScheduler.review(.easy)

        let expectedPreview: [Rating: Card] = [
            .again: again.card,
            .hard: hard.card,
            .good: good.card,
            .easy: easy.card
        ]

        // Check that preview matches expected structure
        XCTAssertEqual(preview.recordLog[.again]?.card, expectedPreview[.again])
        XCTAssertEqual(preview.recordLog[.good]?.card, expectedPreview[.good])
        XCTAssertEqual(preview.recordLog[.easy]?.card, expectedPreview[.easy])
        XCTAssertEqual(preview.recordLog[.hard]?.card, expectedPreview[.hard])

        for item in preview.recordLog {
            let expectedCard = basicScheduler.review(item.value.log.rating)
            XCTAssertEqual(item.value, expectedCard)
        }
    }

    func testStateLearningExist() {
        let cardByNew = FSRSDefaults().createEmptyCard(now: now)
        let card = BasicScheduler(card: cardByNew, reviewTime: now, algorithm: algorithm).review(.again).card
        let basicScheduler = BasicScheduler(card: card, reviewTime: now, algorithm: algorithm)

        let preview = basicScheduler.preview
        let again = basicScheduler.review(.again)
        let hard = basicScheduler.review(.hard)
        let good = basicScheduler.review(.good)
        let easy = basicScheduler.review(.easy)

        let expectedPreview: [Rating: Card] = [
            .again: again.card,
            .hard: hard.card,
            .good: good.card,
            .easy: easy.card
        ]

        // Check that preview matches expected structure
        XCTAssertEqual(preview.recordLog[.again]?.card, expectedPreview[.again])
        XCTAssertEqual(preview.recordLog[.good]?.card, expectedPreview[.good])
        XCTAssertEqual(preview.recordLog[.easy]?.card, expectedPreview[.easy])
        XCTAssertEqual(preview.recordLog[.hard]?.card, expectedPreview[.hard])

        for item in preview.recordLog {
            let expectedCard = basicScheduler.review(item.value.log.rating)
            XCTAssertEqual(item.value, expectedCard)
        }
    }

    func testStateReviewExist() {
        let cardByNew = FSRSDefaults().createEmptyCard(now: now)
        let card = BasicScheduler(card: cardByNew, reviewTime: now, algorithm: algorithm).review(.easy).card
        let basicScheduler = BasicScheduler(card: card, reviewTime: now, algorithm: algorithm)

        let preview = basicScheduler.preview
        let again = basicScheduler.review(.again)
        let hard = basicScheduler.review(.hard)
        let good = basicScheduler.review(.good)
        let easy = basicScheduler.review(.easy)

        let expectedPreview: [Rating: Card] = [
            .again: again.card,
            .hard: hard.card,
            .good: good.card,
            .easy: easy.card
        ]

        // Check that preview matches expected structure
        XCTAssertEqual(preview.recordLog[.again]?.card, expectedPreview[.again])
        XCTAssertEqual(preview.recordLog[.good]?.card, expectedPreview[.good])
        XCTAssertEqual(preview.recordLog[.easy]?.card, expectedPreview[.easy])
        XCTAssertEqual(preview.recordLog[.hard]?.card, expectedPreview[.hard])

        for item in preview.recordLog {
            let expectedCard = basicScheduler.review(item.value.log.rating)
            XCTAssertEqual(item.value, expectedCard)
        }
    }
}
