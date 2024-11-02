import Foundation
import RealModule
import Testing

@testable
import FSRS

struct AlgoTests {
    static let testRatings: [Rating] = [
        .good,
        .good,
        .good,
        .good,
        .good,
        .good,
        .again,
        .again,
        .good,
        .good,
        .good,
        .good,
        .good,
    ];

    static let weights: [Float64] = [
        0.4197, 1.1869, 3.0412, 15.2441, 7.1434, 0.6477, 1.0007, 0.0674, 1.6597, 0.1712, 1.1178,
        2.0225, 0.0904, 0.3025, 2.1214, 0.2498, 2.9466, 0.4891, 0.6468,
    ];

    static var dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    @Test
    func testBasicSchedulerInterval() {
        let fsrs = FSRS()
        var card = Card()
        var now = Self.dateFormatter.date(from: "2022-11-29T12:30:00Z")!
        var intervalHistory: [Int64] = []

        for rating in Self.testRatings {
            let next = fsrs.next(card: card, now: now, rating: rating)
            card = next.card
            intervalHistory.append(card.scheduledDays)
            now = card.due
        }
        let expected: [Int64] = [0, 4, 15, 48, 136, 351, 0, 0, 7, 13, 24, 43, 77];
        #expect(intervalHistory == expected)
    }

    @Test
    func testBasicSchedulerState() {
        let params = Parameters(
            w: Self.weights
        )

        let fsrs = FSRS(parameters: params)
        var card = Card()
        var now = Self.dateFormatter.date(from: "2022-11-29T12:30:00Z")!
        var stateList: [State] = []
        var recordLog = fsrs.repeat(card: card, now: now)

        for rating in Self.testRatings {
            card = recordLog[rating]!.card
            let revLog = recordLog[rating]!.reviewLog
            stateList.append(revLog.state)
            now = card.due
            recordLog = fsrs.repeat(card: card, now: now)
        }
        let expected: [State] = [
            .new, .learning, .review, .review, .review, .review, .review, .relearning, .relearning, .review,
            .review, .review, .review,
        ];
        #expect(stateList == expected)
    }

    @Test
    func testBasicSchedulerMemoState() {
        let params = Parameters(
            w: Self.weights
        )

        let fsrs = FSRS(parameters: params)
        var card = Card()
        var now = Self.dateFormatter.date(from: "2022-11-29T12:30:00Z")!
        var recordLog = fsrs.repeat(card: card, now: now)
        let ratings: [Rating] = [
            .again,
            .good,
            .good,
            .good,
            .good,
            .good,
        ]
        let intervals = [0, 0, 1, 3, 8, 21]
        for (index, rating) in ratings.enumerated() {
            card = recordLog[rating]!.card
            now = now.addingDays(Int64(intervals[index]))
            recordLog = fsrs.repeat(card: card, now: now)
        }

        card = recordLog[.good]!.card;
        #expect(card.stability.precised(4) == 71.4554.precised(4))
        #expect(card.difficulty.precised(4) == 5.0976.precised(4))
    }

    @Test
    func testLongTermScheduler() {
        let params = Parameters(
            w: Self.weights,
            isShortTermEnabled: false
        )

        let fsrs = FSRS(parameters: params)
        var card = Card()
        var now = Self.dateFormatter.date(from: "2022-11-29T12:30:00Z")!
        var intervalHistory: [Int64] = []
        var stabilityHistory: [Float64] = []
        var difficultyHistory: [Float64] = []

        for rating in Self.testRatings {
            let record = fsrs.repeat(card: card, now: now)[rating]!
            let next = fsrs.next(card: card, now: now, rating: rating)

            #expect(record.card == next.card)

            card = record.card
            intervalHistory.append(card.scheduledDays)
            stabilityHistory.append(card.stability)
            difficultyHistory.append(card.difficulty)
            now = card.due
        }

        let expectedInterval: [Int64] = [3, 13, 48, 155, 445, 1158, 17, 3, 9, 27, 74, 190, 457]
        #expect(intervalHistory == expectedInterval)
        
        let expectedStability: [Float64] = [
            3.0412, 13.0913, 48.1585, 154.9373, 445.0556, 1158.0778, 16.6306, 2.9888, 9.4633, 26.9474,
            73.9723, 189.7037, 457.4379,
        ]
        #expect(stabilityHistory.map { $0.precised(4) } == expectedStability)
        
        let expectedDifficulty: [Float64] = [
            4.4909, 4.2666, 4.0575, 3.8624, 3.6804, 3.5108, 5.219, 6.8122, 6.4314, 6.0763, 5.7452,
            5.4363, 5.1483,
        ]

        #expect(difficultyHistory.map { $0.precised(4) } == expectedDifficulty)
    }

