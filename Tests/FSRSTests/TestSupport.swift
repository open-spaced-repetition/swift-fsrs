//
//  TestSupport.swift
//  FSRS
//
//  Shared helpers for the Swift Testing suite. `expectClose` replaces the
//  XCTest `XCTAssertEqual(_, _, accuracy:)` form with `<=` semantics
//  (matching XCTest's tolerance behavior).
//

import Foundation
import Testing

func expectClose(
    _ a: Double,
    _ b: Double,
    _ eps: Double = 1e-7,
    _ comment: Comment? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(abs(a - b) <= eps, comment, sourceLocation: sourceLocation)
}

let utcCalendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(secondsFromGMT: 0)!
    return c
}()
