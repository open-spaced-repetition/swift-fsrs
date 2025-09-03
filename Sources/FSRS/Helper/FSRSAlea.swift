//
//  FSRSAlea.swift
//
//  Created by nkq on 10/13/24.
//

import Foundation

class FSRSAlea {
    struct State: Equatable {
        var c: Int
        var s0: Double
        var s1: Double
        var s2: Double
    }

    private var c: Int
    private var s0: Double
    private var s1: Double
    private var s2: Double

    init(seed: Any? = nil) {
        var mash = MashWrapper()
        c = 1
        s0 = mash.do(" ")
        s1 = mash.do(" ")
        s2 = mash.do(" ")

        let seedValue: String = String(
            describing: seed ?? Date().timeIntervalSince1970
        )
        s0 -= mash.do(seedValue)
        if s0 < 0 { s0 += 1 }
        s1 -= mash.do(seedValue)
        if s1 < 0 { s1 += 1 }
        s2 -= mash.do(seedValue)
        if s2 < 0 { s2 += 1 }
    }

    func next() -> Double {
        let t = 2_091_639 * s0 + Double(c) * 2.3283064365386963e-10  // 2^-32
        s0 = s1
        s1 = s2
        c = Int(floor(t))
        s2 = t - floor(t)
        return s2
    }

    var state: State {
        get {
            State(c: c, s0: s0, s1: s1, s2: s2)
        }
        set {
            c = newValue.c
            s0 = newValue.s0
            s1 = newValue.s1
            s2 = newValue.s2
        }
    }
}

// Pure Swift implementation of the Alea Mash function (JS-free)
struct MashWrapper {
    // Internal 53-bit floating state mirroring JS number behavior
    private var n: Double = 0xEFC8_249D as Double  // 0xefc8249d

    // Convert a Double to JS ToUint32 result as Double (0..2^32-1)
    @inline(__always)
    private func toUint32(_ x: Double) -> Double {
        if !x.isFinite { return 0 }
        var r = fmod(x, 4294967296.0)  // 2^32
        if r < 0 { r += 4294967296.0 }
        return floor(r)
    }

    // Match JS String.charCodeAt over UTF-16 code units
    private func utf16Codes(_ s: String) -> [UInt16] {
        Array(s.utf16)
    }

    // Returns a double in [0,1) like the JS mash
    mutating func `do`(_ data: String) -> Double {
        // Coerce to String like JS does
        let str = String(data)
        for code in utf16Codes(str) {
            n += Double(code)
            var h = 0.02519603282416938 * n
            n = toUint32(h)
            h -= n
            h *= n
            n = toUint32(h)
            h -= n
            n += h * 4294967296.0  // 2^32
        }
        return toUint32(n) * 2.3283064365386963e-10  // 2^-32
    }
}

protocol PRNG {
    func next() -> Double
    func int32() -> Int32
    func double() -> Double
    func state() -> FSRSAlea.State
    func importState(_ state: FSRSAlea.State)
}

struct RandomNumberGeneratorWrapper: PRNG {
    private let alea: FSRSAlea

    init(seed: Any? = nil) {
        alea = FSRSAlea(seed: seed)
    }

    func next() -> Double {
        alea.next()
    }

    func int32() -> Int32 {
        Int32(truncatingIfNeeded: Int(alea.next() * Double(0x1_0000_0000)))
    }

    func double() -> Double {
        next() + Double(UInt(next() * 0x200000)) * 1.1102230246251565e-16  // 2^-53
    }

    func state() -> FSRSAlea.State {
        alea.state
    }

    func importState(_ state: FSRSAlea.State) {
        alea.state = state
    }
}

func alea(seed: Any? = nil) -> RandomNumberGeneratorWrapper {
    RandomNumberGeneratorWrapper(seed: seed)
}
