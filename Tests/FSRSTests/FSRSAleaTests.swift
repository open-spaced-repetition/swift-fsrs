import XCTest
@testable import FSRS

final class FSRSAleaTests: XCTestCase {
    func testExample() throws {
        let prng1 = alea(seed: 1)
        let prng2 = alea(seed: 3)
        let prng3 = alea(seed: 1)
        
        let a = prng1.state()
        let b = prng2.state()
        let c = prng3.state()
        
        XCTAssert(a == c)
        XCTAssert(a != b)
        
        var generator = alea(seed: 12345)
        let v4 = generator.next()
        let v5 = generator.next()
        let v6 = generator.next()
        print([0.27138191112317145, 0.19615925149992108, 0.6810678059700876].debugDescription)
        print([v4, v5, v6].debugDescription)
        XCTAssert([v4, v5, v6].elementsEqual([0.27138191112317145, 0.19615925149992108, 0.6810678059700876]))
        
        generator = alea(seed: "int32test")
        let value = generator.int32()
        XCTAssert(Int(value) <= 0xffffffff)
        XCTAssert(value >= 0)

        generator = alea(seed: 12345)
        let v1 = generator.int32()
        let v2 = generator.int32()
        let v3 = generator.int32()
        print([1165576433, 842497570, -1369803343].debugDescription)
        print([v1, v2, v3].debugDescription)
        XCTAssert([v1, v2, v3].elementsEqual([1165576433, 842497570, -1369803343]))

        generator = alea(seed: "doubletest")
        let value1 = generator.double()
        XCTAssert(value1 < 1)
        XCTAssert(value1 >= 0)
        
        generator = alea(seed: 12345)
        let v7 = generator.double()
        let v8 = generator.double()
        let v9 = generator.double()
        print([0.27138191116884325, 0.6810678062004586, 0.3407802057882554].debugDescription)
        print([v7, v8, v9].debugDescription)
        XCTAssert([v7, v8, v9].elementsEqual([0.27138191116884325, 0.6810678062004586, 0.3407802057882554]))
        
        let prng4 = alea(seed: Double.random(in: 0...1))
        _ = prng4.next()
        _ = prng4.next()
        _ = prng4.next()
        let prng5 = alea()
        prng5.importState(prng4.state())
        XCTAssert(prng4.state() == prng5.state())
        
        for _ in 1...10000 {
            let q = prng4.next()
            let b = prng5.next()
            XCTAssert(q == b)
            XCTAssert(q >= 0)
            XCTAssert(q < 1)
            XCTAssert(b < 1)
        }
        
        generator = alea(seed: "statetest")
        let state1 = generator.state()
        let next1 = generator.next()
        let state2 = generator.state()
        let next2 = generator.next()
        XCTAssert(state1.s0 != state2.s0)
        XCTAssert(state1.s1 != state2.s1)
        XCTAssert(state1.s2 != state2.s2)
        XCTAssert(next1 != next2)
        
        
        generator = alea(seed: 12345)
        generator.importState(.init(c: 0, s0: 0, s1: 0, s2: -0.5))
        let res = generator.next()
        let state3 = generator.state()
        XCTAssert(res == 0)
        XCTAssert(state3 == .init(c: 0, s0: 0, s1: -0.5, s2: 0))
        
        generator = alea(seed: "1727015666066")
        let res1 = generator.next()
        let state4 = generator.state()
        XCTAssert(res1 == 0.6320083506871015)
        XCTAssert(state4 == .init(
            c: 1828249,
            s0: 0.5888567129150033,
            s1: 0.5074866858776659,
            s2: 0.6320083506871015
        ))
        
        generator = alea(seed: "Seedp5fxh9kf4r0")
        let res2 = generator.next()
        let state5 = generator.state()
        XCTAssert(res2 == 0.14867847645655274)
        XCTAssert(state5 == .init(
            c: 1776946,
            s0: 0.6778371171094477,
            s1: 0.0770602801349014,
            s2: 0.14867847645655274
        ))
        
        generator = alea(seed: "NegativeS2Seed")
        let res3 = generator.next()
        let state6 = generator.state()
        XCTAssert(res3 == 0.830770346801728)
        XCTAssert(state6 == .init(
            c: 952982,
            s0: 0.25224833423271775,
            s1: 0.9213257452938706,
            s2: 0.830770346801728
        ))
    }
}
