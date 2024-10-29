//
//  FSRSLongTermSchedulerTests.swift
//
//  Created by nkq on 10/20/24.
//


import XCTest
@testable import FSRS

class LongTermSchedulerTests: XCTestCase {
    var params: FSRSParameters!
    var algorithm: FSRS!
    var calendar: Calendar = {
        var res = Calendar.current
        res.timeZone = .init(secondsFromGMT: 0)!
        return res
    }()
    var dateFormatter: DateFormatter = .init()

    override func setUp() {
        super.setUp()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let w: [Double] = [
            0.4197, 1.1869, 3.0412, 15.2441, 7.1434, 0.6477, 1.0007, 0.0674, 1.6597,
            0.1712, 1.1178, 2.0225, 0.0904, 0.3025, 2.1214, 0.2498, 2.9466, 0.4891,
            0.6468,
        ]
        params = FSRSDefaults().generatorParameters(props: .init(w: w, enableShortTerm: false))
        algorithm = FSRS(parameters: params)
    }


    func test1() {
        let testAdditionalCases: (
            _ now: Date,
            _ ratings: [Rating],
            _ exivlHistory: [Int],
            _ exsHistory: [Double],
            _ exdHistory: [Double]
        ) -> Void = { [weak self] now,ratings,exivlHistory,exsHistory,exdHistory in
            guard let self = self else { return }
            var now = now
            var card = FSRSDefaults().createEmptyCard()
            var ivlHistory: [Int] = []
            var sHistory: [Double] = []
            var dHistory: [Double] = []

            for rating in ratings {
                let record = algorithm.repeat(card: card, now: now)[rating]
                let next = try! FSRS(parameters: params).next(card: card, now: now, grade: rating)
                XCTAssertEqual(record, next)

                card = record!.card
                ivlHistory.append(Int(card.scheduledDays))
                sHistory.append(card.stability)
                dHistory.append(card.difficulty)
                now = card.due
            }

            XCTAssertEqual(ivlHistory, exivlHistory)
            XCTAssertEqual(sHistory, exsHistory)
            XCTAssertEqual(dHistory, exdHistory)
        }
        testAdditionalCases(
            calendar.date(from: DateComponents(calendar: Calendar.current, year: 2022, month: 12, day: 29, hour: 12, minute: 30))!,
            [
                .good, .good, .good, .good, .good, .good, .again,
                .again, .good, .good, .good, .good, .good
            ],
            [3, 13, 48, 155, 445, 1158, 17, 3, 9, 27, 74, 190, 457],
            [
                3.0412, 13.09130698, 48.15848988, 154.93732625, 445.05562739,
                1158.07779739, 16.63063166, 2.98878859, 9.46334669, 26.94735845,
                73.97228121, 189.70368068, 457.43785852,
            ],
            [
                4.49094334, 4.26664289, 4.05746029, 3.86237659, 3.68044154, 3.51076891,
                5.21903785, 6.81216947, 6.43141837, 6.0763299, 5.74517439, 5.43633876,
                5.14831865,
            ])
    }

    func test2() {
        let testAdditionalCases: (
            _ now: Date,
            _ ratings: [Rating],
            _ exivlHistory: [Int],
            _ exsHistory: [Double],
            _ exdHistory: [Double]
        ) -> Void = { [weak self] now,ratings,exivlHistory,exsHistory,exdHistory in
            guard let self = self else { return }
            var now = now
            var card = FSRSDefaults().createEmptyCard()
            var ivlHistory: [Int] = []
            var sHistory: [Double] = []
            var dHistory: [Double] = []

            for rating in ratings {
                let record = algorithm.repeat(card: card, now: now)[rating]
                let next = try! FSRS(parameters: params).next(card: card, now: now, grade: rating)
                XCTAssertEqual(record, next)

                card = record!.card
                ivlHistory.append(Int(card.scheduledDays))
                sHistory.append(card.stability)
                dHistory.append(card.difficulty)
                now = card.due
            }

            XCTAssertEqual(ivlHistory, exivlHistory)
            XCTAssertEqual(sHistory, exsHistory)
            XCTAssertEqual(dHistory, exdHistory)
        }
        testAdditionalCases(
            calendar.date(from: DateComponents(calendar: Calendar.current, year: 2022, month: 12, day: 29, hour: 12, minute: 30))!,
            [
                .again,
                .hard,
                .good,
                .easy,
                .again,
                .hard,
                .good,
                .easy,
            ],
             [1, 2, 5, 31, 4, 6, 14, 71],
             [
                0.4197, 1.0344317, 4.81220091, 31.07244353, 3.94952214, 5.69573414,
                14.10008388, 71.33039653,
              ],
            [
                7.1434, 7.67357679, 7.23476684, 5.89227986, 7.44003496, 7.95021855,
                7.49276295, 6.13288703,
              ])
    }

