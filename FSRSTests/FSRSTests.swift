//
//  FSRSTests.swift
//  FSRSTests
//
//  Created by Ben on 11/08/2023.
//

import XCTest

@testable import FSRS

final class FSRSTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let f = FSRS()
        let card = Card()

        XCTAssertEqual(card.status, .New)
        
        f.p.w = [
            1.14, 1.01, 5.44, 14.67, 5.3024, 1.5662, 1.2503, 0.0028,
            1.5489, 0.1763, 0.9953, 2.7473, 0.0179, 0.3105, 0.3976, 0.0, 2.0902
        ]
        
    //        let now = DateComponents(calendar: .current, year: 2022, month: 9, day: 29, hour: 12, minute: 30, second: 0).date!
        let now = Date(timeIntervalSince1970: 1669721400)
        var schedulingCards = f.repeat(card: card, now: now)
        
        print(schedulingCards)
        
        let ratings: [Rating] = [.Good, .Good, .Good, .Good, .Good, .Good, .Again, .Again, .Good, .Good, .Good, .Good, .Good, .Hard, .Easy, .Good]
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
        XCTAssertEqual(statusHistory, [.New, .Learning, .Review, .Review, .Review, .Review, .Review, .Relearning, .Relearning, .Review, .Review, .Review, .Review, .Review, .Review, .Review])
    
    }

    func log(schedulingInfo: [Rating: SchedulingInfo]) {
        
        var data = [String: [String: [String: Encodable]]]()
        for key in schedulingInfo.keys {
            if let info = schedulingInfo[key] {
                data[key.description] = info.data()
            }
        }
        print("\(data)")
    }
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
