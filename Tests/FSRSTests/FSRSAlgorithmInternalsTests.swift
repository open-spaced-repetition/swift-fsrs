//
//  FSRSAlgorithmInternalsTests.swift
//
//  Direct coverage of FSRSAlgorithm.nextState error paths and the
//  computeIntervalModifier fallback for invalid retention values.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSAlgorithmInternalsTests {

    @Test func nextStateRejectsNegativeDeltaT() {
        let algo = FSRS(parameters: .init(w: FSRSDefaults.defaultWv6))
        let memory = FSRSState(stability: 5.0, difficulty: 5.0)
        let err = #expect(throws: FSRSError.self) {
            _ = try algo.nextState(memoryState: memory, t: -1, g: .good)
        }
        #expect(err?.errorReason == .invalidDeltaT)
    }

    @Test func nextStateRejectsDifficultyBelowOne() {
        let algo = FSRS(parameters: .init(w: FSRSDefaults.defaultWv6))
        // difficulty < 1 with non-zero stability triggers the .invalidParam guard
        let memory = FSRSState(stability: 5.0, difficulty: 0.5)
        let err = #expect(throws: FSRSError.self) {
            _ = try algo.nextState(memoryState: memory, t: 1, g: .good)
        }
        #expect(err?.errorReason == .invalidParam)
    }

    @Test func nextStateRejectsStabilityBelowSMin() {
        let algo = FSRS(parameters: .init(w: FSRSDefaults.defaultWv6))
        // Stability below v6's sMin (0.001) with difficulty >= 1.
        let memory = FSRSState(stability: 1e-5, difficulty: 5.0)
        let err = #expect(throws: FSRSError.self) {
            _ = try algo.nextState(memoryState: memory, t: 1, g: .good)
        }
        #expect(err?.errorReason == .invalidParam)
    }

    @Test func nextStateAllowsManualOnExistingMemory() throws {
        // Sanity: manual rating on an existing memory state is a no-op pass-through,
        // not an error — guards previously rejected this incorrectly.
        let algo = FSRS(parameters: .init(w: FSRSDefaults.defaultWv6))
        let memory = FSRSState(stability: 5.0, difficulty: 5.0)
        let result = try algo.nextState(memoryState: memory, t: 1, g: .manual)
        #expect(result.stability == 5.0)
        #expect(result.difficulty == 5.0)
    }

    @Test(arguments: [1.5, 2.0, -0.1, 0.0])
    func intervalModifierFallbackForOutOfRangeRetention(retention: Double) {
        // r outside (0, 1] — the algorithm logs and falls through to modifier=1.
        let algo = FSRS(parameters: .init(requestRetention: retention))
        #expect(algo.intervalModifier == 1)
    }

    @Test func intervalModifierFallbackForNonFiniteRetention() {
        let nan = FSRS(parameters: .init(requestRetention: .nan))
        #expect(nan.intervalModifier == 1)

        let inf = FSRS(parameters: .init(requestRetention: .infinity))
        #expect(inf.intervalModifier == 1)
    }
}
