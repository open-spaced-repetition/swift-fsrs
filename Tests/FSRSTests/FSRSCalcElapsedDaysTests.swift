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
    
    func testSSEUseNextState() {
        let f = FSRS(parameters: .init(
            w: [
                0.4911, 4.5674, 24.8836, 77.045, 7.5474, 0.1873, 1.7732, 0.001, 1.1112,
                0.152, 0.5728, 1.8747, 0.1733, 0.2449, 2.2905, 0.0, 2.9898, 0.0883,
                0.9033,
            ]
        ))
        let rids = [
            1698678054.940 /**2023-10-30T15:00:54.940Z */,
            1698678126.399 /**2023-10-30T15:02:06.399Z */,
            1698688771.401 /**2023-10-30T17:59:31.401Z */,
            1698688837.021 /**2023-10-30T18:00:37.021Z */,
            1698688916.440 /**2023-10-30T18:01:56.440Z */,
            1698698192.380 /**2023-10-30T20:36:32.380Z */,
            1699260169.343 /**2023-11-06T08:42:49.343Z */,
            1702718934.003 /**2023-12-16T09:28:54.003Z */,
            1704910583.686 /**2024-01-10T18:16:23.686Z */,
            1713000017.248 /**2024-04-13T09:20:17.248Z */,
        ]
        let ratings = [Rating.good, .good, .again, .good, .good, .good, .manual, .good, .manual, .good]
        var last = Date(timeIntervalSince1970: rids[0])
        var memoryState: FSRSState?
        for (index, rid) in rids.enumerated() {
            let current = Date(timeIntervalSince1970: rid)
            let rating = ratings[index]
            let deltaT = Date.dateDiffInDays(from: last, to: current)
            let nextStates = try! f.nextState(memoryState: memoryState, t: deltaT, g: rating)
            if rating != .manual {
                last = Date(timeIntervalSince1970: rid)
            }
            print("\(rid) \(deltaT) \(nextStates.stability.toFixedNumber(2)) \(nextStates.difficulty.toFixedNumber(2))")
            memoryState = nextStates
        }
        
        XCTAssertEqual(memoryState?.stability.toFixedNumber(2) ?? 0.0, 71.77)
    }

//    func testSSE7177() {
//        let f = FSRS(parameters: .init(
//            w: [
//                0.4911, 4.5674, 24.8836, 77.045, 7.5474, 0.1873, 1.7732, 0.001, 1.1112,
//                0.152, 0.5728, 1.8747, 0.1733, 0.2449, 2.2905, 0.0, 2.9898, 0.0883,
//                0.9033,
//            ]
//        ))
//        let rids = [
//            1698678054.940 /**2023-10-30T15:00:54.940Z */,
//            1698678126.399 /**2023-10-30T15:02:06.399Z */,
//            1698688771.401 /**2023-10-30T17:59:31.401Z */,
//            1698688837.021 /**2023-10-30T18:00:37.021Z */,
//            1698688916.440 /**2023-10-30T18:01:56.440Z */,
//            1698698192.380 /**2023-10-30T20:36:32.380Z */,
//            1699260169.343 /**2023-11-06T08:42:49.343Z */,
//            1702718934.003 /**2023-12-16T09:28:54.003Z */,
//            1704910583.686 /**2024-01-10T18:16:23.686Z */,
//            1713000017.248 /**2024-04-13T09:20:17.248Z */,
//        ]
//        let ratings = [Rating.good, .good, .again, .good, .good, .good, .manual, .good, .manual, .good]
//        
//        let expected = [
//            0: [
//               "elapsed_days": 0,
//               "s": 24.88,
//               "d": 7.09,
//             ],
//            1: [
//               "elapsed_days": 0,
//               "s": 26.95,
//               "d": 7.09,
//             ],
//            2: [
//               "elapsed_days": 0,
//               "s": 24.46,
//               "d": 8.24,
//             ],
//            3: [
//               "elapsed_days": 0,
//               "s": 26.48,
//               "d": 8.24,
//             ],
//            4: [
//               "elapsed_days": 0,
//               "s": 28.69,
//               "d": 8.23,
//             ],
//            5: [
//               "elapsed_days": 0,
//               "s": 31.08,
//               "d": 8.23,
//             ],
//            7: [
//               "elapsed_days": 0,
//               "s": 47.44,
//               "d": 8.23,
//             ],
//            9: [
//               "elapsed_days": 119,
//               "s": 71.77,
//               "d": 8.23,
//             ],
//           ]
//        
//        var card = FSRSDefaults().createEmptyCard(now: Date(timeIntervalSince1970: rids[0]))
//        for (index, rid) in rids.enumerated() {
//            let rating = ratings[index]
//            if rating == .manual {
//                continue
//            }
//            let now = Date(timeIntervalSince1970: rid)
//            let log = try! f.next(card: card, now: now, grade: rating)
//            card = log.card
//            print(index + 1)
//            XCTAssertEqual(card.elapsedDays, expected[index]?["elapsed_days"])
//            XCTAssertEqual(card.stability.toFixedNumber(2), expected[index]?["s"])
//            XCTAssertEqual(card.difficulty.toFixedNumber(2), expected[index]?["d"])
//        }
//        XCTAssertEqual(card.stability, 71.77)
//    }
}
