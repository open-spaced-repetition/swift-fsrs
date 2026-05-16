//
//  FSRSCompletionHandlerTests.swift
//
//  The public FSRS surface exposes optional completion-handler closures on
//  `repeat`, `next`, `rollback`, `forget`, and `reschedule` (via
//  RescheduleOptions.recordLogHandler). Without these tests those branches
//  were entirely unexercised.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSCompletionHandlerTests {

    let f: FSRS

    init() {
        f = FSRS(parameters: .init(enableFuzz: false))
    }

    @Test func repeatRunsCompletionHandler() throws {
        let card = FSRSDefaults().createEmptyCard()
        let now = Date()
        let baseline = try f.repeat(card: card, now: now)

        // Identity handler — proves the branch is taken and the result is
        // what the handler returned, not the un-handled value.
        let sentinel = IPreview(recordLog: [:])
        let returned = try f.repeat(card: card, now: now) { _ in sentinel }
        #expect(returned.recordLog.isEmpty)
        #expect(baseline.recordLog.isEmpty == false)
    }

    @Test func nextRunsCompletionHandler() throws {
        let card = FSRSDefaults().createEmptyCard()
        let now = Date()
        let baseline = try f.next(card: card, now: now, grade: .good)

        // Mutate the returned card via the handler, observe the mutation.
        var bumped = baseline
        bumped.card.reps = 99
        let returned = try f.next(card: card, now: now, grade: .good) { _ in bumped }
        #expect(returned.card.reps == 99)
    }

    @Test func rollbackRunsCompletionHandler() throws {
        let card = FSRSDefaults().createEmptyCard()
        let now = Date()
        let preview = try f.repeat(card: card, now: now)
        let goodItem = preview[.good]!

        let sentinel = Card(due: Date(timeIntervalSince1970: 0))
        let returned = try f.rollback(card: goodItem.card, log: goodItem.log) { _ in sentinel }
        #expect(returned.due == sentinel.due)
    }

    @Test func forgetRunsCompletionHandler() throws {
        let card = FSRSDefaults().createEmptyCard()
        let now = Date()
        let forgetTime = now.addingTimeInterval(86400)

        var marker = f.forget(card: card, now: forgetTime, resetCount: true)
        marker.card.reps = 42
        let returned = f.forget(card: card, now: forgetTime, resetCount: true) { _ in marker }
        #expect(returned.card.reps == 42)
    }

    @Test func rescheduleRecordLogHandlerMapsItems() throws {
        let card = FSRSDefaults().createEmptyCard()
        let now = Date()
        let reviews: [ReviewLog] = [
            ReviewLog(rating: .good, review: now.addingTimeInterval(0)),
            ReviewLog(rating: .good, review: now.addingTimeInterval(86400)),
            ReviewLog(rating: .good, review: now.addingTimeInterval(2 * 86400)),
        ]

        // The handler replaces every RecordLogItem with nil; the result should
        // reflect that — proving recordLogHandler ran on every collection item
        // and on the manual record.
        let options = RescheduleOptions(
            recordLogHandler: { _ in nil },
            now: now.addingTimeInterval(7 * 86400)
        )
        let result = try f.reschedule(currentCard: card, reviews: reviews, options: options)
        #expect(result.collections.allSatisfy { $0 == nil })
        #expect(result.rescheduleItem == nil)
    }
}
