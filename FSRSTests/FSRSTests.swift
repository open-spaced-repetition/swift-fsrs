//
//  FSRSTests.swift
//  FSRSTests
//
//  Created by Ben on 11/08/2023.
//

import XCTest

@testable import FSRS

final class FSRSTests: XCTestCase {
    func testExample() throws {
        var f = FSRS()
        let card = Card()

        XCTAssertEqual(card.status, .new)

        f.p.w = [
            1.14, 1.01, 5.44, 14.67, 5.3024, 1.5662, 1.2503, 0.0028,
            1.5489, 0.1763, 0.9953, 2.7473, 0.0179, 0.3105, 0.3976, 0.0, 2.0902
        ]
        
    //        let now = DateComponents(calendar: .current, year: 2022, month: 9, day: 29, hour: 12, minute: 30, second: 0).date!
        let now = Date(timeIntervalSince1970: 1669721400)
        var schedulingCards = f.repeat(card: card, now: now)
        
        print(schedulingCards)
        
        let ratings: [Rating] = [.good, .good, .good, .good, .good, .good, .again, .again, .good, .good, .good, .good, .good, .hard, .easy, .good]
        var ivlHistory: [Double] = []
        var statusHistory: [Status] = []
        
        for rating in ratings {
            if let s = schedulingCards[rating] {
                let card = s.card
                ivlHistory.append(card.scheduledDays)
                
                let revlog = s.reviewLog
                statusHistory.append(revlog.status)
                let now = card.due
                schedulingCards = f.repeat(card: card, now: now)
                
                log(schedulingInfo: schedulingCards)
            }
        }
        
        print(ivlHistory)
        print(statusHistory)
        
        XCTAssertEqual(ivlHistory, [0, 5, 16, 43, 106, 236, 0, 0, 12, 25, 47, 85, 147, 147, 351, 551])
        XCTAssertEqual(statusHistory, [.new, .learning, .review, .review, .review, .review, .review, .relearning, .relearning, .review, .review, .review, .review, .review, .review, .review])

    }

    func log(schedulingInfo: [Rating: SchedulingInfo]) {
        var data = [String: String]()
        for key in schedulingInfo.keys {
            if let info = schedulingInfo[key] {
                data[String(describing: key)] = String(describing: info)
            }
        }
        print("\(data)")
    }
}
