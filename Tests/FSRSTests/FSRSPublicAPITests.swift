import Foundation
import Testing
import FSRS

@Suite struct FSRSPublicAPITests {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func readmeSampleSchedulesNewCard() throws {
        let v6 = FSRS(parameters: .init(w: FSRSDefaults.defaultWv6))
        let card = FSRSDefaults().createEmptyCard(now: now)
        #expect(card.state == .new)
        #expect(card.due == now)

        let next = try v6.next(card: card, now: now, grade: .good).card
        #expect(next.state == .learning)
    }

    @Test func createEmptyCardAppliesAfterHandler() {
        let later = now.addingTimeInterval(60)
        let card = FSRSDefaults().createEmptyCard(now: now) { card in
            var card = card
            card.due = later
            return card
        }
        #expect(card.due == later)
    }

    @Test func rescheduleAcceptsPublicOptionsAndExposesResult() throws {
        let f = FSRS(parameters: .init())
        let first = try f.next(card: FSRSDefaults().createEmptyCard(now: now), now: now, grade: .good)

        var options = RescheduleOptions(skipManual: false, now: now.addingTimeInterval(86_400))
        options.updateMemoryState = true
        options.firstCard = FSRSDefaults().createEmptyCard(now: now)

        let result = try f.reschedule(currentCard: first.card, reviews: [first.log], options: options)
        #expect(result.collections.count == 1)
        #expect(result.collections.first??.card == first.card)
        #expect(result.rescheduleItem == nil)
    }

    @Test func thrownErrorExposesReasonAndMessage() {
        let f = FSRS(parameters: .init())
        let card = FSRSDefaults().createEmptyCard(now: now)
        let err = #expect(throws: FSRSError.self) {
            _ = try f.next(card: card, now: now, grade: .manual)
        }
        #expect(err?.errorReason == .invalidRating)
        #expect(err?.message == "Cannot review a manual rating")
    }
}
