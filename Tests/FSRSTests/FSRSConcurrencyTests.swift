//
//  FSRSConcurrencyTests.swift
//
//  Verifies the library is safe to use from concurrent code: a single shared
//  `FSRS` instance produces identical results when called serially vs. fanned
//  out across many `Task`s, and the public value types conform to `Sendable`.
//

import XCTest
@testable import FSRS

final class FSRSConcurrencyTests: XCTestCase {
    /// Compile-time assertion: the listed types must be `Sendable`. If a future
    /// change adds non-Sendable state to one of them, this stops compiling.
    func testPublicTypesAreSendable() {
        func _requireSendable<T: Sendable>(_: T.Type) {}
        _requireSendable(Card.self)
        _requireSendable(ReviewLog.self)
        _requireSendable(RecordLogItem.self)
        _requireSendable(FSRSParameters.self)
        _requireSendable(FSRSReview.self)
        _requireSendable(FSRSState.self)
        _requireSendable(IPreview.self)
        _requireSendable(IReschedule.self)
        _requireSendable(RescheduleOptions.self)
        _requireSendable(CardState.self)
        _requireSendable(Rating.self)
        _requireSendable(FSRSAlgorithmVersion.self)
        _requireSendable(FSRSError.self)
        _requireSendable(FSRS.self)
    }

    /// Fans `repeat` and `next` out across many tasks against a *shared*
    /// `FSRS` instance with fuzz enabled. Compares to a serial baseline. If
    /// any per-call state ever leaks back onto the algorithm instance (the
    /// pre-refactor `seed` race), this catches it.
    func testConcurrentRepeatMatchesSerialBaseline() async throws {
        let params = FSRSParameters(enableFuzz: true)
        let fSerial = FSRS(parameters: params)
        let fShared = FSRS(parameters: params)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let baseDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!

        // Build a population of distinct cards. Spread `reps`, stability, and
        // review time so each call hits a different seed.
        struct Input: Sendable {
            let card: Card
            let now: Date
        }
        var inputs: [Input] = []
        for i in 0..<128 {
            let card = Card(
                due: calendar.date(byAdding: .day, value: i, to: baseDate)!,
                stability: 5.0 + Double(i) * 0.37,
                difficulty: 4.0 + Double(i % 8) * 0.13,
                elapsedDays: Double(i % 7),
                scheduledDays: Double(i % 11),
                reps: i,
                lapses: i % 3,
                state: .review,
                lastReview: calendar.date(byAdding: .day, value: i - 5, to: baseDate)
            )
            let now = calendar.date(byAdding: .day, value: i + 10, to: baseDate)!
            inputs.append(Input(card: card, now: now))
        }

        let serial: [IPreview] = try inputs.map { try fSerial.repeat(card: $0.card, now: $0.now) }

        let parallel: [(Int, IPreview)] = await withTaskGroup(of: (Int, IPreview).self) { group in
            for (idx, input) in inputs.enumerated() {
                group.addTask {
                    (idx, try! fShared.repeat(card: input.card, now: input.now))
                }
            }
            var collected: [(Int, IPreview)] = []
            for await pair in group {
                collected.append(pair)
            }
            return collected
        }

        XCTAssertEqual(parallel.count, serial.count)
        let parallelSorted = parallel.sorted { $0.0 < $1.0 }.map { $0.1 }

        for (i, (s, p)) in zip(serial, parallelSorted).enumerated() {
            for grade in [Rating.again, .hard, .good, .easy] {
                XCTAssertEqual(s[grade], p[grade], "mismatch at index \(i) grade \(grade)")
            }
        }
    }

    /// Same idea for `next`, exercising the rating-specific path that today
    /// reads the seed inside `nextInterval`/`applyFuzz`.
    func testConcurrentNextMatchesSerialBaseline() async throws {
        let params = FSRSParameters(enableFuzz: true)
        let fSerial = FSRS(parameters: params)
        let fShared = FSRS(parameters: params)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let baseDate = calendar.date(from: DateComponents(year: 2024, month: 6, day: 1))!

        struct Input: Sendable {
            let card: Card
            let now: Date
            let grade: Rating
        }
        let grades: [Rating] = [.again, .hard, .good, .easy]
        var inputs: [Input] = []
        for i in 0..<200 {
            let card = Card(
                due: calendar.date(byAdding: .day, value: i, to: baseDate)!,
                stability: 1.0 + Double(i) * 0.5,
                difficulty: 1.0 + Double(i % 9),
                elapsedDays: Double(i % 14),
                scheduledDays: Double(i % 13),
                reps: i + 1,
                lapses: i % 4,
                state: .review,
                lastReview: calendar.date(byAdding: .day, value: i - 3, to: baseDate)
            )
            let now = calendar.date(byAdding: .day, value: i + 20, to: baseDate)!
            inputs.append(Input(card: card, now: now, grade: grades[i % grades.count]))
        }

        let serial: [RecordLogItem] = try inputs.map {
            try fSerial.next(card: $0.card, now: $0.now, grade: $0.grade)
        }

        let parallel: [(Int, RecordLogItem)] = await withTaskGroup(of: (Int, RecordLogItem)?.self) { group in
            for (idx, input) in inputs.enumerated() {
                group.addTask {
                    do {
                        let item = try fShared.next(card: input.card, now: input.now, grade: input.grade)
                        return (idx, item)
                    } catch {
                        return nil
                    }
                }
            }
            var collected: [(Int, RecordLogItem)] = []
            for await pair in group {
                if let pair = pair { collected.append(pair) }
            }
            return collected
        }

        XCTAssertEqual(parallel.count, serial.count)
        let parallelSorted = parallel.sorted { $0.0 < $1.0 }.map { $0.1 }
        for (i, (s, p)) in zip(serial, parallelSorted).enumerated() {
            XCTAssertEqual(s, p, "mismatch at index \(i)")
        }
    }
}
