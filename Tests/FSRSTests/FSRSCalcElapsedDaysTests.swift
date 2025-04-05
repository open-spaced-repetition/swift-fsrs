//
//  FSRSCalcElapsedDaysTests.swift
//  FSRS
//
//  Created by nkq on 4/5/25.
//

import XCTest
@testable import FSRS

/**
  * @see https://forums.ankiweb.net/t/feature-request-estimated-total-knowledge-over-time/53036/58?u=l.m.sherlock
  * @see https://ankiweb.net/shared/info/1613056169
  */

class FSRSCalcElapsedDaysTests: XCTestCase {
    var f: FSRS!
    let rids = [1704468957.0, 1704469645.0, 1704599572.0, 1705509507.0]
    

    override func setUp() {
        super.setUp()
        f = FSRS(parameters: .init(
            w: [
                1.1596, 1.7974, 13.1205, 49.3729, 7.2303, 0.5081, 1.5371, 0.001, 1.5052,
                0.1261, 0.9735, 1.8924, 0.1486, 0.2407, 2.1937, 0.1518, 3.0699, 0.4636,
                0.6048,
            ]
        ))
    }

    func testElapsedDays() {
        let expected = [13.1205, 17.3668145, 21.28550751, 39.63452215]
        var card = FSRSDefaults().createEmptyCard(now: Date(timeIntervalSince1970: rids[0]))
        let grade = [Rating.good, .good, .good, .good]
        for (index, rid) in rids.enumerated() {
            do {
                let now = Date(timeIntervalSince1970: rid)
                let log = try f.next(card: card, now: now, grade: grade[index])
                card = log.card
                XCTAssertEqual(card.stability, expected[index])
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