    func test3() {
        let testAdditionalCases: (
            _ now: Date,
            _ ratings: [Rating],
            _ exivlHistory: [Int],
            _ exsHistory: [Double],
            _ exdHistory: [Double]
        ) -> Void = { [weak self] now,ratings,exivlHistory,exsHistory,exdHistory in
            guard let self = self else { return }
            var now = now
            var card = FSRSDefaults().createEmptyCard()
            var ivlHistory: [Int] = []
            var sHistory: [Double] = []
            var dHistory: [Double] = []

            for rating in ratings {
                let record = algorithm.repeat(card: card, now: now)[rating]
                let next = try! FSRS(parameters: params).next(card: card, now: now, grade: rating)
                XCTAssertEqual(record, next)

                card = record!.card
                ivlHistory.append(Int(card.scheduledDays))
                sHistory.append(card.stability)
                dHistory.append(card.difficulty)
                now = card.due
            }

            XCTAssertEqual(ivlHistory, exivlHistory)
            XCTAssertEqual(sHistory, exsHistory)
            XCTAssertEqual(dHistory, exdHistory)
        }
        testAdditionalCases(
            calendar.date(from: DateComponents(calendar: Calendar.current, year: 2022, month: 12, day: 29, hour: 12, minute: 30))!,
            [
                .hard,
                .good,
                .easy,
                .again,
                .hard,
                .good,
                .easy,
                .again,
            ],
            [2, 7, 54, 5, 8, 22, 130, 7],
            [
                1.1869, 6.59167572, 53.76078737, 5.13329038, 7.91598767, 22.353464,
                129.65007831, 7.25750204,
              ],
            [
                6.23225985, 5.89059466, 4.63870489, 6.27095095, 6.8599308, 6.47596059,
                5.18461715, 6.78006872,
              ])
    }

    func test4() {
        let testAdditionalCases: (
            _ now: Date,
            _ ratings: [Rating],
            _ exivlHistory: [Int],
            _ exsHistory: [Double],
            _ exdHistory: [Double]
        ) -> Void = { [weak self] now,ratings,exivlHistory,exsHistory,exdHistory in
            guard let self = self else { return }
            var now = now
            var card = FSRSDefaults().createEmptyCard()
            var ivlHistory: [Int] = []
            var sHistory: [Double] = []
            var dHistory: [Double] = []

            for rating in ratings {
                let record = algorithm.repeat(card: card, now: now)[rating]
                let next = try! FSRS(parameters: params).next(card: card, now: now, grade: rating)
                XCTAssertEqual(record, next)

                card = record!.card
                ivlHistory.append(Int(card.scheduledDays))
                sHistory.append(card.stability)
                dHistory.append(card.difficulty)
                now = card.due
            }

            XCTAssertEqual(ivlHistory, exivlHistory)
            XCTAssertEqual(sHistory, exsHistory)
            XCTAssertEqual(dHistory, exdHistory)
        }
        testAdditionalCases(
            calendar.date(from: DateComponents(calendar: Calendar.current, year: 2022, month: 12, day: 29, hour: 12, minute: 30))!,
            [
                .good,
                .easy,
                .again,
                .hard,
                .good,
                .easy,
                .again,
                .hard,
            ],
            [3, 33, 4, 7, 24, 166, 8, 13],
            [
                3.0412, 32.65484522, 4.26210549, 7.16183801, 23.58957904, 166.25211957,
                8.13553136, 12.60456051,
              ],
            [
                4.49094334, 3.33339007, 5.05361435, 5.72464269, 5.4171909, 4.19720854,
                5.85921145, 6.47594255,
              ])
    }

