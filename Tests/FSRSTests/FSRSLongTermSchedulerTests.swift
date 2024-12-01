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
            [
                3, 13, 48, 155, 445, 1158, 17, 3, 11, 37, 112, 307, 773,
            ],
            [
                3.0412, 13.09130698, 48.15848988, 154.93732625, 445.05562739,
                1158.07779739, 16.63063166, 3.01732209, 11.42247264, 37.37521902,
                111.8752758, 306.5974569, 772.94031572,
            ],
            [
                4.49094334, 4.26664289, 4.05746029, 3.86237659, 3.68044154, 3.51076891,
                4.69833071, 5.55956298, 5.26323756, 4.98688448, 4.72915759, 4.4888015,
                4.26464541,
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
             [
                1, 2, 6, 41, 4, 7, 21, 133
             ],
             [
                0.4197, 1.0344317, 5.5356759, 41.0033667, 4.46605519, 6.67743292,
                20.88868155, 132.81849454,
              ],
            [
                7.1434, 7.03653841, 6.64066485, 5.92312772, 6.44779861, 6.45995078,
                6.10293922, 5.36588547,
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
            [
                2, 7, 54, 5, 8, 26, 171, 8
            ],
            [
                1.1869, 6.59167572, 53.76078737, 5.0853693, 8.09786749, 25.52991279,
                171.16195166, 8.11072373,
              ],
            [
                6.23225985, 5.89059466, 5.14583392, 5.884097, 5.99269555, 5.667177,
                4.91430736, 5.71619151,
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
            [
                3, 33, 4, 7, 26, 193, 9, 14
            ],
            [
                3.0412, 32.65484522, 4.22256838, 7.23250123, 25.52681848, 193.36619432,
                8.63899858, 14.31323884,
              ],
            [
                4.49094334, 3.69538259, 4.83221448, 5.12078462, 4.85403286, 4.07165035,
                5.1050878, 5.34697075,
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
            [
                15, 3, 6, 27, 240, 10, 17, 60
            ],
            [
                15.2441, 3.25621013, 6.32684549, 26.56339029, 239.70462771, 9.75621519,
                17.06035531, 59.59547542,
            ],
            [
                1.16304343, 2.99573557, 3.59851762, 3.43436666, 2.60045771, 4.03816348,
                4.46259158, 4.24020203,
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

        XCTAssertEqual(ivlHistory, [
            0, 4, 1, 5, 19, 0
        ])
        XCTAssertEqual(sHistory, [
            3.0412, 3.0412, 1.21778427, 4.73753014, 19.02294877, 3.20676576,
        ])
        XCTAssertEqual(dHistory, [
            4.49094334, 4.26664289, 5.24649844, 4.97127357, 4.71459886, 5.57136081,
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
