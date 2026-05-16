//
//  FSRSElapsedDaysTests.swift
//
//  Created by nkq on 10/19/24.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSElapsedDaysTests {

    let f: FSRS
    let calendar: Calendar
    let initialCard: Card

    init() {
        f = FSRS(parameters: .init())
        var cal = Calendar.current
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = cal
        let components = DateComponents(year: 2023, month: 10, day: 18, hour: 14, minute: 32, second: 03)
        let createDue = cal.date(from: components)!
        initialCard = FSRSDefaults().createEmptyCard(now: createDue)
    }

    @Test func firstRepeatGood() throws {
        var card = initialCard
        var components = DateComponents(year: 2023, month: 11, day: 05, hour: 08, minute: 27, second: 02)
        let firstDue = calendar.date(from: components)!
        var sc = try f.repeat(card: card, now: firstDue)

        var currentLog = sc[.good]?.log
        #expect(currentLog?.elapsedDays == 0)

        card = sc[.good]?.card ?? card

        components = DateComponents(year: 2023, month: 11, day: 08, hour: 15, minute: 02, second: 09)
        let secondDue = calendar.date(from: components)!

        sc = try f.repeat(card: card, now: secondDue)
        currentLog = sc[.again]?.log

        var expectedElapsedDays: Double = Date.dateDiff(now: secondDue, pre: card.lastReview, unit: .days)
        #expect(currentLog?.elapsedDays == expectedElapsedDays)
        #expect(currentLog?.elapsedDays == 3)

        card = sc[.again]?.card ?? card

        components = DateComponents(year: 2023, month: 11, day: 08, hour: 15, minute: 02, second: 30)
        let thirdDue = calendar.date(from: components)!

        sc = try f.repeat(card: card, now: thirdDue)
        currentLog = sc[.again]?.log

        expectedElapsedDays = Date.dateDiff(now: thirdDue, pre: card.lastReview, unit: .days)
        #expect(currentLog?.elapsedDays == expectedElapsedDays)
        #expect(currentLog?.elapsedDays == 0)

        card = sc[.again]?.card ?? card

        components = DateComponents(year: 2023, month: 11, day: 08, hour: 15, minute: 04, second: 08)
        let fourthDue = calendar.date(from: components)!

        sc = try f.repeat(card: card, now: fourthDue)
        currentLog = sc[.good]?.log

        expectedElapsedDays = Date.dateDiff(now: fourthDue, pre: card.lastReview, unit: .days)
        #expect(currentLog?.elapsedDays == expectedElapsedDays)
        #expect(currentLog?.elapsedDays == 0)
    }
}
