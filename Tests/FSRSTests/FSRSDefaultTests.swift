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
            0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575,
            0.1192, 1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655,
            0.6621,
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
        
        let params2 = defaults.generatorParameters(props: .init(w: [
            0.4, 0.6, 2.4, 5.8, 4.93, 0.94, 0.86, 0.01, 1.49, 0.14, 0.94, 2.18,
            0.05, 0.34, 1.26, 0.29, 2.61,
        ]))
        
        XCTAssertEqual(params2.w, [
            0.4, 0.6, 2.4, 5.8, 6.81, 0.44675014, 1.36, 0.01, 1.49, 0.14, 0.94, 2.18,
            0.05, 0.34, 1.26, 0.29, 2.61, 0.0, 0.0,
        ])
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
