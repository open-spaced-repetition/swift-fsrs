//
//  FSRSAlea.swift
//
//  Created by nkq on 10/13/24.
//

import Foundation
import JavaScriptCore

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
        let mash = MashWrapper()
        c = 1
        s0 = mash.do(" ")
        s1 = mash.do(" ")
        s2 = mash.do(" ")

        let seedValue: String = String(describing: seed ?? Date().timeIntervalSince1970)
        s0 -= mash.do(seedValue)
        if s0 < 0 { s0 += 1 }
        s1 -= mash.do(seedValue)
        if s1 < 0 { s1 += 1 }
        s2 -= mash.do(seedValue)
        if s2 < 0 { s2 += 1 }
    }

    func next() -> Double {
        let t = 2091639 * s0 + Double(c) * 2.3283064365386963e-10 // 2^-32
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

struct MashWrapper {
    var helper: JSContext? = {
        let context = JSContext()
        context?.exceptionHandler = {
            print($0.debugDescription)
            print($1.debugDescription)
        }
        context?.evaluateScript(
"""
function Mash() {
    let n = 0xefc8249d;
    return function mash(data) {
        data = String(data);
        for (let i = 0; i < data.length; i++) {
            n += data.charCodeAt(i);
            let h = 0.02519603282416938 * n;
            n = h >>> 0;
            h -= n;
            h *= n;
            n = h >>> 0;
            h -= n;
            n += h * 0x100000000; // 2^32
        }
        return (n >>> 0) * 2.3283064365386963e-10; // 2^-32
    }
}
const mash = Mash()
"""
        )
        return context
    }()

    func `do`(_ data: String) -> Double {
        let value = helper?.evaluateScript(
            "mash('\(data)')"
        )
        return value?.toDouble() ?? 0
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
        Int32(truncatingIfNeeded: Int(alea.next() * Double(0x100000000)))
    }

    func double() -> Double {
        next() + Double(UInt(next() * 0x200000)) * 1.1102230246251565e-16 // 2^-53
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

