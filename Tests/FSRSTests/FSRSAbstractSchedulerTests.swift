//
//  BasicSchedulerTests.swift
//  FSRS
//
//  Created by nkq on 10/20/24.
//


import XCTest
@testable import FSRS

class BasicSchedulerTests: XCTestCase {
    func testSymbolIterator() {
        let now = Date()
        let card = FSRSDefaults().createEmptyCard(now: now)
        let f = FSRS(parameters: .init())
        let preview = f.repeat(card: card, now: now)
        let again = try! f.next(card: card, now: now, grade: .again)
        let hard = try! f.next(card: card, now: now, grade: .hard)
        let good = try! f.next(card: card, now: now, grade: .good)
        let easy = try! f.next(card: card, now: now, grade: .easy)

        let expectPreview: [Rating: Card] = [
            .again: again.card,
            .hard: hard.card,
            .good: good.card,
            .easy: easy.card,
        ]
        
        // Check that preview matches expected structure
        XCTAssertEqual(preview.recordLog[.again]?.card, expectPreview[.again])
        XCTAssertEqual(preview.recordLog[.good]?.card, expectPreview[.good])
        XCTAssertEqual(preview.recordLog[.easy]?.card, expectPreview[.easy])
        XCTAssertEqual(preview.recordLog[.hard]?.card, expectPreview[.hard])

        
        
        // Iterate over preview and check values
        for item in preview.recordLog {
            let expectedCard = expectPreview[item.value.log.rating]
            XCTAssertEqual(item.value.card, expectedCard)
        }
    }
}
