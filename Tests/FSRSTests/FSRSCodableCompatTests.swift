//
//  FSRSCodableCompatTests.swift
//
//  Backward-compat: legacy v5 JSON (no `learningSteps` key) must still
//  decode after the v6 model evolution. These tests guard the
//  decodeIfPresent strategy in Card / ReviewLog / FSRSParameters.
//

import XCTest
@testable import FSRS

final class FSRSCodableCompatTests: XCTestCase {

    private func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    // MARK: - Card

    func testLegacyCardJSONDecodes() throws {
        let json = """
        {
          "due": "2025-01-01T00:00:00Z",
          "stability": 1.5,
          "difficulty": 4.2,
          "elapsedDays": 0,
          "scheduledDays": 0,
          "reps": 0,
          "lapses": 0,
          "state": 0
        }
        """.data(using: .utf8)!

        let card = try decoder().decode(Card.self, from: json)
        XCTAssertEqual(card.stability, 1.5)
        XCTAssertEqual(card.difficulty, 4.2)
        XCTAssertEqual(card.learningSteps, 0, "Missing learningSteps must default to 0")
        XCTAssertEqual(card.state, .new)
    }

    func testCurrentCardJSONRoundTrips() throws {
        let card = Card(
            due: Date(timeIntervalSince1970: 1_700_000_000),
            stability: 2.5,
            difficulty: 5.0,
            elapsedDays: 3,
            scheduledDays: 7,
            learningSteps: 1,
            reps: 4,
            lapses: 1,
            state: .review,
            lastReview: Date(timeIntervalSince1970: 1_699_000_000)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(card)
        let decoded = try decoder().decode(Card.self, from: data)
        XCTAssertEqual(card, decoded)
    }

    // MARK: - ReviewLog

    func testLegacyReviewLogJSONDecodes() throws {
        let json = """
        {
          "rating": 3,
          "elapsedDays": 1,
          "lastElapsedDays": 0,
          "scheduledDays": 4,
          "review": "2025-01-02T00:00:00Z"
        }
        """.data(using: .utf8)!

        let log = try decoder().decode(ReviewLog.self, from: json)
        XCTAssertEqual(log.rating, .good)
        XCTAssertEqual(log.learningSteps, 0)
    }

    // MARK: - FSRSParameters

    func testLegacyParametersJSONDecodes() throws {
        // Caller stored params from before v6 — no learningSteps/relearningSteps
        // in the JSON. Should decode using FSRSDefaults values for those.
        let json = """
        {
          "requestRetention": 0.9,
          "maximumInterval": 36500,
          "w": [0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575, 0.1192, 1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655, 0.6621],
          "enableFuzz": false,
          "enableShortTerm": true
        }
        """.data(using: .utf8)!

        let params = try decoder().decode(FSRSParameters.self, from: json)
        XCTAssertEqual(params.w.count, 19, "Legacy v5 weights preserved")
        XCTAssertEqual(params.learningSteps, FSRSDefaults.defaultLearningSteps)
        XCTAssertEqual(params.relearningSteps, FSRSDefaults.defaultRelearningSteps)

        // And v5 path still resolves to v5 algorithm.
        let f = FSRS(parameters: params)
        XCTAssertEqual(f.version, .v5)
    }
}
