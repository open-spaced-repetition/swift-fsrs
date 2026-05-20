//
//  FSRSReschduleTests.swift
//  FSRS
//
//  Created by nkq on 10/20/24.
//

import Foundation
import Testing
@testable import FSRS

// MARK: - Models
struct ReviewState {
    var difficulty: Double
    var due: Date
    var rating: Rating
    var review: Date?
    var stability: Double
    var state: CardState
    var reps: Int
    var lapses: Int
    var elapsedDays: Double
    var scheduledDays: Double
}

@Suite struct FSRSReschduleTests {
    let calendar: Calendar = {
        var res = Calendar.current
        res.timeZone = TimeZone(secondsFromGMT: 0)!
        return res
    }()
    let MOCK_NOW: Date

    let scheduler: FSRS

    init() {
        var cal = Calendar.current
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        MOCK_NOW = cal.date(from: DateComponents(year: 2024, month: 8, day: 11, hour: 1, minute: 0))!
        scheduler = FSRS(parameters: .init())
    }

    private func experiment(scheduler: FSRS, reviews: [ReviewLog], skipManual: Bool = true) -> [ReviewState] {
        var filteredReviews = reviews
        if skipManual {
            filteredReviews = reviews.filter { $0.rating != .manual }
        }

        return filteredReviews.enumerated().reduce(into: [ReviewState]()) { state, reviewEnum in
            let (index, review) = reviewEnum

            let currentCard: Card = {
                if let previousState = state.last {
                    return Card(
                        due: previousState.due,
                        stability: previousState.stability,
                        difficulty: previousState.difficulty,
                        elapsedDays: calculateElapsedDays(state: state, index: index),
                        scheduledDays: calculateScheduledDays(previousState),
                        reps: previousState.reps,
                        lapses: previousState.lapses,
                        state: previousState.state,
                        lastReview: previousState.review
                    )
                } else {
                    return FSRSDefaults().createEmptyCard(now: MOCK_NOW)
                }
            }()
            var card: Card
            var log: ReviewLog
            if review.rating == .manual {
                if let previousState = state.last {
                    log = .init(
                        rating: .manual,
                        state: .new,
                        due: previousState.due,
                        stability: previousState.stability,
                        difficulty: previousState.difficulty,
                        elapsedDays: previousState.elapsedDays,
                        lastElapsedDays: previousState.elapsedDays,
                        scheduledDays: previousState.scheduledDays,
                        review: review.review
                    )
                } else {
                    log = .init(
                        rating: .manual,
                        state: .new,
                        due: MOCK_NOW,
                        stability: 0,
                        difficulty: 0,
                        elapsedDays: 0,
                        lastElapsedDays: 0,
                        scheduledDays: 0,
                        review: review.review
                    )
                }
                card = FSRSDefaults().createEmptyCard(now: review.review)

            } else {
                let result = try! scheduler.next(card: currentCard, now: review.review, grade: review.rating)
                card = result.card
                log = result.log
            }

            state.append(ReviewState(
                difficulty: card.difficulty,
                due: card.due,
                rating: log.rating,
                review: log.review,
                stability: card.stability,
                state: card.state,
                reps: card.reps,
                lapses: card.lapses,
                elapsedDays: card.elapsedDays,
                scheduledDays: card.scheduledDays
            ))
        }
    }

    /// Helper used by multiple `@Test`s — renamed from `testReschedule` so it
    /// doesn't read like a discovered test in the report.
    private func runReschedule(scheduler: FSRS, tests: [[Rating]], options: RescheduleOptions) {
        let mockNowTime = MOCK_NOW.timeIntervalSince1970
        for test in tests {
            let reviews = test.enumerated().map { index, rating in
                ReviewLog(
                    rating: rating,
                    state: rating == .manual ? .new : nil,
                    review: Date(timeIntervalSince1970: mockNowTime + TimeInterval(24 * 60 * 60 * (index + 1)))
                )
            }

            let control = try? scheduler.reschedule(
                currentCard: FSRSDefaults().createEmptyCard(),
                reviews: reviews,
                options: options
            ).collections

            let experimentResult = experiment(
                scheduler: scheduler,
                reviews: reviews,
                skipManual: options.skipManual
            )

            for (index, controlItem) in (control ?? []).enumerated() {
                let experimentItem = experimentResult[index]

                #expect(controlItem!.card.difficulty == experimentItem.difficulty)
                #expect(controlItem!.card.due == experimentItem.due)
                #expect(controlItem!.card.stability == experimentItem.stability)
                #expect(controlItem!.card.state == experimentItem.state)
                #expect(controlItem!.card.lastReview?.timeIntervalSince1970 == experimentItem.review?.timeIntervalSince1970)
                #expect(controlItem!.card.reps == experimentItem.reps)
                #expect(controlItem!.card.lapses == experimentItem.lapses)
                #expect(controlItem!.card.elapsedDays == experimentItem.elapsedDays)
                #expect(controlItem!.card.scheduledDays == experimentItem.scheduledDays)
            }
        }
    }

