import RealModule

struct AleaState: Equatable {
    let c: Float64
    let s0: Float64
    let s1: Float64
    let s2: Float64
    
    init(
        c: Float64,
        s0: Float64,
        s1: Float64,
        s2: Float64
    ) {
        self.c = c
        self.s0 = s0
        self.s1 = s1
        self.s2 = s2
    }
    
    init(alea: Alea) {
        self.c = alea.c
        self.s0 = alea.s0
        self.s1 = alea.s1
        self.s2 = alea.s2
    }
}

struct Alea {
    var c: Float64
    var s0: Float64
    var s1: Float64
    var s2: Float64
    
    init(state: AleaState) {
        self.c = state.c
        self.s0 = state.s0
        self.s1 = state.s1
        self.s2 = state.s2
    }
    
    init(
        c: Float64,
        s0: Float64,
        s1: Float64,
        s2: Float64
    ) {
        self.c = c
        self.s0 = s0
        self.s1 = s1
        self.s2 = s2
    }
    
    init(seed: Seed) {
        var mash = Mash()
        let blankSeed = Seed.string(" ")
        var alea = Alea(
            c: 1.0,
            s0: mash.mash(seed: blankSeed),
            s1: mash.mash(seed: blankSeed),
            s2: mash.mash(seed: blankSeed)
        )
        alea.s0 -= mash.mash(seed: seed)
        if alea.s0 < 0 {
            alea.s0 += 1
        }
        alea.s1 -= mash.mash(seed: seed)
        if alea.s1 < 0 {
            alea.s1 += 1
        }
        alea.s2 -= mash.mash(seed: seed)
        if alea.s2 < 0 {
            alea.s2 += 1
        }
        
        self = alea
    }
}

extension Alea: IteratorProtocol {
    mutating func next() -> Float64? {
        let t = Float64._mulAdd(2091639.0, s0, c * twoToThePowerOfMinus32)
        self.s0 = s1
        self.s1 = s2
        self.c = t.rounded(.down)
        self.s2 = t - c
        
        return s2
    }
}

let twoToThePowerOf32: UInt64 = 1 << 32
let twoToThePowerOf21: UInt64 = 1 << 21
let twoToThePowerOfMinus32: Float64 = 1.0 / Float64(twoToThePowerOf32)
let twoToThePowerOfMinus53: Float64 = 1.0 / Float64(UInt64(1 << 53))

struct Mash {
    private var n: Float64
    
    init() {
        let n: UInt64 = 0xefc8249d
        self.n = Float64(n)
    }
    
    mutating func mash(seed: Seed) -> Float64 {
        var n = n
        for c in seed.rawValue {
            n += Float64(c.asciiValue ?? 0)
            var h = 0.02519603282416938 * n
            n = Float64(UInt32(h))
            h -= n
            h *= n
            n = Float64(UInt32(h))
            h -= n
            n += h * Float64(twoToThePowerOf32)
        }
        self.n = n
        return n * twoToThePowerOfMinus32
    }
}

struct Prng {
    var xg: Alea
    
    init(seed: Seed) {
        self.xg = Alea(seed: seed)
    }
    
    mutating func genNext() -> Float64 {
        xg.next()!
    }
    
    mutating func int32() -> Int32 {
        wrapToInt32(input: genNext() * Float64(twoToThePowerOf32))
    }
 
    mutating func double() -> Float64 {
        Float64._mulAdd(
            Float64(UInt64(genNext() * Float64(twoToThePowerOf21))),
            twoToThePowerOfMinus53,
            genNext()
        )
    }
    
    func state() -> AleaState {
        AleaState(alea: xg)
    }
    
    mutating func `import`(state: AleaState) {
        self.xg = Alea(state: state)
    }
}

// The rem_euclid() wraps within a positive range, then casting u32 to i32 makes half of that range negative.
func wrapToInt32(input: Float64) -> Int32 {
    Int32(truncatingIfNeeded: UInt32(input.truncatingRemainder(dividingBy: Float64(UInt32.max) + 1.0)))
}


func alea(seed: Seed) -> Prng {
    switch seed {
    case .string(_):
        return Prng(seed: seed)
    default:
        return Prng(seed: .default)
    }
}
