//
//  FSRSElapsedDaysTests.swift
//
//  Created by nkq on 10/19/24.
//

import XCTest
@testable import FSRS

class FSRSElapsedDaysTests: XCTestCase {
    
    var f: FSRS!
    var currentLog: ReviewLog?
    var card: Card!
    var calendar = Calendar.current

    override func setUp() {
        super.setUp()
        f = FSRS(parameters: .init())
        calendar.timeZone = .init(secondsFromGMT: 0)!
        let components = DateComponents(year: 2023, month: 10, day: 18, hour: 14, minute: 32, second: 03)
        let createDue = calendar.date(from: components)! // UTC 2023-10-18 14:32:03.370
        card = FSRSDefaults().createEmptyCard(now: createDue)
    }

    func testFirstRepeatGood() {
        var components = DateComponents(year: 2023, month: 11, day: 05, hour: 08, minute: 27, second: 02)
        let firstDue = calendar.date(from: components)! // UTC 2023-11-05 08:27:02.605
        var sc = f.repeat(card: card, now: firstDue)
        
        currentLog = sc[.good]?.log
        XCTAssertEqual(currentLog?.elapsedDays, 0)
        
        card = sc[.good]?.card ?? card

        components = DateComponents(year: 2023, month: 11, day: 08, hour: 15, minute: 02, second: 09)
        let secondDue = calendar.date(from: components)! // UTC 2023-11-08 15:02:09.791
        XCTAssertNotNil(card)
        
        sc = f.repeat(card: card, now: secondDue)
        currentLog = sc[.again]?.log
        
        var expectedElapsedDays: Double = Date.dateDiff(now: secondDue, pre: card.lastReview, unit: .days)
        XCTAssertEqual(currentLog?.elapsedDays, expectedElapsedDays)
        XCTAssertEqual(currentLog?.elapsedDays, 3)
        
        card = sc[.again]?.card ?? card

        components = DateComponents(year: 2023, month: 11, day: 08, hour: 15, minute: 02, second: 30)
        let thirdDue = calendar.date(from: components)! // UTC 2023-11-08 15:02:30.799
        XCTAssertNotNil(card)

        sc = f.repeat(card: card, now: thirdDue)
        currentLog = sc[.again]?.log
        
        expectedElapsedDays = Date.dateDiff(now: thirdDue, pre: card.lastReview, unit: .days)
        XCTAssertEqual(currentLog?.elapsedDays, expectedElapsedDays)
        XCTAssertEqual(currentLog?.elapsedDays, 0)
        
        card = sc[.again]?.card ?? card

        components = DateComponents(year: 2023, month: 11, day: 08, hour: 15, minute: 04, second: 08)
        let fourthDue = calendar.date(from: components)! // UTC 2023-11-08 15:04:08.739
        XCTAssertNotNil(card)

        sc = f.repeat(card: card, now: fourthDue)
        currentLog = sc[.good]?.log
        
        expectedElapsedDays = Date.dateDiff(now: fourthDue, pre: card.lastReview, unit: .days)
        XCTAssertEqual(currentLog?.elapsedDays, expectedElapsedDays)
        XCTAssertEqual(currentLog?.elapsedDays, 0)
        
        card = sc[.good]?.card ?? card
    }
}
