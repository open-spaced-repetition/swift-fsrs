//
//  FSRSGeneratorParametersV6Tests.swift
//
//  Verifies generatorParameters handles 17-, 19-, and 21-length w correctly:
//  17 → migrates to 19 (legacy v4 → v5, unchanged), 19 stays 19 (v5),
//  21 stays 21 with v6 clamp ranges. Crucially, 19 does NOT auto-migrate to
//  21 — that would silently change short-term stability behavior.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSGeneratorParametersV6Tests {

    @Test func noArgsStaysOnV5() {
        let defaults = FSRSDefaults()
        let p = defaults.generatorParameters()
        #expect(p.w.count == 19)
        #expect(FSRSAlgorithmVersion.detect(p.w) == .v5)
    }

    @Test func v6DefaultPassesThrough() {
        let defaults = FSRSDefaults()
        let p = defaults.generatorParameters(props: .init(w: FSRSDefaults.defaultWv6))
        #expect(p.w.count == 21)
        #expect(FSRSAlgorithmVersion.detect(p.w) == .v6)
        expectClose(p.w[20], FSRSDefaults.FSRS6_DEFAULT_DECAY, 1e-9)
    }

    @Test func legacy17PathUnchanged() {
        let defaults = FSRSDefaults()
        let raw = Array(repeating: 0.5, count: 17)
        let p = defaults.generatorParameters(props: .init(w: raw))
        #expect(p.w.count == 19)
        #expect(FSRSAlgorithmVersion.detect(p.w) == .v5)
    }

    @Test func length19DoesNotAutoMigrateTo21() {
        let defaults = FSRSDefaults()
        let v5w: [Double] = [
            0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575,
            0.1192, 1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655,
            0.6621,
        ]
        let p = defaults.generatorParameters(props: .init(w: v5w))
        #expect(p.w.count == 19)
        #expect(p.w == v5w)
    }

    @Test func v6ClampForcesValidRanges() {
        let defaults = FSRSDefaults()
        var w = FSRSDefaults.defaultWv6
        w[20] = 5.0
        let p = defaults.generatorParameters(props: .init(w: w))
        expectClose(p.w[20], 0.8, 1e-9)

        w[20] = -1.0
        let p2 = defaults.generatorParameters(props: .init(w: w))
        expectClose(p2.w[20], 0.1, 1e-9)
    }

    @Test func sMinIsVersionDispatched() {
        let v5 = FSRS(parameters: .init())
        #expect(v5.sMin == FSRSDefaults.S_MIN)

        let v6 = FSRS(parameters: .init(w: FSRSDefaults.defaultWv6))
        #expect(v6.sMin == FSRSDefaults.S_MIN_V6)
    }

    @Test func ceilingFiniteForOutOfRangeInputs() {
        // w[11] / w[13] feed into log(...) inside computeW17W18Ceiling. Pre-
        // clamping inputs prevents NaN from a hostile `w` (or a tweaked test
        // harness) poisoning the rest of the clamp table.
        var w = FSRSDefaults.defaultWv6
        w[11] = -1.0   // log(w[11]) would be NaN
        w[13] = -0.5   // log(2^w[13] - 1) → log(negative) NaN
        let ceiling = FSRSDefaults.computeW17W18Ceiling(
            parameters: w,
            numRelearningSteps: 2
        )
        #expect(ceiling.isFinite)
        #expect(ceiling >= 0.01)
        #expect(ceiling <= 2.0)
    }

    @Test func malformedLearningStepThrowsOnReview() {
        // Malformed step strings used to be silently swallowed by `try?` in
        // basicLearningStepsStrategy, causing the v6 scheduler to graduate
        // cards immediately. Now they propagate `FSRSError(.invalidParam)`
        // through the throwing review chain.
        let p = FSRSParameters(
            w: FSRSDefaults.defaultWv6,
            learningSteps: ["1m", "bogus"]
        )
        let f = FSRS(parameters: p)
        let card = FSRSDefaults().createEmptyCard()
        let now = Date()
        #expect(throws: FSRSError.self) {
            _ = try f.next(card: card, now: now, grade: .good)
        }
    }

    @Test func factorIsDerivedFromDecayInV6() {
        let v5 = FSRS(parameters: .init())
        expectClose(v5.factor, 19.0 / 81.0, 1e-12)
        #expect(v5.decay == -0.5)

        var w = FSRSDefaults.defaultWv6
        w[20] = 0.5
        let v6Equivalent = FSRS(parameters: .init(w: w))
        expectClose(v6Equivalent.factor, 19.0 / 81.0, 1e-7)
        #expect(v6Equivalent.decay == -0.5)
    }
}
