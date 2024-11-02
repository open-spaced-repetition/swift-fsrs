import Foundation
import RealModule

public typealias Weights = [Float64]

public struct Parameters {
    public internal(set) var requestRetention: Float64
    public internal(set) var maximumInterval: Int32
    public internal(set) var w: Weights
    public internal(set) var decay: Float64
    public internal(set) var factor: Float64
    public internal(set) var isShortTermEnabled: Bool
    public internal(set) var isFuzzEnabled: Bool
    public internal(set) var seed: Seed
    
    public init(
        requestRetention: Float64 = 0.9,
        maximumInterval: Int32 = 36500,
        w: Weights = Self.defaultWeight,
        decay: Float64 = Self.defaultDecay,
        factor: Float64 = Self.defaultFactor,
        isShortTermEnabled: Bool = true,
        isFuzzEnabled: Bool = false,
        seed: Seed = .default
    ) {
        self.requestRetention = requestRetention
        self.maximumInterval = maximumInterval
        self.w = w
        self.decay = decay
        self.factor = factor
        self.isShortTermEnabled = isShortTermEnabled
        self.isFuzzEnabled = isFuzzEnabled
        self.seed = seed
    }
    
    @usableFromInline
    static let defaultWeight: Weights = [
        0.4072, 1.1829, 3.1262, 15.4722, 7.2102, 0.5316, 1.0651, 0.0234, 1.616, 0.1544, 1.0824, 1.9813,
        0.0953, 0.2975, 2.2042, 0.2407, 2.9466, 0.5034, 0.6567,
    ]
    
    @usableFromInline
    static let defaultDecay: Float64 = -0.5
    
    @usableFromInline
    static let defaultFactor: Float64 = 19.0 / 81.0
}

extension Parameters {
    static func forgettingCurve(elapsedDays: Float64, stability: Float64) -> Float64 {
        .pow(1.0 + defaultFactor * elapsedDays / stability, defaultDecay)
    }
    
    func initDifficulty(rating: Rating) -> Float64 {
        let rating = rating.rawValue
        let value = w[4] - .exp(w[5] * (Float64(rating) - 1.0)) + 1.0
        return (1.0...10.0).clamp(value)
    }
    
    func initStability(rating: Rating) -> Float64 {
        let rating = rating.rawValue
        return max(w[rating - 1], 0.1)
    }
    
    func nextInterval(stability: Float64, elapsedDays: Int64) -> Float64 {
        let newInterval = (stability / factor * (.pow(requestRetention, 1.0 / decay) - 1.0))
            .rounded()
        let clamped = (1.0...Float64(maximumInterval)).clamp(newInterval)
        return applyFuzz(interval: clamped, elapsedDays: elapsedDays)
    }
    
    func nextDifficulty(difficulty: Float64, rating: Rating) -> Float64 {
        let rating = rating.rawValue
        let nextDifficulty = Float64._mulAdd(w[6], -(Float64(rating) - 3.0), difficulty)
        let reversion = meanReversion(initial: initDifficulty(rating: .easy), current: nextDifficulty)
        return (1.0...10.0).clamp(reversion)
    }
    
    func shortTermStability(stability: Float64, rating: Rating) -> Float64 {
        let rating = rating.rawValue
        return stability * .exp(w[17] * (Float64(rating) - 3.0 + w[18]))
    }
    
    func nextRecallStability(
        difficulty: Float64,
        stability: Float64,
        retrievability: Float64,
        rating: Rating
    ) -> Float64 {
        let modifier = switch rating {
        case .hard: w[15]
        case .easy: w[16]
        default: 1.0
        }
        
        return stability * ._mulAdd(
            .exp(w[8])
                * (11.0 - difficulty)
                * .pow(stability, -w[9])
                * .expMinusOne((1 - retrievability) * w[10]),
            modifier,
            1.0
        )
    }
    
    func nextForgetStability(
        difficulty: Float64,
        stability: Float64,
        retrievability: Float64
    ) -> Float64 {
        w[11]
            * .pow(difficulty, -w[12])
            * (.pow(stability + 1.0, w[13]) - 1.0)
            * .exp((1.0 - retrievability) * w[14])
    }
    
    private func meanReversion(initial: Float64, current: Float64) -> Float64 {
        ._mulAdd(w[7], initial, (1.0 - w[7]) * current)
    }
    
    private func applyFuzz(interval: Float64, elapsedDays: Int64) -> Float64 {
        if !isFuzzEnabled || interval < 2.5 {
            return interval
        }

        var generator = alea(seed: seed)
        let fuzzFactor = generator.double()
        let (minInterval, maxInterval) =
        FuzzRange.getFuzzRange(interval: interval, elapsedDays: elapsedDays, maximumInterval: maximumInterval)

        return ._mulAdd(
            fuzzFactor,
            Float64(maxInterval) - Float64(minInterval) + 1,
            Float64(minInterval)
        )
    }
}

private struct FuzzRange {
    let start: Float64
    let end: Float64
    let factor: Float64
    
    init(start: Float64, end: Float64, factor: Float64) {
        self.start = start
        self.end = end
        self.factor = factor
    }
    
    static func getFuzzRange(interval: Float64, elapsedDays: Int64, maximumInterval: Int32) -> (Int64, Int64) {
        var delta: Float64 = 1.0
        for range in constFuzzRange {
            delta += range.factor * max(min(interval, range.end) - range.start, 0)
        }
        
        let i = min(interval, Float64(maximumInterval))
        var minInterval = max(2, (i - delta).rounded())
        let maxInterval = min((i + delta).rounded(), Float64(maximumInterval))
        if i > Float64(elapsedDays) {
            minInterval = max(minInterval, Float64(elapsedDays) + 1)
        }
        
        minInterval = min(minInterval, maxInterval)
        return (Int64(minInterval), Int64(maxInterval))
    }
}


private let constFuzzRange = [
    FuzzRange(start: 2.5, end: 7.0, factor: 0.15),
    FuzzRange(start: 7.0, end: 20.0, factor: 0.1),
    FuzzRange(start: 20.0, end: 1.7976931348623157E+308, factor: 0.05),
];

public enum Seed: CustomStringConvertible, ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    case string(String)
    case empty
    case `default`
    
    public init<T: CustomStringConvertible>(_ value: T) {
        guard !value.description.isEmpty else {
            self = .default
            return
        }
        self = .string(value.description)
    }
    
    public init(int: UInt64) {
        self = .init(int)
    }
    
    public var rawValue: String {
        switch self {
        case .string(let value):
            return value
        case .empty:
            fallthrough
        case .default:
            return String(Date.now.timeIntervalSince1970)
        }
    }
    
    public var description: String {
        rawValue
    }
    
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}
