//
//  FSRSV5Tests.swift
//  FSRS
//
//  Created by nkq on 10/19/24.
//


import XCTest
@testable import FSRS

class FSRSV5Tests: XCTestCase {
    var f: FSRS!
    var calendar: Calendar = {
        var res = Calendar.current
        res.timeZone = .init(secondsFromGMT: 0)!
        return res
    }()
    let w: [Double] = [
        0.4197, 1.1869, 3.0412, 15.2441, 7.1434, 0.6477, 1.0007, 0.0674, 1.6597,
        0.1712, 1.1178, 2.0225, 0.0904, 0.3025, 2.1214, 0.2498, 2.9466, 0.4891,
        0.6468,
    ]

    override func setUp() {
        super.setUp()
        f = FSRS(parameters: .init(w: w))
    }

    func testIvlHistory() {
        var card = FSRSDefaults().createEmptyCard()
        var now = calendar.date(from: DateComponents(year: 2022, month: 12, day: 29, hour: 12, minute: 30))!
        var schedulingCards = f.repeat(card: card, now: now)

        let ratings: [Rating] = [
            .good, .good, .good, .good, .good, .good,
            .again, .again, .good, .good, .good, .good, .good,
        ]

        var ivlHistory: [Int] = []
        
        for rating in ratings {
            do {
                var grades = Rating.allCases
                grades.removeAll(where: { $0 == .manual })
                for check in grades {
                    let rollbackCard = try f.rollback(card: schedulingCards[check]!.card, log: schedulingCards[check]!.log)
                    XCTAssertEqual(rollbackCard, card)
                    let elapsedDays = card.lastReview != nil ? Date.dateDiff(now: now, pre: card.lastReview, unit: .days) : 0
                    XCTAssertEqual(schedulingCards[check]!.log.elapsedDays, elapsedDays)
                    let tempF = FSRS(parameters: .init(w: w))
                    let next = try tempF.next(card: card, now: now, grade: check)
                    XCTAssertEqual(schedulingCards[check], next)
                }
            } catch {
                
            }

            card = schedulingCards[rating]!.card
            let ivl = card.scheduledDays
            ivlHistory.append(Int(ivl))
            now = card.due
            schedulingCards = f.repeat(card: card, now: now)
        }

        XCTAssertEqual(ivlHistory, [0, 4, 17, 62, 198, 563, 0, 0, 9, 27, 74, 190, 457])
    }

    func testMemoryState() {
        var card = FSRSDefaults().createEmptyCard()
        var now = calendar.date(from: DateComponents(year: 2022, month: 12, day: 29, hour: 12, minute: 30))!
        var schedulingCards = f.repeat(card: card, now: now)

        let ratings: [Rating] = [
            .again, .good, .good, .good, .good, .good,
        ]
        let intervals: [Int] = [0, 0, 1, 3, 8, 21]
        
        for (index, rating) in ratings.enumerated() {
            card = schedulingCards[rating]!.card
            now.addTimeInterval(Double(intervals[index]) * 24 * 60 * 60) // Adding days as seconds
            schedulingCards = f.repeat(card: card, now: now)
        }

        let stability = schedulingCards[Rating.good]!.card.stability
        let difficulty = schedulingCards[Rating.good]!.card.difficulty
        XCTAssertEqual(stability, 71.4554, accuracy: 0.0001)
        XCTAssertEqual(difficulty, 5.0976, accuracy: 0.0001)
    }

    func testFirstRepeat() {
        let card = FSRSDefaults().createEmptyCard()
        let now = calendar.date(from: DateComponents(year: 2022, month: 12, day: 29, hour: 12, minute: 30))!
        let schedulingCards = f.repeat(card: card, now: now)

        var stability: [Double] = []
        var difficulty: [Double] = []
        var elapsedDays: [Int] = []
        var scheduledDays: [Int] = []
        var reps: [Int] = []
        var lapses: [Int] = []
        var states: [CardState] = []

        for item in schedulingCards.recordLog {
            let firstCard = item.value.card
            stability.append(firstCard.stability.toFixedNumber(4))
            difficulty.append(firstCard.difficulty.toFixedNumber(8))
            reps.append(firstCard.reps)
            lapses.append(firstCard.lapses)
            elapsedDays.append(Int(firstCard.elapsedDays))
            scheduledDays.append(Int(firstCard.scheduledDays))
            states.append(firstCard.state)
        }

        XCTAssertEqual(Set(stability), Set([0.4197, 1.1869, 3.0412, 15.2441]))
        XCTAssertEqual(Set(difficulty), Set([7.1434, 6.23225985, 4.49094334, 1.16304343]))
        XCTAssertEqual(Set(reps), Set([1, 1, 1, 1]))
        XCTAssertEqual(Set(lapses), Set([0, 0, 0, 0]))
        XCTAssertEqual(Set(elapsedDays), Set([0, 0, 0, 0]))
        XCTAssertEqual(Set(scheduledDays), Set([0, 0, 0, 15]))
        XCTAssertEqual(Set(states), Set([.learning, .learning, .learning, .review]))
    }
}

