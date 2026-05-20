//
//  FSRSFuzzSameSeedTests.swift
//
//  Created by nkq on 10/20/24.
//
//  With identical inputs, the seeded fuzz must produce identical due
//  timestamps. The original XCTest version dispatched 100 invocations onto
//  the main queue with `asyncAfter(...+0.05)`, but the synchronous test
//  method returned before any of those closures ran — so the assertion was
//  never observed. Fuzz with a fixed seed is fully deterministic and
//  doesn't need async dispatch; just run the 100 invocations inline.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FuzzSameSeedTests {
    let calendar: Calendar = {
        var res = Calendar.current
        res.timeZone = TimeZone(secondsFromGMT: 0)!
        return res
    }()

    @Test func fuzzSameShortTerm() throws {
        let mockNow = calendar.date(from: DateComponents(year: 2024, month: 8, day: 15))!
        let mockTomorrow = calendar.date(from: DateComponents(year: 2024, month: 8, day: 16))!
        let initialCard = FSRSDefaults().createEmptyCard()
        let card = try FSRS(parameters: .init()).next(card: initialCard, now: mockNow, grade: .good).card

        let dues: [TimeInterval] = try (0..<100).map { _ in
            let scheduler = FSRS(parameters: .init(enableFuzz: true))
            return try scheduler.next(card: card, now: mockTomorrow, grade: .good)
                .card.due.timeIntervalSince1970
        }

        #expect(Set(dues).count == 1)
    }

    @Test func fuzzSameLongTerm() throws {
        let mockNow = calendar.date(from: DateComponents(year: 2024, month: 8, day: 15))!
        let mockTomorrow = calendar.date(from: DateComponents(year: 2024, month: 8, day: 18))!
        let initialCard = FSRSDefaults().createEmptyCard()
        let card = try FSRS(parameters: .init(enableShortTerm: false))
            .next(card: initialCard, now: mockNow, grade: .good).card

        let dues: [TimeInterval] = try (0..<100).map { _ in
            let scheduler = FSRS(parameters: .init(enableFuzz: true, enableShortTerm: false))
            return try scheduler.next(card: card, now: mockTomorrow, grade: .good)
                .card.due.timeIntervalSince1970
        }

        #expect(Set(dues).count == 1)
    }
}