    @Test
    func testPrngGetState() {
        let prng1 = alea(seed: Seed(int: 1))
        let prng2 = alea(seed: Seed(int: 2))
        let prng3 = alea(seed: Seed(int: 1))

        let aleaState1 = prng1.state()
        let aleaState2 = prng2.state()
        let aleaState3 = prng3.state()

        #expect(aleaState1 == aleaState3)
        #expect(aleaState1 != aleaState2)
    }

    @Test
    func testAleaGetNext() {
        let seed = Seed(int: 12345)
        var generator = alea(seed: seed)
        #expect(generator.genNext() == 0.27138191112317145)
        #expect(generator.genNext() == 0.19615925149992108)
        #expect(generator.genNext() == 0.6810678059700876)
    }

    @Test
    func testAleaInt32() {
        let seed = Seed(int: 12345)
        var generator = alea(seed: seed)
        #expect(generator.int32() == 1165576433);
        #expect(generator.int32() == 842497570);
        #expect(generator.int32() == -1369803343);
    }

    @Test
    func testAleaImportState() {
        var rng = SystemRandomNumberGenerator()
        var prng1 = alea(seed: Seed(int: rng.next()))
        _ = prng1.genNext()
        _ = prng1.genNext()
        _ = prng1.genNext()
        let prng1State = prng1.state()
        var prng2 = alea(seed: Seed.empty)
        prng2.import(state: prng1State)

        #expect(prng1.state() == prng2.state())

        for _ in 1...10000 {
            let a = prng1.genNext()
            let b = prng2.genNext()

            #expect(a == b)
            #expect(a >= 0.0 && a < 1.0)
            #expect(b >= 0.0 && b < 1.0)
        }
    }

    @Test
    func testSeedExample1() {
        let seed: Seed = "1727015666066"
        var generator = alea(seed: seed)
        let results = generator.genNext()
        let state = generator.state()

        let expectAleaState = AleaState(
            c: 1828249.0,
            s0: 0.5888567129150033,
            s1: 0.5074866858776659,
            s2: 0.6320083506871015
        )
        #expect(results == 0.6320083506871015)
        #expect(state == expectAleaState)
    }

    @Test
    func testSeedExample2() {
        let seed: Seed = "Seedp5fxh9kf4r0"
        var generator = alea(seed: seed)
        let results = generator.genNext()
        let state = generator.state()

        let expectAleaState = AleaState(
            c: 1776946.0,
            s0: 0.6778371171094477,
            s1: 0.0770602801349014,
            s2: 0.14867847645655274
        )
        #expect(results == 0.14867847645655274)
        #expect(state == expectAleaState)
    }

    @Test
    func testSeedExample3() {
        let seed: Seed = "NegativeS2Seed"
        var generator = alea(seed: seed)
        let results = generator.genNext()
        let state = generator.state()

        let expectAleaState = AleaState(
            c: 952982.0,
            s0: 0.25224833423271775,
            s1: 0.9213257452938706,
            s2: 0.830770346801728
        )
        #expect(results == 0.830770346801728)
        #expect(state == expectAleaState)
    }

    @Test
    func testGetRetrievability() {
        let fsrs = FSRS()
        let card = Card()
        let now = Self.dateFormatter.date(from: "2022-11-29T12:30:00Z")!
        let expectRetrievability: [Float64] = [1.0, 1.0, 1.0, 0.9026208];
        let scheduler = fsrs.repeat(card: card, now: now)

        for (i, rating) in Rating.allCases.enumerated() {
            let card = scheduler[rating]!.card
            let retrievability = card.retrievability(for: card.due)

            #expect(retrievability.precised(7) == expectRetrievability[i].precised(7))
        }
    }
}

private extension Float64 {
    func precised(_ value: Int = 1) -> Double {
        let offset = Float64.pow(10, Double(value))
        return (self * offset).rounded() / offset
      }
}
