//
//  FSRSDayBoundaryTests.swift
//  FSRS
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSDayBoundaryTests {
    private static func date(_ s: String) -> Date {
        ISO8601DateFormatter().date(from: s)!
    }

    @Test func defaultBehaviorUnchangedAcrossUTCMidnight() throws {
        let t1 = Self.date("2026-10-16T23:55:00Z"), t2 = Self.date("2026-10-17T00:05:00Z")
        let card = try FSRS(parameters: .init()).next(card: Card(state: .review, lastReview: t1), now: t2, grade: .good).card
        #expect(card.elapsedDays == 1)
    }

    @Test func europeIstanbulStudyDayBoundary() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        let t = { (h: Int, m: Int) in cal.date(from: DateComponents(year: 2026, month: 10, day: 17, hour: h, minute: m))! }
        #expect(Date.dateDiffInDays(from: t(2, 55), to: t(3, 5), calendar: cal, dayStartHour: 4) == 0)
        #expect(Date.dateDiffInDays(from: t(3, 55), to: t(4, 5), calendar: cal, dayStartHour: 4) == 1)
    }

    @Test func newYorkCrossingMidnightInvariance() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        let fNY = FSRS(parameters: .init(), calendar: cal, dayStartHour: 4)

        let cA = try fNY.next(card: Card(stability: 2, difficulty: 5, state: .review, lastReview: Self.date("2026-10-16T23:55:00Z")), now: Self.date("2026-10-17T00:05:00Z"), grade: .good).card
        let cB = try fNY.next(card: Card(stability: 2, difficulty: 5, state: .review, lastReview: Self.date("2026-10-16T22:45:00Z")), now: Self.date("2026-10-16T22:55:00Z"), grade: .good).card

        #expect(cA.elapsedDays == 0 && cB.elapsedDays == 0)
        expectClose(cA.stability, cB.stability)
    }

    @Test func daylightSavingTimeBoundaries() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!
        #expect(Date.dateDiffInDays(from: Self.date("2026-03-08T17:00:00Z"), to: Self.date("2026-03-09T17:00:00Z"), calendar: cal, dayStartHour: 4) == 1)
        #expect(Date.dateDiffInDays(from: Self.date("2026-11-01T17:00:00Z"), to: Self.date("2026-11-02T17:00:00Z"), calendar: cal, dayStartHour: 4) == 1)
    }
}
