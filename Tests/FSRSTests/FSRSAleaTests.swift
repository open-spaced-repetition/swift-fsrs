//
//  FSRSAleaTests.swift
//
//  Reproducibility tests for the seeded PRNG. Oracle values match alea.js so
//  fuzz output is bit-comparable across the JS/Swift implementations.
//

import Foundation
import Testing
@testable import FSRS

@Suite struct FSRSAleaTests {

    @Test func sameSeedProducesSameState() {
        let prng1 = alea(seed: 1)
        let prng2 = alea(seed: 3)
        let prng3 = alea(seed: 1)

        let a = prng1.state()
        let b = prng2.state()
        let c = prng3.state()

        #expect(a == c)
        #expect(a != b)
    }

    @Test func nextProducesKnownDoubleSequence() {
        let generator = alea(seed: 12345)
        let v4 = generator.next()
        let v5 = generator.next()
        let v6 = generator.next()
        #expect([v4, v5, v6] == [0.27138191112317145, 0.19615925149992108, 0.6810678059700876])
    }

    @Test func int32IsBoundedAndReproducible() {
        var generator = alea(seed: "int32test")
        let value = generator.int32()
        #expect(Int(value) <= 0xffffffff)
        #expect(value >= 0)

        generator = alea(seed: 12345)
        let v1 = generator.int32()
        let v2 = generator.int32()
        let v3 = generator.int32()
        #expect([v1, v2, v3] == [1165576433, 842497570, -1369803343])
    }

    @Test func doubleIsBoundedAndReproducible() {
        var generator = alea(seed: "doubletest")
        let value = generator.double()
        #expect(value < 1)
        #expect(value >= 0)

        generator = alea(seed: 12345)
        let v7 = generator.double()
        let v8 = generator.double()
        let v9 = generator.double()
        #expect([v7, v8, v9] == [0.27138191116884325, 0.6810678062004586, 0.3407802057882554])
    }

    @Test func importStateClonesGenerator() {
        let prng4 = alea(seed: Double.random(in: 0...1))
        _ = prng4.next()
        _ = prng4.next()
        _ = prng4.next()
        let prng5 = alea()
        prng5.importState(prng4.state())
        #expect(prng4.state() == prng5.state())

        for _ in 1...10000 {
            let q = prng4.next()
            let b = prng5.next()
            #expect(q == b)
            #expect(q >= 0)
            #expect(q < 1)
            #expect(b < 1)
        }
    }

    @Test func stateAdvancesAfterNext() {
        let generator = alea(seed: "statetest")
        let state1 = generator.state()
        let next1 = generator.next()
        let state2 = generator.state()
        let next2 = generator.next()
        #expect(state1.s0 != state2.s0)
        #expect(state1.s1 != state2.s1)
        #expect(state1.s2 != state2.s2)
        #expect(next1 != next2)
    }

    @Test func zeroStateProducesZero() {
        let generator = alea(seed: 12345)
        generator.importState(.init(c: 0, s0: 0, s1: 0, s2: -0.5))
        let res = generator.next()
        let state3 = generator.state()
        #expect(res == 0)
        #expect(state3 == .init(c: 0, s0: 0, s1: -0.5, s2: 0))
    }

    /// Regression cases for specific named seeds. Oracle values from alea.js.
    @Test(arguments: [
        ("1727015666066",    0.6320083506871015, 1828249, 0.5888567129150033, 0.5074866858776659, 0.6320083506871015),
        ("Seedp5fxh9kf4r0",  0.14867847645655274, 1776946, 0.6778371171094477, 0.0770602801349014, 0.14867847645655274),
        ("NegativeS2Seed",   0.830770346801728,   952982, 0.25224833423271775, 0.9213257452938706, 0.830770346801728),
    ])
    func reproducesNamedSeed(seed: String, expectedNext: Double, c: Int, s0: Double, s1: Double, s2: Double) {
        let generator = alea(seed: seed)
        let res = generator.next()
        let state = generator.state()
        #expect(res == expectedNext)
        #expect(state == FSRSAlea.State(c: c, s0: s0, s1: s1, s2: s2))
    }
}