    // MARK: - Helper Functions
    private func calculateElapsedDays(state: [ReviewState], index: Int) -> Double {
        guard index >= 2,
              let previousReview = state[index - 1].review,
              let twoReviewsAgo = state[index - 2].review else {
            return 0
        }
        return Date.dateDiff(now: twoReviewsAgo, pre: previousReview, unit: .days)
    }

    private func calculateScheduledDays(_ previousState: ReviewState) -> Double {
        guard let review = previousState.review else { return 0 }
        return Date.dateDiff(now: review, pre: previousState.due, unit: .days)
    }

    @Test func basicGrade() {
        let grade: [Rating] = [.again, .hard, .good, .easy]
        var tests: [[Rating]] = []
        for i in 0..<grade.count {
            for j in 0..<grade.count {
                for k in 0..<grade.count {
                    for l in 0..<grade.count {
                        tests.append([grade[i], grade[j], grade[k], grade[l]])
                    }
                }
            }
        }
        runReschedule(
            scheduler: scheduler,
            tests: tests,
            options: .init(
                reviewsOrderBy: { a, b in
                    Date.dateDiff(now: a.review, pre: b.review, unit: .days) < 0
                }
            )
        )
    }

    @Test func includeManualRatingSetForget() {
        var tests: [[Rating]] = []
        let ratings: [Rating] = [.manual, .again, .hard, .good, .easy]
        for i in 0..<ratings.count {
            for j in 0..<ratings.count {
                for k in 0..<ratings.count {
                    for l in 0..<ratings.count {
                        for m in 0..<ratings.count {
                            tests.append([ratings[i], ratings[j], ratings[k], ratings[l], ratings[m]])
                        }
                    }
                }
            }
        }
        runReschedule(scheduler: scheduler, tests: tests, options: .init(
            reviewsOrderBy: { a, b in
                Date.dateDiff(now: a.review, pre: b.review, unit: .days) < 0
            },
            skipManual: false)
        )
    }

