//
//  FSRSShowDiffMessageTests.swift
//  FSRS
//
//  Created by nkq on 10/27/24.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct ShowDiffMessageTests {

    static let timeUnitFormatTest = ["秒", "分", "小时", "天", "个月", "年"]

    struct DiffCase: Sendable {
        let later: Date
        let earlier: Date
        let abbreviate: Bool
        let units: [String]?
        let expected: String
        let invert: Bool  // true => assert NotEqual

        static func eq(_ later: Date, _ earlier: Date, _ abbr: Bool, _ units: [String]? = nil, _ expected: String) -> DiffCase {
            DiffCase(later: later, earlier: earlier, abbreviate: abbr, units: units, expected: expected, invert: false)
        }
        static func neq(_ later: Date, _ earlier: Date, _ abbr: Bool, _ units: [String]? = nil, _ expected: String) -> DiffCase {
            DiffCase(later: later, earlier: earlier, abbreviate: abbr, units: units, expected: expected, invert: true)
        }
    }

    private static func runCase(_ c: DiffCase, sourceLocation: SourceLocation = #_sourceLocation) {
        let actual: String = {
            if let units = c.units {
                return Date.showDiffMessage(c.later, c.earlier, c.abbreviate, units)
            }
            return Date.showDiffMessage(c.later, c.earlier, c.abbreviate)
        }()
        if c.invert {
            #expect(actual != c.expected, sourceLocation: sourceLocation)
        } else {
            #expect(actual == c.expected, sourceLocation: sourceLocation)
        }
    }

    @Test func badType() {
        let t1 = Date.fromString("1970-01-01 00:00:00")!
        let t2 = Date.fromString("1970-01-02 00:00:00")!
        let t3 = Date.fromString("1970-01-01 00:00:00")!
        let t4 = Date.fromString("1970-01-02 00:00:00")!
        let t5 = Date(timeIntervalSince1970: 0)
        let t6 = Date(timeIntervalSince1970: 60 * 60 * 24)

        let cases: [DiffCase] = [
            .eq(t2, t1, false, nil, "1"),
            .eq(t2, t1, true,  nil, "1day"),
            .eq(t2, t1, true,  Self.timeUnitFormatTest, "1天"),
            .eq(t4, t3, false, nil, "1"),
            .eq(t4, t3, true,  nil, "1day"),
            .eq(t4, t3, true,  Self.timeUnitFormatTest, "1天"),
            .eq(t6, t5, false, nil, "1"),
            .eq(t6, t5, true,  nil, "1day"),
            .eq(t6, t5, true,  Self.timeUnitFormatTest, "1天"),
        ]
        cases.forEach { Self.runCase($0) }
    }

    @Test func minutes() {
        let t1 = Date()
        let t2 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60)
        let t3 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 59)

        let cases: [DiffCase] = [
            .eq(t2, t1, false, nil, "1"),
            .eq(t2, t1, true,  nil, "1min"),
            .eq(t2, t1, true,  Self.timeUnitFormatTest, "1分"),
            .eq(t3, t1, true,  nil, "59min"),
            .eq(t3, t1, true,  Self.timeUnitFormatTest, "59分"),
        ]
        cases.forEach { Self.runCase($0) }
    }

    @Test func hours() {
        let t1 = Date()
        let t2 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60)
        let t3 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 59)

        let cases: [DiffCase] = [
            .eq(t2, t1, false, nil, "1"),
            .eq(t2, t1, true,  nil, "1hour"),
            .eq(t2, t1, true,  Self.timeUnitFormatTest, "1小时"),
            .neq(t3, t1, true,  nil, "59hour"),
            .neq(t3, t1, true,  Self.timeUnitFormatTest, "59小时"),
            .eq(t3, t1, true,  nil, "2day"),
            .eq(t3, t1, true,  Self.timeUnitFormatTest, "2天"),
        ]
        cases.forEach { Self.runCase($0) }
    }

    @Test func days() {
        let t1 = Date()
        let t2 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24)
        let t3 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 30)
        let t4 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31)

        let cases: [DiffCase] = [
            .eq(t2, t1, false, nil, "1"),
            .eq(t2, t1, true,  nil, "1day"),
            .eq(t2, t1, true,  Self.timeUnitFormatTest, "1天"),
            .eq(t3, t1, false, nil, "30"),
            .eq(t3, t1, true,  nil, "30day"),
            .eq(t3, t1, true,  Self.timeUnitFormatTest, "30天"),
            .neq(t4, t1, false, nil, "31"),
            .eq(t4, t1, true,  nil, "1month"),
            .eq(t4, t1, true,  Self.timeUnitFormatTest, "1个月"),
        ]
        cases.forEach { Self.runCase($0) }
    }

    @Test func months() {
        let t1 = Date()
        let t2 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31)
        let t3 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31 * 12)
        let t4 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31 * 13)

        let cases: [DiffCase] = [
            .eq(t2, t1, false, nil, "1"),
            .eq(t2, t1, true,  nil, "1month"),
            .eq(t2, t1, true,  Self.timeUnitFormatTest, "1个月"),
            .neq(t3, t1, false, nil, "12"),
            .neq(t3, t1, true,  nil, "12month"),
            .neq(t3, t1, true,  Self.timeUnitFormatTest, "12个月"),
            .neq(t4, t1, false, nil, "13"),
            .eq(t4, t1, true,  nil, "1year"),
            .eq(t4, t1, true,  Self.timeUnitFormatTest, "1年"),
        ]
        cases.forEach { Self.runCase($0) }
    }

    @Test func years() {
        let t1 = Date()
        let t2 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31 * 13)
        let t3 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31 * 13 + 60 * 60 * 24)
        let t4 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31 * 24 + 60 * 60 * 24)

        let cases: [DiffCase] = [
            .eq(t2, t1, false, nil, "1"),
            .eq(t2, t1, true,  nil, "1year"),
            .eq(t2, t1, true,  Self.timeUnitFormatTest, "1年"),
            .eq(t3, t1, false, nil, "1"),
            .eq(t3, t1, true,  nil, "1year"),
            .eq(t3, t1, true,  Self.timeUnitFormatTest, "1年"),
            .eq(t4, t1, false, nil, "2"),
            .eq(t4, t1, true,  nil, "2year"),
            .eq(t4, t1, true,  Self.timeUnitFormatTest, "2年"),
        ]
        cases.forEach { Self.runCase($0) }
    }

    @Test func wrongTimeUnitLength() {
        let timeUnitFormatTestShort = ["年"]
        let t1 = Date()
        let t2 = Date(timeIntervalSince1970: t1.timeIntervalSince1970 + 60 * 60 * 24 * 31 * 13)

        let cases: [DiffCase] = [
            .eq(t2, t1, false, nil, "1"),
            .eq(t2, t1, true,  nil, "1year"),
            .neq(t2, t1, true,  timeUnitFormatTestShort, "1年"),
            .eq(t2, t1, true,   timeUnitFormatTestShort, "1year"),
        ]
        cases.forEach { Self.runCase($0) }
    }
}
