//
//  ReviewState.swift
//  FSRS
//
//  Created by nkq on 10/20/24.
//


import XCTest
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


// MARK: - Test Class
class FSRSReschduleTests: XCTestCase {
    var calendar: Calendar = {
        var res = Calendar.current
        res.timeZone = .init(secondsFromGMT: 0)!
        return res
    }()
    lazy var MOCK_NOW = calendar.date(from: DateComponents(year: 2024, month: 8, day: 11, hour: 1, minute: 0))! // 2024, 7, 11, 1, 0, 0 UTC

    func experiment(scheduler: FSRS, reviews: [ReviewLog], skipManual: Bool = true) -> [ReviewState] {
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
    
    func testReschedule(scheduler: FSRS, tests: [[Rating]], options: RescheduleOptions) {
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
                
                XCTAssertEqual(controlItem!.card.difficulty, experimentItem.difficulty)
                XCTAssertEqual(controlItem!.card.due, experimentItem.due)
                XCTAssertEqual(controlItem!.card.stability, experimentItem.stability)
                XCTAssertEqual(controlItem!.card.state, experimentItem.state)
                XCTAssertEqual(controlItem!.card.lastReview?.timeIntervalSince1970,
                               experimentItem.review?.timeIntervalSince1970)
                XCTAssertEqual(controlItem!.card.reps, experimentItem.reps)
                XCTAssertEqual(controlItem!.card.lapses, experimentItem.lapses)
                XCTAssertEqual(controlItem!.card.elapsedDays, experimentItem.elapsedDays)
                XCTAssertEqual(controlItem!.card.scheduledDays, experimentItem.scheduledDays)
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

    var scheduler: FSRS!

    override func setUp() {
        super.setUp()
        scheduler = FSRS(parameters: .init())
    }

    func testBasicGrade() {
        let grade = [Rating.again, .hard, .good, .easy]
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
        testReschedule(
            scheduler: scheduler,
            tests: tests,
            options: .init(
                reviewsOrderBy: { a, b in
                    Date.dateDiff(now: a.review, pre: b.review, unit: .days) < 0
                }
            )
        )
    }

    func testIncludeManualRatingSetForget() {
        var tests: [[Rating]] = []
        let ratings = [Rating.manual, Rating.again, Rating.hard, Rating.good, Rating.easy]
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
        print("reschedule case size: \(tests.count)")
        testReschedule(scheduler: scheduler, tests: tests, options: .init(
            reviewsOrderBy: { a, b in
                Date.dateDiff(now: a.review, pre: b.review, unit: .days) < 0
            },
            skipManual: false)
        )
    }

    func testIncludeManualRatingStateNotProvided() {
        let test = [Rating.easy, Rating.good, Rating.manual, Rating.good]
        let reviews = test.enumerated().map { (index, rating) in
            ReviewLog(rating: rating, state: nil, review: Date(timeIntervalSinceNow: Double(index + 1) * 86400))
        }
        XCTAssertThrowsError(try scheduler.reschedule(
            currentCard: FSRSDefaults().createEmptyCard(),
            reviews: reviews,
            options: .init(skipManual: false, updateMemoryState: true)
        )) { error in
            XCTAssertEqual((error as? FSRSError)?.errorReason, .invalidParam)
        }
    }

    func testIncludeManualRatingDueNotProvided() {
        let test = [Rating.easy, Rating.good, Rating.manual, Rating.good]
        let reviews = test.enumerated().map { (index, rating) in
            ReviewLog(rating: rating, state: rating == .manual ? .review : .new, review: Date(timeIntervalSinceNow: Double(index + 1) * 86400))
        }
        XCTAssertThrowsError(try scheduler.reschedule(
            currentCard: FSRSDefaults().createEmptyCard(),
            reviews: reviews,
            options: .init(skipManual: false, updateMemoryState: true)
        )) { error in
            XCTAssertEqual((error as? FSRSError)?.errorReason, .invalidParam)
        }
    }

    func testIncludeManualRatingManuallyConfigureData() {
        let test = [Rating.easy, Rating.good, Rating.manual, Rating.good]
        let reviews = test.enumerated().map { (index, rating) in
            ReviewLog(
                rating: rating,
                state: rating == .manual ? .review : nil,
                due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 4, hour: 17, minute: 0))!,
                stability: 21.79806877,
                difficulty: 3.2828565,
                review: Date(timeIntervalSince1970: MOCK_NOW.timeIntervalSince1970 + Double(
                    60 * 60 * 24 * (index + 1)
                ))
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
        
        let result = try! scheduler.reschedule(
            currentCard: FSRSDefaults().createEmptyCard(),
            reviews: reviews,
            options: .init(skipManual: false)
        )
        
        XCTAssertEqual(result.collections[2], expected)
        XCTAssertEqual(result.collections[3], nextItemExpected)
    }

    func testIncludeManualRatingAndDsNotProvided() {
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
                    due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 04, hour: 17, minute: 0))!, // '2024-09-04T17:00:00.000Z'
                    review: reviewDate
                )
            )
            index += 1
        }

        let expected = RecordLogItem(
            card: Card(
                due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 04, hour: 17, minute: 0))!, // '2024-09-04T17:00:00.000Z'
                stability: 18.80877052,
                difficulty: 3.22450159,
                elapsedDays: 1,
                scheduledDays: 21,
                reps: 3,
                lapses: 0,
                state: .review,
                lastReview: calendar.date(from: DateComponents(year: 2024, month: 8, day: 14, hour: 1, minute: 0))! // '2024-08-14T01:00:00.000Z'
            ),
            log: ReviewLog(
                rating: .manual,
                state: .review,
                due: calendar.date(from: DateComponents(year: 2024, month: 8, day: 13, hour: 1, minute: 0))!, // '2024-08-13T01:00:00.000Z'
                stability: 18.80877052,
                difficulty: 3.22450159,
                elapsedDays: 1,
                lastElapsedDays: 1,
                scheduledDays: 19,
                review: calendar.date(from: DateComponents(year: 2024, month: 8, day: 14, hour: 1, minute: 0))! // '2024-08-14T01:00:00.000Z'
            )
        )
        
        let currentCard = Card(
            due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 06, hour: 1, minute: 0))!, // '2024-09-06T01:00:00.000Z'
            stability: 21.79806877,
            difficulty: 3.2828565,
            elapsedDays: 1,
            scheduledDays: 22,
            reps: 4,
            lapses: 0,
            state: .review,
            lastReview: calendar.date(from: DateComponents(year: 2024, month: 8, day: 15, hour: 1, minute: 0))! // '2024-08-15T01:00:00.000Z'
        )

        let res = try! scheduler.reschedule(
            currentCard: currentCard,
            reviews: reviews,
            options: .init(skipManual: false)
        )
        
        XCTAssertEqual(res.collections[2], expected)
        XCTAssertNil(res.rescheduleItem)
    }

    func testGetRescheduleItem() {
        let test: [Rating] = [.easy, .good, .good, .good]
            
        let reviews: [ReviewLog] = test.enumerated().map { index, rating in
            let reviewDate = Date(timeIntervalSince1970: Double(60 * 60 * 24 * (index + 1)) + MOCK_NOW.timeIntervalSince1970)
            return ReviewLog(
                rating: rating,
                state: rating == .manual ? .review : nil,
                due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 04, hour: 17, minute: 0))!, // '2024-09-04T17:00:00.000Z'
                review: reviewDate
            )
        }
        
        let expected = RecordLogItem(
            card: Card(
                due: calendar.date(from: DateComponents(year: 2024, month: 9, day: 9, hour: 1, minute: 0))!, // '2024-09-09T01:00:00.000Z'
                stability: 24.86663381,
                difficulty: 3.22450159,
                elapsedDays: 1,
                scheduledDays: 25,
                reps: 4,
                lapses: 0,
                state: .review,
                lastReview: calendar.date(from: DateComponents(year: 2024, month: 8, day: 15, hour: 1, minute: 0))! // '2024-08-15T01:00:00.000Z'
            ),
            log: ReviewLog(
                rating: .good,
                state: .review,
                due: calendar.date(from: DateComponents(year: 2024, month: 8, day: 14, hour: 1, minute: 0))!, // '2024-08-14T01:00:00.000Z'
                stability: 21.86357285,
                difficulty: 3.22450159,
                elapsedDays: 1,
                lastElapsedDays: 1,
                scheduledDays: 22,
                review: calendar.date(from: DateComponents(year: 2024, month: 8, day: 15, hour: 1, minute: 0))! // '2024-08-15T01:00:00.000Z'
            )
        )

        var curCard = FSRSDefaults().createEmptyCard(now: MOCK_NOW)
        var index = 0
        let reviewAt = calendar.date(from: DateComponents(year: 2024, month: 8, day: 15, hour: 1, minute: 0))! // '2024-08-15T01:00:00.000Z'
        
        for _ in test {
            let res = try! scheduler.reschedule(
                currentCard: curCard, reviews: reviews,
                options: .init(skipManual: false, updateMemoryState: true, now: reviewAt)
            )
            let control = res.collections
            let scheduledDays = Date.dateDiff(now: res.rescheduleItem!.card.due, pre: curCard.due, unit: .days)
            
            XCTAssertEqual(control[control.count - 1], expected)
            XCTAssertEqual(res.rescheduleItem, {
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

    func testHandleEmptySetReviews() {
        let res = try! scheduler.reschedule(
            currentCard: FSRSDefaults().createEmptyCard(),
            reviews: [],
            options: .init()
        )
        XCTAssertEqual(res, IReschedule.init(collections: [], rescheduleItem: nil))
    }

    func testBasicReschedule() {
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
            reviews.append(ReviewLog(
                rating: grades[i],
                review: reviewsAt[i]
            ))
        }

        let resultsShort = try! f.reschedule(
            currentCard: FSRSDefaults().createEmptyCard(),
            reviews: reviews,
            options: .init(skipManual: false)
        )
        let ivlHistoryShort = resultsShort.collections.map { $0!.card.scheduledDays }
        let sHistoryShort = resultsShort.collections.map { $0!.card.stability }
        let dHistoryShort = resultsShort.collections.map { $0!.card.difficulty }

        XCTAssertNotNil(resultsShort.rescheduleItem)
        XCTAssertEqual(resultsShort.collections.count, 4)
        XCTAssertEqual(ivlHistoryShort, [0, 4, 14, 38])
        XCTAssertEqual(sHistoryShort, [
            3.173, 4.46685806, 14.21728391, 37.90805078,
        ])
        XCTAssertEqual(dHistoryShort, [
            5.28243442, 5.27296793, 5.26354498, 5.25416538,
        ])

        // Switch to long-term scheduler
        f.parameters.enableShortTerm = false
        let results = try! f.reschedule(
            currentCard: FSRSDefaults().createEmptyCard(),
            reviews: reviews,
            options: .init(skipManual: false)
        )
        let ivlHistoryLong = results.collections.map { $0!.card.scheduledDays }
        let sHistoryLong = results.collections.map { $0!.card.stability }
        let dHistoryLong = results.collections.map { $0!.card.difficulty }

        XCTAssertNotNil(results.rescheduleItem)
        XCTAssertEqual(results.collections.count, 4)
        XCTAssertEqual(ivlHistoryLong, [3, 4, 13, 37])
        XCTAssertEqual(sHistoryLong, [3.173, 3.173, 12.96611898, 36.73449305])
        XCTAssertEqual(dHistoryLong, [5.28243442, 5.27296793, 5.26354498, 5.25416538])
    }

    func testCurrentCardEqualRescheduleCard() {
        let grades: [Rating] = [.good, .good, .good, .good]
        let reviewsAt: [Date] = [
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 13))!, // 2024-09-13T00:00:00.000Z
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 13))!, // 2024-09-13T00:00:00.000Z
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 17))!, // 2024-09-17T00:00:00.000Z
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 28))! // 2024-09-28T00:00:00.000Z
        ]

        var reviews: [ReviewLog] = []
        for i in 0..<grades.count {
            reviews.append(ReviewLog(
                rating: grades[i],
                review: reviewsAt[i]
            ))
        }

        let currentCard = Card(
            due: calendar.date(from: DateComponents(year: 2024, month: 11, day: 05))!, // 2024-11-07T00:00:00.000Z
            stability: 37.90805078,
            difficulty: 5.25416538,
            elapsedDays: 11,
            scheduledDays: 9,
            reps: 5,
            lapses: 0,
            state: .review,
            lastReview: calendar.date(from: DateComponents(year: 2024, month: 10, day: 27))! // 2024-10-27T00:00:00.000Z
        )

        let resultsShort = try! scheduler.reschedule(
            currentCard: currentCard,
            reviews: reviews,
            options: .init(
                skipManual: false,
                updateMemoryState: true,
                now: calendar.date(from: DateComponents(year: 2024, month: 9, day: 27))!,
                firstCard: FSRSDefaults().createEmptyCard(now: calendar.date(from: DateComponents(year: 2024, month: 8, day: 13))!)
            )
        )
        
        XCTAssertNil(resultsShort.rescheduleItem)
    }

    func testForget() {
        let grades: [Rating] = [.good, .good, .good, .good]
        let reviewsAt: [Date] = [
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 13))!, // 2024-09-13T00:00:00.000Z
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 13))!, // 2024-09-13T00:00:00.000Z
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 17))!, // 2024-09-17T00:00:00.000Z
            calendar.date(from: DateComponents(year: 2024, month: 9, day: 28))! // 2024-09-28T00:00:00.000Z
        ]

        var reviews: [ReviewLog] = []
        for i in 0..<grades.count {
            reviews.append(ReviewLog(
                rating: grades[i],
                review: reviewsAt[i]
            ))
        }
        
        let firstCard = FSRSDefaults().createEmptyCard(now: calendar.date(from: DateComponents(year: 2024, month: 9, day: 28))!) // 2024-09-28T00:00:00.000Z
        var currentCard: Card = FSRSDefaults().createEmptyCard()
        var historyCard: [Card] = []
        
        for review in reviews {
            let item = try! scheduler.next(
                card: currentCard,
                now: review.review,
                grade: review.rating
            )
            currentCard = item.card
            historyCard.append(currentCard)
        }
        
        let item = scheduler.forget(
            card: currentCard,
            now: calendar.date(from: DateComponents(year: 2024, month: 10, day: 27))!  // 2024-10-27T00:00:00.000Z
        )
        currentCard = item.card

        let results = try! scheduler.reschedule(
            currentCard: currentCard,
            reviews: reviews,
            options: .init(
                updateMemoryState: true,
                now: calendar.date(from: DateComponents(year: 2024, month: 10, day: 27))!, // 2024-10-27T00:00:00.000Z
                firstCard: firstCard
            )
        )
        
        XCTAssertNotNil(results.rescheduleItem)
        XCTAssertEqual(results.rescheduleItem?.card.due, historyCard.last?.due)
        XCTAssertEqual(results.rescheduleItem?.card.stability, historyCard.last?.stability)
        XCTAssertEqual(results.rescheduleItem?.card.difficulty, historyCard.last?.difficulty)
    }
}
