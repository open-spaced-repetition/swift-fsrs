//
//  FSRSModelEnumStringValueTests.swift
//
//  `CardState.stringValue` and `Rating.stringValue` are public — library users
//  rely on them for logging / UI / persistence. Lock the mapping so future
//  refactors can't silently rename a case.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSModelEnumStringValueTests {

    @Test(arguments: [
        (CardState.new, "new"),
        (CardState.learning, "learning"),
        (CardState.review, "review"),
        (CardState.relearning, "relearning"),
    ])
    func cardStateStringValue(state: CardState, expected: String) {
        #expect(state.stringValue == expected)
    }

    @Test(arguments: [
        (Rating.manual, "manual"),
        (Rating.again, "again"),
        (Rating.hard, "hard"),
        (Rating.good, "good"),
        (Rating.easy, "easy"),
    ])
    func ratingStringValue(rating: Rating, expected: String) {
        #expect(rating.stringValue == expected)
    }

    /// Sanity: every CaseIterable rating must round-trip through stringValue.
    @Test func ratingStringValueIsExhaustive() {
        for rating in Rating.allCases {
            #expect(rating.stringValue.isEmpty == false)
        }
    }
}