class RetrievabilityTests: XCTestCase {
    var fsrs: FSRS!
    let dateFormatter = DateFormatter()

    override func setUp() {
        super.setUp()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"  // "2024-03-21 15:30:45"
        fsrs = FSRS(parameters: .init())
    }

    func testReturnZeroForNewCards() {
        let card = FSRSDefaults().createEmptyCard()
        let now = Date()
        let expected = "0.00%"
        XCTAssertEqual(fsrs.getRetrievability(card: card, now: now).string, expected)
    }

    func testRetrievabilityPercentageForReviewCards() {
        let card = FSRSDefaults().createEmptyCard(now: dateFormatter.date(from: "2023-12-01 04:00:00")!)
        let sc = fsrs.repeat(card: card, now: dateFormatter.date(from: "2023-12-01 04:05:00")!)
        let expectedResults = ["100.00%", "100.00%", "100.00%", "90.26%"]
        let expectedNumbers = [1.0, 1.0, 1.0, 0.9026208]

        for grade in Rating.allCases {
            if grade != .manual {
                XCTAssertEqual(fsrs.getRetrievability(card: sc[grade]!.card, now: sc[grade]!.card.due).string, expectedResults[grade.rawValue - 1])
                XCTAssertEqual(fsrs.getRetrievability(card: sc[grade]!.card, now: sc[grade]!.card.due).number, expectedNumbers[grade.rawValue - 1])
            }
        }
    }

//    func testFakeCurrentSystemTime() {
//        let card = FSRSDefaults().createEmptyCard(now: dateFormatter.date(from: "2023-12-01 04:00:00")!)
//        let sc = fsrs.repeat(card: card, now: dateFormatter.date(from: "2023-12-01 04:05:00")!)
//        let expectedResults = ["100.00%", "100.00%", "100.00%", "90.26%"]
//        let expectedNumbers = [1.0, 1.0, 1.0, 0.9026208]
//
//        var strings = [String]()
//        var numbers = [Double]()
//        for grade in Rating.allCases {
//            if grade != .manual {
//                strings.append(fsrs.getRetrievability(card: sc[grade]!.card).string)
//                numbers.append(fsrs.getRetrievability(card: sc[grade]!.card).number)
//            }
//        }
//        XCTAssertEqual(strings, expectedResults)
//        XCTAssertEqual(numbers, expectedNumbers)
//    }

    func testLoopAgain() {
        var card = FSRSDefaults().createEmptyCard()
        var now = Date()
        
        do {
            for i in 0..<5 {
                card = try fsrs.next(card: card, now: now, grade: .again).card
                now = card.due
                
                let retrievability = fsrs.getRetrievability(card: card, now: now).number
                print("Loop \(i + 1): stability: \(card.stability) retrievability: \(retrievability) ")
                XCTAssertFalse(retrievability.isNaN)
            }
        } catch {
            
        }
    }
}

class FSRSNextMethodTests: XCTestCase {
    var fsrs: FSRS!

    override func setUp() {
        super.setUp()
        fsrs = FSRS(parameters: .init())
    }

    func testInvalidGrade() {
        let card = FSRSDefaults().createEmptyCard()
        let now = Date()
        let invalidGrade = Rating.manual
        XCTAssertThrowsError(try fsrs.next(card: card, now: now, grade: invalidGrade)) { error in
            XCTAssertEqual((error as? FSRSError)?.errorReason, .invalidRating)
        }
    }
}
