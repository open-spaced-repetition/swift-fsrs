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

    func testStateNewExist() throws {
        let card = FSRSDefaults().createEmptyCard(now: now)
        let basicScheduler = BasicScheduler(card: card, reviewTime: now, algorithm: algorithm)
        let preview = try basicScheduler.preview
        let again = try basicScheduler.review(.again)
        let hard = try basicScheduler.review(.hard)
        let good = try basicScheduler.review(.good)
        let easy = try basicScheduler.review(.easy)

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
            let expectedCard = try basicScheduler.review(item.value.log.rating)
            XCTAssertEqual(item.value, expectedCard)
        }
    }

    func testStateLearningExist() throws {
        let cardByNew = FSRSDefaults().createEmptyCard(now: now)
        let card = try BasicScheduler(card: cardByNew, reviewTime: now, algorithm: algorithm).review(.again).card
        let basicScheduler = BasicScheduler(card: card, reviewTime: now, algorithm: algorithm)

        let preview = try basicScheduler.preview
        let again = try basicScheduler.review(.again)
        let hard = try basicScheduler.review(.hard)
        let good = try basicScheduler.review(.good)
        let easy = try basicScheduler.review(.easy)

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
            let expectedCard = try basicScheduler.review(item.value.log.rating)
            XCTAssertEqual(item.value, expectedCard)
        }
    }

    func testStateReviewExist() throws {
        let cardByNew = FSRSDefaults().createEmptyCard(now: now)
        let card = try BasicScheduler(card: cardByNew, reviewTime: now, algorithm: algorithm).review(.easy).card
        let basicScheduler = BasicScheduler(card: card, reviewTime: now, algorithm: algorithm)

        let preview = try basicScheduler.preview
        let again = try basicScheduler.review(.again)
        let hard = try basicScheduler.review(.hard)
        let good = try basicScheduler.review(.good)
        let easy = try basicScheduler.review(.easy)

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
            let expectedCard = try basicScheduler.review(item.value.log.rating)
            XCTAssertEqual(item.value, expectedCard)
        }
    }
}
