//
//  FSRSRollbackTests.swift
//  FSRS
//
//  Created by nkq on 10/19/24.
//


import XCTest
@testable import FSRS

class FSRSRollbackTests: XCTestCase {
    
    var f: FSRS!

    override func setUp() {
        super.setUp()
        f = FSRS(parameters: .init(
            w: [
                1.14, 1.01, 5.44, 14.67, 5.3024, 1.5662, 1.2503, 0.0028, 1.5489, 0.1763,
                0.9953, 2.7473, 0.0179, 0.3105, 0.3976, 0.0, 2.0902,
            ],
            enableFuzz: false
        ))
    }

    func testFirstRollback() {
        let card = FSRSDefaults().createEmptyCard()
        let now = DateComponents(calendar: .current, year: 2022, month: 12, day: 29, hour: 12, minute: 30).date!
        let schedulingCards = f.repeat(card: card, now: now)
        
        let grades: [Rating] = [Rating.again, Rating.hard, Rating.good, Rating.easy]
        for rating in grades {
            do {
                let rollbackCard = try f.rollback(card: schedulingCards[rating]!.card, log: schedulingCards[rating]!.log)
                XCTAssertEqual(rollbackCard, card)
            } catch {
                
            }
        }
    }

    func testRollback2() {
        var card = FSRSDefaults().createEmptyCard()
        var now = DateComponents(calendar: .current, year: 2022, month: 12, day: 29, hour: 12, minute: 30).date!
        var schedulingCards = f.repeat(card: card, now: now)

        card = schedulingCards[Rating.easy]!.card
        now = card.due
        schedulingCards = f.repeat(card: card, now: now)

        let grades: [Rating] = [Rating.again, Rating.hard, Rating.good, Rating.easy]
        for rating in grades {
            do {
                let rollbackCard = try f.rollback(card: schedulingCards[rating]!.card, log: schedulingCards[rating]!.log)
                XCTAssertEqual(rollbackCard, card)
            } catch {
                
            }
        }
    }
}
