//
//  FSRSDefaultTests.swift
//  FSRS
//
//  Created by nkq on 10/19/24.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSDefaultTests {
    @Test func defaultParams() {
        let expectedW = [
            0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575,
            0.1192, 1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655,
            0.6621,
        ]
        let defaults = FSRSDefaults()
        #expect(defaults.defaultRequestRetention == 0.9)
        #expect(defaults.defaultMaximumInterval == 36500)
        #expect(defaults.defaultEnableFuzz == false)
        #expect(defaults.defaultW.count == expectedW.count)
        #expect(defaults.defaultW == expectedW)

        let params = defaults.generatorParameters()
        #expect(params.requestRetention == defaults.defaultRequestRetention)
        #expect(params.maximumInterval == defaults.defaultMaximumInterval)
        #expect(params.w == expectedW)
        #expect(params.enableFuzz == defaults.defaultEnableFuzz)

        let params2 = defaults.generatorParameters(props: .init(w: [
            0.4, 0.6, 2.4, 5.8, 4.93, 0.94, 0.86, 0.01, 1.49, 0.14, 0.94, 2.18,
            0.05, 0.34, 1.26, 0.29, 2.61,
        ]))

        #expect(params2.w == [
            0.4, 0.6, 2.4, 5.8, 6.81, 0.44675014, 1.36, 0.01, 1.49, 0.14, 0.94, 2.18,
            0.05, 0.34, 1.26, 0.29, 2.61, 0.0, 0.0,
        ])

        var w = Array(repeating: 0.0, count: 19)
        var paramsClamp = defaults.generatorParameters(props: .init(w: w))
        let w_min = FSRSDefaults.CLAMP_PARAMETERS.map({ $0[0] })
        #expect(paramsClamp.w == w_min)

        w = Array(repeating: .infinity, count: 19)
        paramsClamp = defaults.generatorParameters(props: .init(w: w))
        let w_max = FSRSDefaults.CLAMP_PARAMETERS.map({ $0[1] })
        #expect(paramsClamp.w == w_max)
    }

    @Test func defaultCard() {
        let times = [Date(), Date(timeIntervalSince1970: 1696291200)]
        for now in times {
            let card = FSRSDefaults().createEmptyCard(now: now)
            #expect(card.due == now)
            #expect(card.stability == 0)
            #expect(card.difficulty == 0)
            #expect(card.elapsedDays == 0)
            #expect(card.scheduledDays == 0)
            #expect(card.reps == 0)
            #expect(card.lapses == 0)
            #expect(card.state.rawValue == 0)
        }
    }

    @Test(arguments: [16, 18, 20, 22])
    func unsupportedWLengthFallsBackToDefault(length: Int) {
        // The migration switch in `generatorParameters` only knows 17 / 19 / 21
        // lengths. Anything else hits the `default: break` branch, leaving the
        // pre-loaded `defaultW` (19-length) in place — silently substituted.
        let raw = Array(repeating: 0.5, count: length)
        let defaults = FSRSDefaults()
        let p = defaults.generatorParameters(props: .init(w: raw))
        #expect(p.w.count == 19)
        #expect(FSRSAlgorithmVersion.detect(p.w) == .v5)
    }
}
