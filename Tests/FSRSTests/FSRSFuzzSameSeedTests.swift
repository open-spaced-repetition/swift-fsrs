//
//  FuzzSameSeedTests.swift
//  FSRS
//
//  Created by nkq on 10/20/24.
//


import XCTest
@testable import FSRS

class FuzzSameSeedTests: XCTestCase {
    var mockNow: Date { calendar.date(from: DateComponents(year: 2024, month: 8, day: 15))! }
    var calendar: Calendar = {
        var res = Calendar.current
        res.timeZone = .init(secondsFromGMT: 0)!
        return res
    }()

    func testFuzzSameShortTerm() {
        do {
            let initialCard = FSRSDefaults().createEmptyCard()
            let fsrsInstance = FSRS(parameters: .init())
            let card: Card = try fsrsInstance.next(card: initialCard, now: mockNow, grade: .good).card
            let mockTomorrow = calendar.date(from: DateComponents(year: 2024, month: 8, day: 16))!

            var timestamps: [TimeInterval] = []

            for _ in 0..<100 {
                if #available(macOS 14.0, *) {
                    DispatchQueue.main.asyncAfterUnsafe(deadline: .now() + 0.05) {
                        do {
                            let scheduler = FSRS(parameters: .init(enableFuzz: true))
                            let nextCard = try scheduler.next(card: card, now: mockTomorrow, grade: .good).card
                            timestamps.append(nextCard.due.timeIntervalSince1970)
                            
                            if timestamps.count == 100 {
                                let firstValue = timestamps[0]
                                XCTAssertTrue(timestamps.allSatisfy { $0 == firstValue })
                            }
                        } catch {
                            
                        }
                    }
                } else {
                    // Fallback on earlier versions
                }
            }
        } catch {
            
        }
    }

    func testFuzzSameLongTerm() {
        do {
            let initialCard = FSRSDefaults().createEmptyCard()
            let fsrsInstance = FSRS(parameters: .init(enableShortTerm: false))
            let card = try fsrsInstance.next(card: initialCard, now: mockNow, grade: .good).card
            let mockTomorrow = calendar.date(from: DateComponents(year: 2024, month: 8, day: 18))!

            var timestamps: [TimeInterval] = []

            for _ in 0..<100 {
                if #available(macOS 14.0, *) {
                    DispatchQueue.main.asyncAfterUnsafe(deadline: .now() + 0.05) {
                        do {
                            let scheduler = FSRS(parameters: .init(enableFuzz: true, enableShortTerm: false))
                            let nextCard = try scheduler.next(card: card, now: mockTomorrow, grade: .good).card
                            timestamps.append(nextCard.due.timeIntervalSince1970)
                            
                            if timestamps.count == 100 {
                                let firstValue = timestamps[0]
                                XCTAssertTrue(timestamps.allSatisfy { $0 == firstValue })
                            }
                        } catch {}
                    }
                } else {
                    // Fallback on earlier versions
                }
            }

        } catch {
            
        }
    }
}
