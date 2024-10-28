//
//  FSRSDefaultTests.swift
//  FSRS
//
//  Created by nkq on 10/19/24.
//


import XCTest
@testable import FSRS


class YourTestClass: XCTestCase {

    func testDefaultParams() {
        let expectedW = [
          0.4072, 1.1829, 3.1262, 15.4722, 7.2102, 0.5316, 1.0651, 0.0234, 1.616,
          0.1544, 1.0824, 1.9813, 0.0953, 0.2975, 2.2042, 0.2407, 2.9466, 0.5034,
          0.6567,
        ]
        let defaults = FSRSDefaults()
        XCTAssertEqual(defaults.defaultRequestRetention, 0.9)
        XCTAssertEqual(defaults.defaultMaximumInterval, 36500)
        XCTAssertEqual(defaults.defaultEnableFuzz, false)
        XCTAssertEqual(defaults.defaultW.count, expectedW.count)
        XCTAssertEqual(defaults.defaultW, expectedW)

        let params = defaults.generatorParameters()
        
        XCTAssertEqual(params.requestRetention, defaults.defaultRequestRetention)
        XCTAssertEqual(params.maximumInterval, defaults.defaultMaximumInterval)
        XCTAssertEqual(params.w, expectedW)
        XCTAssertEqual(params.enableFuzz, defaults.defaultEnableFuzz)
    }
    
    func testDefaultCard() {
        let times = [Date(), Date(timeIntervalSince1970: 1696291200)] // Replace with the appropriate timestamp
        for now in times {
            let card = FSRSDefaults().createEmptyCard(now: now)
            XCTAssertEqual(card.due, now)
            XCTAssertEqual(card.stability, 0)
            XCTAssertEqual(card.difficulty, 0)
            XCTAssertEqual(card.elapsedDays, 0)
            XCTAssertEqual(card.scheduledDays, 0)
            XCTAssertEqual(card.reps, 0)
            XCTAssertEqual(card.lapses, 0)
            XCTAssertEqual(card.state.rawValue, 0)
        }
    }
}
