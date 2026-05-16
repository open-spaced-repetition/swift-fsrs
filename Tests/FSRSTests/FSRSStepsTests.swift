//
//  FSRSStepsTests.swift
//
//  Edge cases for the public `convertStepUnitToMinutes` parser. Happy-path
//  conversion is covered indirectly by the v6 scheduler tests; these tests
//  exercise the malformed-input branches.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSStepsTests {

    @Test func emptyStringThrows() {
        let err = #expect(throws: FSRSError.self) {
            _ = try convertStepUnitToMinutes("")
        }
        #expect(err?.errorReason == .invalidParam)
    }

    @Test func unknownUnitSuffixThrows() {
        // "5x" passes the numeric check (Int("5") succeeds) but "x" is not
        // m/h/d, so we hit the switch's default branch.
        let err = #expect(throws: FSRSError.self) {
            _ = try convertStepUnitToMinutes("5x")
        }
        #expect(err?.errorReason == .invalidParam)
    }

    @Test func invalidValuePartThrows() {
        // "bogus" — the leading characters can't parse as Int.
        let err = #expect(throws: FSRSError.self) {
            _ = try convertStepUnitToMinutes("bogus")
        }
        #expect(err?.errorReason == .invalidParam)
    }

    @Test(arguments: [
        ("1m", 1),
        ("10m", 10),
        ("1h", 60),
        ("2h", 120),
        ("1d", 1440),
        ("3d", 4320),
        ("0m", 0),
    ])
    func happyPath(input: String, expectedMinutes: Int) throws {
        #expect(try convertStepUnitToMinutes(input) == expectedMinutes)
    }
}
