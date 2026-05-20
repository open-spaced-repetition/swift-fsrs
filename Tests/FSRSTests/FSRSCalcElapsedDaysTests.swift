//
//  FSRSCalcElapsedDaysTests.swift
//  FSRS
//
//  Created by nkq on 4/5/25.
//

import Foundation
import Testing
@testable import FSRS

/**
  * @see https://forums.ankiweb.net/t/feature-request-estimated-total-knowledge-over-time/53036/58?u=l.m.sherlock
  * @see https://ankiweb.net/shared/info/1613056169
  */

@Suite struct FSRSCalcElapsedDaysTests {
    let f: FSRS
    let rids = [1704468957.0, 1704469645.0, 1704599572.0, 1705509507.0]

    init() {
        f = FSRS(parameters: .init(
            w: [
                1.1596, 1.7974, 13.1205, 49.3729, 7.2303, 0.5081, 1.5371, 0.001, 1.5052,
                0.1261, 0.9735, 1.8924, 0.1486, 0.2407, 2.1937, 0.1518, 3.0699, 0.4636,
                0.6048,
            ]
        ))
    }

    @Test func elapsedDays() throws {
        let expected = [13.1205, 17.3668145, 21.28550751, 39.63452215]
        var card = FSRSDefaults().createEmptyCard(now: Date(timeIntervalSince1970: rids[0]))
        let grade: [Rating] = [.good, .good, .good, .good]
        for (index, rid) in rids.enumerated() {
            let now = Date(timeIntervalSince1970: rid)
            let log = try f.next(card: card, now: now, grade: grade[index])
            card = log.card
            #expect(card.stability == expected[index])
        }
    }

    @Test func sseUseNextState() throws {
        let f = FSRS(parameters: .init(
            w: [
                0.4911, 4.5674, 24.8836, 77.045, 7.5474, 0.1873, 1.7732, 0.001, 1.1112,
                0.152, 0.5728, 1.8747, 0.1733, 0.2449, 2.2905, 0.0, 2.9898, 0.0883,
                0.9033,
            ]
        ))
        let rids = [
            1698678054.940, 1698678126.399, 1698688771.401, 1698688837.021,
            1698688916.440, 1698698192.380, 1699260169.343, 1702718934.003,
            1704910583.686, 1713000017.248,
        ]
        let ratings: [Rating] = [.good, .good, .again, .good, .good, .good, .manual, .good, .manual, .good]
        var last = Date(timeIntervalSince1970: rids[0])
        var memoryState: FSRSState?
        for (index, rid) in rids.enumerated() {
            let current = Date(timeIntervalSince1970: rid)
            let rating = ratings[index]
            let deltaT = Date.dateDiffInDays(from: last, to: current)
            let nextStates = try f.nextState(memoryState: memoryState, t: deltaT, g: rating)
            if rating != .manual {
                last = Date(timeIntervalSince1970: rid)
            }
            memoryState = nextStates
        }

        #expect(memoryState?.stability.toFixedNumber(2) ?? 0.0 == 71.77)
    }

    @Test func dateDiffMinutes() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        // Two-minute gap → 2.
        let twoMinAgo = now.addingTimeInterval(-120)
        #expect(Date.dateDiff(now: now, pre: twoMinAgo, unit: .minutes) == 2)
        // Half-minute gap floors to 0.
        let halfMinAgo = now.addingTimeInterval(-30)
        #expect(Date.dateDiff(now: now, pre: halfMinAgo, unit: .minutes) == 0)
        // One-hour gap → 60 minutes.
        let hourAgo = now.addingTimeInterval(-3600)
        #expect(Date.dateDiff(now: now, pre: hourAgo, unit: .minutes) == 60)
        // Nil pre → 0 (matches the guard at the top of dateDiff).
        #expect(Date.dateDiff(now: now, pre: nil, unit: .minutes) == 0)
    }
}