    @Test func includeManualRatingStateNotProvided() {
        let test: [Rating] = [.easy, .good, .manual, .good]
        let reviews = test.enumerated().map { (index, rating) in
            ReviewLog(rating: rating, state: nil, review: Date(timeIntervalSinceNow: Double(index + 1) * 86400))
        }
        let err = #expect(throws: FSRSError.self) {
            _ = try scheduler.reschedule(
                currentCard: FSRSDefaults().createEmptyCard(),
                reviews: reviews,
                options: .init(skipManual: false, updateMemoryState: true)
            )
        }
        #expect(err?.errorReason == .invalidParam)
    }

    @Test func includeManualRatingDueNotProvided() {
        let test: [Rating] = [.easy, .good, .manual, .good]
        let reviews = test.enumerated().map { (index, rating) in
            ReviewLog(rating: rating, state: rating == .manual ? .review : .new, review: Date(timeIntervalSinceNow: Double(index + 1) * 86400))
        }
        let err = #expect(throws: FSRSError.self) {
            _ = try scheduler.reschedule(
                currentCard: FSRSDefaults().createEmptyCard(),
                reviews: reviews,
                options: .init(skipManual: false, updateMemoryState: true)
            )
        }
        #expect(err?.errorReason == .invalidParam)
    }

    @Test func includeManualRatingManuallyConfigureData() throws {
        let test: [Rating] = [.easy, .good, .manual, .good]
        let reviews = test.enumerated().map { (index, rating) in
            ReviewLog(
                rating: rating,
                state: rating == .manual ? .review : nil,
                due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 4, hour: 17, minute: 0))!,
                stability: 21.79806877,
                difficulty: 3.2828565,
                review: Date(timeIntervalSince1970: MOCK_NOW.timeIntervalSince1970 + Double(60 * 60 * 24 * (index + 1)))
            )
        }

        let expected = RecordLogItem(
            card: Card(
                due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 4, hour: 17, minute: 0))!,
                stability: 21.79806877,
                difficulty: 3.2828565,
                elapsedDays: 1,
                scheduledDays: 21,
                reps: 3,
                lapses: 0,
                state: .review,
                lastReview: calendar.date(from: DateComponents(year: 2024, month: 8, day: 14, hour: 1, minute: 0))!
            ),
            log: ReviewLog(
                rating: .manual,
                state: .review,
                due: calendar.date(from: DateComponents(year: 2024, month: 8, day: 13, hour: 1, minute: 0))!,
                stability: 18.80877052,
                difficulty: 3.22450159,
                elapsedDays: 1,
                lastElapsedDays: 1,
                scheduledDays: 19,
                review: calendar.date(from: DateComponents(year: 2024, month: 8, day: 14, hour: 1, minute: 0))!
            ))
        let nextItemExpected = RecordLogItem(
            card: Card(
                due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 9, hour: 1, minute: 0))!,
                stability: 24.7796143,
                difficulty: 3.28258807,
                elapsedDays: 1,
                scheduledDays: 25,
                reps: 4,
                lapses: 0,
                state: .review,
                lastReview: calendar.date(from: DateComponents(year: 2024, month: 8, day: 15, hour: 1, minute: 0))!
            ),
            log: ReviewLog(
                rating: .good,
                state: .review,
                due: calendar.date(from: DateComponents(year: 2024, month: 8, day: 14, hour: 1, minute: 0))!,
                stability: 21.79806877,
                difficulty: 3.2828565,
                elapsedDays: 1,
                lastElapsedDays: 1,
                scheduledDays: 21,
                review: calendar.date(from: DateComponents(year: 2024, month: 8, day: 15, hour: 1, minute: 0))!
            )
        )

        let result = try scheduler.reschedule(
            currentCard: FSRSDefaults().createEmptyCard(),
            reviews: reviews,
            options: .init(skipManual: false)
        )

        #expect(result.collections[2] == expected)
        #expect(result.collections[3] == nextItemExpected)
    }

    @Test func includeManualRatingAndDsNotProvided() throws {
        let test: [Rating] = [.easy, .good, .manual, .good]
        var reviews: [ReviewLog] = []
        var index = 0
        let timeInterval: TimeInterval = MOCK_NOW.timeIntervalSince1970
        for rating in test {
            let reviewDate = Date(timeIntervalSince1970: Double(24 * 60 * 60 * (index + 1)) + timeInterval)
            reviews.append(
                ReviewLog(
                    rating: rating,
                    state: (rating == .manual) ? .review : nil,
                    due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 04, hour: 17, minute: 0))!,
                    review: reviewDate
                )
            )
            index += 1
        }

        let expected = RecordLogItem(
            card: Card(
                due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 04, hour: 17, minute: 0))!,
                stability: 18.80877052,
                difficulty: 3.22450159,
                elapsedDays: 1,
                scheduledDays: 21,
                reps: 3,
                lapses: 0,
                state: .review,
                lastReview: calendar.date(from: DateComponents(year: 2024, month: 8, day: 14, hour: 1, minute: 0))!
            ),
            log: ReviewLog(
                rating: .manual,
                state: .review,
                due: calendar.date(from: DateComponents(year: 2024, month: 8, day: 13, hour: 1, minute: 0))!,
                stability: 18.80877052,
                difficulty: 3.22450159,
                elapsedDays: 1,
                lastElapsedDays: 1,
                scheduledDays: 19,
                review: calendar.date(from: DateComponents(year: 2024, month: 8, day: 14, hour: 1, minute: 0))!
            )
        )

        let currentCard = Card(
            due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 06, hour: 1, minute: 0))!,
            stability: 21.79806877,
            difficulty: 3.2828565,
            elapsedDays: 1,
            scheduledDays: 22,
            reps: 4,
            lapses: 0,
            state: .review,
            lastReview: calendar.date(from: DateComponents(year: 2024, month: 8, day: 15, hour: 1, minute: 0))!
        )

        let res = try scheduler.reschedule(
            currentCard: currentCard,
            reviews: reviews,
            options: .init(skipManual: false)
        )

        #expect(res.collections[2] == expected)
        #expect(res.rescheduleItem == nil)
    }

    @Test func getRescheduleItem() throws {
        let test: [Rating] = [.easy, .good, .good, .good]

        let reviews: [ReviewLog] = test.enumerated().map { index, rating in
            let reviewDate = Date(timeIntervalSince1970: Double(60 * 60 * 24 * (index + 1)) + MOCK_NOW.timeIntervalSince1970)
            return ReviewLog(
                rating: rating,
                state: rating == .manual ? .review : nil,
                due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 04, hour: 17, minute: 0))!,
                review: reviewDate
            )
        }

        let expected = RecordLogItem(
            card: Card(
                due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 9, hour: 1, minute: 0))!,
                stability: 24.86663381,
                difficulty: 3.22450159,
                elapsedDays: 1,
                scheduledDays: 25,
                reps: 4,
                lapses: 0,
                state: .review,
                lastReview: calendar.date(from: DateComponents(year: 2024, month: 8, day: 15, hour: 1, minute: 0))!
            ),
            log: ReviewLog(
                rating: .good,
                state: .review,
                due: calendar.date(from: DateComponents(year: 2024, month: 8, day: 14, hour: 1, minute: 0))!,
                stability: 21.86357285,
                difficulty: 3.22450159,
                elapsedDays: 1,
                lastElapsedDays: 1,
                scheduledDays: 22,
                review: calendar.date(from: DateComponents(year: 2024, month: 8, day: 15, hour: 1, minute: 0))!
            )
        )

        var curCard = FSRSDefaults().createEmptyCard(now: MOCK_NOW)
        var index = 0
        let reviewAt = calendar.date(from: DateComponents(year: 2024, month: 8, day: 15, hour: 1, minute: 0))!

        for _ in test {
            let res = try scheduler.reschedule(
                currentCard: curCard, reviews: reviews,
                options: .init(skipManual: false, updateMemoryState: true, now: reviewAt)
            )
            let control = res.collections
            let scheduledDays = Date.dateDiff(now: res.rescheduleItem!.card.due, pre: curCard.due, unit: .days)

            #expect(control[control.count - 1] == expected)
            #expect(res.rescheduleItem == {
                var rescheduleLog = expected.log
                rescheduleLog.rating = .manual
                rescheduleLog.state = curCard.state
                rescheduleLog.due = curCard.lastReview ?? curCard.due
                rescheduleLog.lastElapsedDays = curCard.elapsedDays
                rescheduleLog.scheduledDays = scheduledDays
                rescheduleLog.stability = curCard.stability
                rescheduleLog.difficulty = curCard.difficulty
                rescheduleLog.review = reviewAt
                var card = expected.card.newCard
                card.lastReview = reviewAt
                card.reps = curCard.reps + 1
                return RecordLogItem(card: card, log: rescheduleLog)
            }())

            curCard = control[index]!.card
            index += 1
        }
    }

    @Test func handleEmptySetReviews() throws {
        let res = try scheduler.reschedule(
            currentCard: FSRSDefaults().createEmptyCard(),
            reviews: [],
            options: .init()
        )
        #expect(res == IReschedule(collections: [], rescheduleItem: nil))
    }

    @Test func basicReschedule() throws {
        let f = FSRS(parameters: .init())
        let grades: [Rating] = [.good, .good, .good, .good]
        let reviewsAt: [Date] = [
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 13))!,
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 13))!,
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 17))!,
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 28))!
        ]

        var reviews: [ReviewLog] = []
        for i in 0..<grades.count {
            reviews.append(ReviewLog(rating: grades[i], review: reviewsAt[i]))
        }

        let resultsShort = try f.reschedule(
            currentCard: FSRSDefaults().createEmptyCard(),
            reviews: reviews,
            options: .init(skipManual: false)
        )
        let ivlHistoryShort = resultsShort.collections.map { $0!.card.scheduledDays }
        let sHistoryShort = resultsShort.collections.map { $0!.card.stability }
        let dHistoryShort = resultsShort.collections.map { $0!.card.difficulty }

        #expect(resultsShort.rescheduleItem != nil)
        #expect(resultsShort.collections.count == 4)
        #expect(ivlHistoryShort == [0, 4, 14, 38])
        #expect(sHistoryShort == [3.173, 4.46685806, 14.21728391, 37.90805078])
        #expect(dHistoryShort == [5.28243442, 5.27296793, 5.26354498, 5.25416538])

        let fLongTerm = FSRS(parameters: .init(enableShortTerm: false))
        let results = try fLongTerm.reschedule(
            currentCard: FSRSDefaults().createEmptyCard(),
            reviews: reviews,
            options: .init(skipManual: false)
        )
        let ivlHistoryLong = results.collections.map { $0!.card.scheduledDays }
        let sHistoryLong = results.collections.map { $0!.card.stability }
        let dHistoryLong = results.collections.map { $0!.card.difficulty }

        #expect(results.rescheduleItem != nil)
        #expect(results.collections.count == 4)
        #expect(ivlHistoryLong == [3, 4, 13, 37])
        #expect(sHistoryLong == [3.173, 3.173, 12.96611898, 36.73449305])
        #expect(dHistoryLong == [5.28243442, 5.27296793, 5.26354498, 5.25416538])
    }

    @Test func currentCardEqualRescheduleCard() throws {
        let grades: [Rating] = [.good, .good, .good, .good]
        let reviewsAt: [Date] = [
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 13))!,
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 13))!,
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 17))!,
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 28))!
        ]

        var reviews: [ReviewLog] = []
        for i in 0..<grades.count {
            reviews.append(ReviewLog(rating: grades[i], review: reviewsAt[i]))
        }

        let currentCard = Card(
            due: calendar.date(from: DateComponents(year: 2024, month: 11, day: 05))!,
            stability: 37.90805078,
            difficulty: 5.25416538,
            elapsedDays: 11,
            scheduledDays: 9,
            reps: 5,
            lapses: 0,
            state: .review,
            lastReview: calendar.date(from: DateComponents(year: 2024, month: 10, day: 27))!
        )

        let resultsShort = try scheduler.reschedule(
            currentCard: currentCard,
            reviews: reviews,
            options: .init(
                skipManual: false,
                updateMemoryState: true,
                now: calendar.date(from: DateComponents(year: 2024, month: 9, day: 27))!,
                firstCard: FSRSDefaults().createEmptyCard(now: calendar.date(from: DateComponents(year: 2024, month: 8, day: 13))!)
            )
        )

        #expect(resultsShort.rescheduleItem == nil)
    }

    @Test func forgetReschedule() throws {
        let grades: [Rating] = [.good, .good, .good, .good]
        let reviewsAt: [Date] = [
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 13))!,
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 13))!,
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 17))!,
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 28))!
        ]

        var reviews: [ReviewLog] = []
        for i in 0..<grades.count {
            reviews.append(ReviewLog(rating: grades[i], review: reviewsAt[i]))
        }

        let firstCard = FSRSDefaults().createEmptyCard(now: calendar.date(from: DateComponents(year: 2024, month: 9, day: 28))!)
        var currentCard: Card = FSRSDefaults().createEmptyCard()
        var historyCard: [Card] = []

        for review in reviews {
            let item = try scheduler.next(card: currentCard, now: review.review, grade: review.rating)
            currentCard = item.card
            historyCard.append(currentCard)
        }

        let item = scheduler.forget(
            card: currentCard,
            now: calendar.date(from: DateComponents(year: 2024, month: 10, day: 27))!
        )
        currentCard = item.card

        let results = try scheduler.reschedule(
            currentCard: currentCard,
            reviews: reviews,
            options: .init(
                updateMemoryState: true,
                now: calendar.date(from: DateComponents(year: 2024, month: 10, day: 27))!,
                firstCard: firstCard
            )
        )

        #expect(results.rescheduleItem != nil)
        #expect(results.rescheduleItem?.card.due == historyCard.last?.due)
        #expect(results.rescheduleItem?.card.stability == historyCard.last?.stability)
        #expect(results.rescheduleItem?.card.difficulty == historyCard.last?.difficulty)
    }

    /// FSRSReschedule.reschedule wraps each non-manual replay in a do/catch:
    /// if `fsrs.next` throws (e.g. malformed learning steps), it logs and
    /// continues. Verify that when every replay throws, the result is an empty
    /// collection (no crash, no propagated throw) and the manual record is nil.
    @Test func rescheduleSwallowsReplayErrors() throws {
        let f = FSRS(parameters: .init(
            w: FSRSDefaults.defaultWv6,
            enableFuzz: false,
            learningSteps: ["1m", "bogus"]  // "bogus" trips convertStepUnitToMinutes
        ))
        let now = calendar.date(from: DateComponents(year: 2024, month: 9, day: 13))!
        let reviews: [ReviewLog] = (1...3).map { i in
            ReviewLog(
                rating: .good,
                review: calendar.date(from: DateComponents(year: 2024, month: 9, day: 13 + i))!
            )
        }

        let result = try f.reschedule(
            currentCard: FSRSDefaults().createEmptyCard(),
            reviews: reviews,
            options: .init(now: now)
        )

        // Every replay threw and was swallowed — no items produced, manual nil.
        #expect(result.collections.isEmpty)
        #expect(result.rescheduleItem == nil)
    }
}
