//
//  FSRSGeneratorParametersV6Tests.swift
//
//  Verifies generatorParameters handles 17-, 19-, and 21-length w correctly:
//  17 → migrates to 19 (legacy v4 → v5, unchanged), 19 stays 19 (v5),
//  21 stays 21 with v6 clamp ranges. Crucially, 19 does NOT auto-migrate to
//  21 — that would silently change short-term stability behavior.
//

import XCTest
@testable import FSRS

final class FSRSGeneratorParametersV6Tests: XCTestCase {

    func testNoArgsStaysOnV5() {
        let defaults = FSRSDefaults()
        let p = defaults.generatorParameters()
        XCTAssertEqual(p.w.count, 19)
        XCTAssertEqual(FSRSAlgorithmVersion.detect(p.w), .v5)
    }

    func testV6DefaultPassesThrough() {
        let defaults = FSRSDefaults()
        let p = defaults.generatorParameters(props: .init(w: FSRSDefaults.defaultWv6))
        XCTAssertEqual(p.w.count, 21)
        XCTAssertEqual(FSRSAlgorithmVersion.detect(p.w), .v6)
        // Last weight is the decay default.
        XCTAssertEqual(p.w[20], FSRSDefaults.FSRS6_DEFAULT_DECAY, accuracy: 1e-9)
    }

    func testLegacy17PathUnchanged() {
        // 17-length input still migrates to 19 (v5), as before.
        let defaults = FSRSDefaults()
        let raw = Array(repeating: 0.5, count: 17)
        let p = defaults.generatorParameters(props: .init(w: raw))
        XCTAssertEqual(p.w.count, 19)
        XCTAssertEqual(FSRSAlgorithmVersion.detect(p.w), .v5)
    }

    func test19LengthDoesNotAutoMigrateTo21() {
        // Legacy v5 weights stay 19 — no silent v6 migration.
        let defaults = FSRSDefaults()
        let v5w: [Double] = [
            0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575,
            0.1192, 1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655,
            0.6621,
        ]
        let p = defaults.generatorParameters(props: .init(w: v5w))
        XCTAssertEqual(p.w.count, 19)
        XCTAssertEqual(p.w, v5w)
    }

    func testV6ClampForcesValidRanges() {
        // Out-of-range w[20] should clamp into [0.1, 0.8].
        let defaults = FSRSDefaults()
        var w = FSRSDefaults.defaultWv6
        w[20] = 5.0  // way above 0.8
        let p = defaults.generatorParameters(props: .init(w: w))
        XCTAssertEqual(p.w[20], 0.8, accuracy: 1e-9)

        w[20] = -1.0  // below 0.1
        let p2 = defaults.generatorParameters(props: .init(w: w))
        XCTAssertEqual(p2.w[20], 0.1, accuracy: 1e-9)
    }

    func testSMinIsVersionDispatched() {
        let v5 = FSRS(parameters: .init())
        XCTAssertEqual(v5.sMin, FSRSDefaults.S_MIN)

        let v6 = FSRS(parameters: .init(w: FSRSDefaults.defaultWv6))
        XCTAssertEqual(v6.sMin, FSRSDefaults.S_MIN_V6)
    }

    func testFactorIsDerivedFromDecayInV6() {
        let v5 = FSRS(parameters: .init())
        XCTAssertEqual(v5.factor, 19.0 / 81.0, accuracy: 1e-12)
        XCTAssertEqual(v5.decay, -0.5)

        // v6 with w[20] = 0.5 should produce v5's exact factor (mathematical fixed point).
        var w = FSRSDefaults.defaultWv6
        w[20] = 0.5
        let v6Equivalent = FSRS(parameters: .init(w: w))
        XCTAssertEqual(v6Equivalent.factor, 19.0 / 81.0, accuracy: 1e-7)
        XCTAssertEqual(v6Equivalent.decay, -0.5)
    }
}