    func test5() {
        let testAdditionalCases: (
            _ now: Date,
            _ ratings: [Rating],
            _ exivlHistory: [Int],
            _ exsHistory: [Double],
            _ exdHistory: [Double]
        ) -> Void = { [weak self] now,ratings,exivlHistory,exsHistory,exdHistory in
            guard let self = self else { return }
            var now = now
            var card = FSRSDefaults().createEmptyCard()
            var ivlHistory: [Int] = []
            var sHistory: [Double] = []
            var dHistory: [Double] = []

            for rating in ratings {
                let record = algorithm.repeat(card: card, now: now)[rating]
                let next = try! FSRS(parameters: params).next(card: card, now: now, grade: rating)
                XCTAssertEqual(record, next)

                card = record!.card
                ivlHistory.append(Int(card.scheduledDays))
                sHistory.append(card.stability)
                dHistory.append(card.difficulty)
                now = card.due
            }

            XCTAssertEqual(ivlHistory, exivlHistory)
            XCTAssertEqual(sHistory, exsHistory)
            XCTAssertEqual(dHistory, exdHistory)
        }
        testAdditionalCases(
            calendar.date(from: DateComponents(calendar: Calendar.current, year: 2022, month: 12, day: 29, hour: 12, minute: 30))!,
            [
                .easy,
                .again,
                .hard,
                .good,
                .easy,
                .again,
                .hard,
                .good,
            ],
            [15, 3, 6, 26, 226, 10, 17, 55],
            [
                15.2441, 3.25621013, 6.31387378, 25.90156323, 226.22071942, 9.55915065,
                16.56937382, 55.3790909,
            ],
            [
                1.16304343, 3.02954907, 3.83699941, 3.65677478, 2.55544447, 4.32810228,
                5.04803013, 4.78618203,
            ])
    }

    func testStateSwitching() {
        var ivlHistory: [Int] = []
        var sHistory: [Double] = []
        var dHistory: [Double] = []
        var stateHistory: [CardState] = []

        let grades: [Rating] = [
            .good, .good, .again, .good, .good, .again
        ]
        let shortTerm = [true, false, false, false, true, true]

        var now = calendar.date(from: DateComponents(calendar: Calendar.current, year: 2022, month: 12, day: 29, hour: 12, minute: 30))!
        var card = FSRSDefaults().createEmptyCard(now: now)

        for i in 0..<grades.count {
            let grade = grades[i]
            let enable = shortTerm[i]
            algorithm.parameters.enableShortTerm = enable
            let record = algorithm.repeat(card: card, now: now)[grade]
            var tempParam = FSRSDefaults().generatorParameters(props: params)
            tempParam.enableShortTerm = enable
            let next = try! FSRS(parameters: tempParam).next(card: card, now: now, grade: grade)
            XCTAssertEqual(record, next)

            card = record!.card
            now = card.due
            ivlHistory.append(Int(card.scheduledDays))
            sHistory.append(card.stability)
            dHistory.append(card.difficulty)
            stateHistory.append(card.state)
        }

        XCTAssertEqual(ivlHistory, [0, 4, 1, 4, 15, 0])
        XCTAssertEqual(sHistory, [
            3.0412, 3.0412, 1.21778427, 4.32308454, 14.84659978, 2.81505627,
        ])
        XCTAssertEqual(dHistory, [
            4.49094334, 4.26664289, 5.92396593, 5.60307975, 5.3038213, 6.89123851,
        ])
        XCTAssertEqual(stateHistory, [
            .learning, .review, .review, .review, .review, .relearning
        ])
    }

    func testGetRetrievability() {
        let f = FSRS(parameters: .init(w: [
            0.4072, 1.1829, 3.1262, 15.4722, 7.2102, 0.5316, 1.0651, 0.0234, 1.616,
            0.1544, 1.0824, 1.9813, 0.0953, 0.2975, 2.2042, 0.2407, 2.9466, 0.5034,
            0.6567,
        ], enableShortTerm: false))
        let now = dateFormatter.date(from: "2024-08-03 18:15:34")!
        let viewDate = dateFormatter.date(from: "2024-08-03 18:25:34")!
        var card = FSRSDefaults().createEmptyCard(now: now)
        card = f.repeat(card: card, now: now)[Rating.again]!.card
        let retrievability = f.getRetrievability(card: card, now: viewDate).string
        XCTAssertEqual(retrievability, "100.00%")

        card = .init(
            due: dateFormatter.date(from: "2024-08-04 18:15:34")!,
            stability: 0.4072,
            difficulty: 7.2102,
            elapsedDays: 0, scheduledDays: 1,
            reps: 1, lapses: 0,
            state: .review,
            lastReview: dateFormatter.date(from: "2024-08-03 18:15:34")
        )
        let retrievability2 = f.getRetrievability(card: card, now: viewDate).string
        XCTAssertEqual(retrievability2, "100.00%")
    }
}
