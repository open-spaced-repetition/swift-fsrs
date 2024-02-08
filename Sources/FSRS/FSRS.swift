//
//  FlashCardEngine.swift
//
//  Created by Ben on 09/08/2023.
//

import Foundation

enum Constants {
    static let secondsInMinute = 60.0
    static let secondsInHour = Self.secondsInMinute * 60
    static let secondsInDay = Self.secondsInHour * 24
}

public enum Status: Codable, Equatable {
    case new, learning, review, relearning
}

public enum Rating: Int, Codable, Equatable  {
    case again = 1, hard, good, easy
}

public struct ReviewLog: Equatable, Codable {
    public var rating: Rating
    public var elapsedDays: Double
    public var scheduledDays: Double
    public var review: Date
    public var status: Status

    public init(
        rating: Rating,
        elapsedDays: Double,
        scheduledDays: Double,
        review: Date,
        status: Status
    ) {
        self.rating = rating
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.review = review
        self.status = status
    }
}

public struct Card: Equatable, Codable {
    public var due: Date
    public var stability: Double
    public var difficulty: Double
    public var elapsedDays: Double
    public var scheduledDays: Double
    public var reps: Int
    public var lapses: Int
    public var status: Status
    public var lastReview: Date

    public init(
        due: Date = Date(),
        stability: Double = 0,
        difficulty: Double = 0,
        elapsedDays: Double = 0,
        scheduledDays: Double = 0,
        reps: Int = 0,
        lapses: Int = 0,
        status: Status = .new,
        lastReview: Date = Date()
    ) {
        self.due = due
        self.stability = stability
        self.difficulty = difficulty
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.reps = reps
        self.lapses = lapses
        self.status = status
        self.lastReview = lastReview
    }

    func retrievability(for now: Date) -> Double? {
        guard status == .review else { return nil }
        let elapsedDays = max(0, (now.timeIntervalSince(lastReview) / Constants.secondsInDay))
        return exp(log(0.9) * Double(elapsedDays) / stability)
    }

    func printLog() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(self)
            print(data)
        } catch {
            print("Error serializing JSON: \(error)")
        }
    }
}

public struct SchedulingInfo {
    public var card: Card
    public var reviewLog: ReviewLog

    public init(card: Card, reviewLog: ReviewLog) {
        self.card = card
        self.reviewLog = reviewLog
    }

    public init(rating: Rating, reference: Card, current: Card, review: Date) {
        self.card = reference
        self.reviewLog = ReviewLog(
            rating: rating,
            elapsedDays: reference.scheduledDays,
            scheduledDays: current.elapsedDays,
            review: review,
            status: current.status
        )
    }
}

public struct SchedulingCards: Equatable, Codable {
    public var again: Card
    public var hard: Card
    public var good: Card
    public var easy: Card

    public init(card: Card) {
        self.again = card
        self.hard = card
        self.good = card
        self.easy = card
    }

    public mutating func updateStatus(to status: Status) {
        switch status {
        case .new:
            again.status = .learning
            hard.status = .learning
            good.status = .learning
            easy.status = .review
            again.lapses += 1
        case .learning, .relearning:
            again.status = status
            hard.status = status
            good.status = .review
            easy.status = .review
        case .review:
            again.status = .relearning
            hard.status = .review
            good.status = .review
            easy.status = .review
            again.lapses += 1
        }
    }

    public mutating func schedule(
        now: Date,
        hardInterval: Double,
        goodInterval: Double,
        easyInterval: Double
    ) {
        again.scheduledDays = 0
        hard.scheduledDays = hardInterval
        good.scheduledDays = goodInterval
        easy.scheduledDays = easyInterval

        again.due = addTime(now, value: 5, unit: .minute)
        if hardInterval > 0 {
            hard.due = addTime(now, value: hardInterval, unit: .day)
        } else {
            hard.due = addTime(now, value: 10, unit: .minute)
        }
        good.due = addTime(now, value: goodInterval, unit: .day)
        easy.due = addTime(now, value: easyInterval, unit: .day)
    }

    public mutating func addTime(_ now: Date, value: Double, unit: Calendar.Component) -> Date {
        var seconds = 1.0
        switch unit {
        case .second:
            seconds = 1.0
        case .minute:
            seconds = Constants.secondsInMinute
        case .hour:
            seconds = Constants.secondsInHour
        case .day:
            seconds = Constants.secondsInDay
        default:
            assert(false)
        }

        return Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + seconds * value)
    }

    func recordLog(for card: Card, now: Date) -> [Rating: SchedulingInfo] {
        [
            .again: SchedulingInfo(rating: .again, reference: again, current: card, review: now),
            .hard: SchedulingInfo(rating: .hard, reference: hard, current: card, review: now),
            .good: SchedulingInfo(rating: .good, reference: good, current: card, review: now),
            .easy: SchedulingInfo(rating: .easy, reference: easy, current: card, review: now),
        ]
    }
}

public struct Params {
    public var requestRetention: Double
    public var maximumInterval: Double
    public var w: [Double]

    public init() {
        self.requestRetention = 0.9
        self.maximumInterval = 36500
        self.w = [
            0.4, // Initial Stability for Again
            0.6, // Initial Stability for Hard
            2.4, // Initial Stability for Good
            5.8, // Initial Stability for Easy
            4.93,
            0.94,
            0.86,
            0.01,
            1.49,
            0.14,
            0.94,
            2.18,
            0.05,
            0.34,
            1.26,
            0.29,
            2.61,
        ]
    }
}

public struct FSRS {
    public var p: Params

    public init(p: Params = Params()) {
        self.p = p
    }

    // Was repeat
    public func `repeat`(card: Card, now: Date) -> [Rating: SchedulingInfo] {
        var card = card
        if card.status == .new {
            card.elapsedDays = 0
        } else {
            // Check this is positive...
            card.elapsedDays = (now.timeIntervalSince(card.lastReview)) / Constants.secondsInDay
        }

        print("Elapsed \(card.elapsedDays)")
        card.lastReview = now
        card.reps += 1

        var s = SchedulingCards(card: card)
        s.updateStatus(to: card.status)

        switch card.status {
        case .new:
            initDS(s: &s)

            s.again.due = s.addTime(now, value: 1, unit: .minute)
            s.hard.due = s.addTime(now, value: 5, unit: .minute)
            s.good.due = s.addTime(now, value: 10, unit: .minute)

            let easyInterval = nextInterval(s: s.easy.stability)

            s.easy.scheduledDays = easyInterval
            s.easy.due = s.addTime(now, value: easyInterval, unit: .day)

        case .learning, .relearning:
            let hardInterval = 0.0
            let goodInterval = nextInterval(s: s.good.stability)
            let easyInterval = max(nextInterval(s: s.easy.stability), goodInterval + 1)
            s.schedule(now: now, hardInterval: hardInterval, goodInterval: goodInterval, easyInterval: easyInterval)

        case .review:
            let interval = card.elapsedDays
            let lastDifficulty = card.difficulty
            let lastStability = card.stability

            let retrievability = pow(1 + Double(interval) / (9 * lastStability), -1)

            nextDS(&s, lastDifficulty: lastDifficulty, lastStability: lastStability, retrievability: retrievability)

            var hardInterval = nextInterval(s: s.hard.stability)
            var goodInterval = nextInterval(s: s.good.stability)

            hardInterval = min(hardInterval, goodInterval)
            goodInterval = max(goodInterval, hardInterval + 1)

            let easyInterval = max(nextInterval(s: s.easy.stability), goodInterval + 1)
            s.schedule(now: now, hardInterval: hardInterval, goodInterval: goodInterval, easyInterval: easyInterval)
        }

        return s.recordLog(for: card, now: now)
    }

    public func initDS(s: inout SchedulingCards) {
        s.again.difficulty = initDifficulty(.again)
        s.again.stability = initStability(.again)
        s.hard.difficulty = initDifficulty(.hard)
        s.hard.stability = initStability(.hard)
        s.good.difficulty = initDifficulty(.good)
        s.good.stability = initStability(.good)
        s.easy.difficulty = initDifficulty(.easy)
        s.easy.stability = initStability(.easy)
    }

    public func nextDS(
        _ scheduling: inout SchedulingCards,
        lastDifficulty d: Double,
        lastStability s: Double,
        retrievability: Double
    ) {
        scheduling.again.difficulty = nextDifficulty(d: d, rating: .again)
        scheduling.again.stability = nextForgetStability(d: scheduling.again.difficulty, s: s, r: retrievability)
        scheduling.hard.difficulty = nextDifficulty(d: d, rating: .hard)
        scheduling.hard.stability = nextRecallStability(
            d: scheduling.hard.difficulty, s: s, r: retrievability, rating: .hard
        )
        scheduling.good.difficulty = nextDifficulty(d: d, rating: .good)
        scheduling.good.stability = nextRecallStability(
            d: scheduling.good.difficulty, s: s, r: retrievability, rating: .good
        )
        scheduling.easy.difficulty = nextDifficulty(d: d, rating: .easy)
        scheduling.easy.stability = nextRecallStability(
            d: scheduling.easy.difficulty, s: s, r: retrievability, rating: .easy
        )
    }

    public func initStability(_ rating: Rating) -> Double {
        return initStability(r: rating.rawValue)
    }

    public func initStability(r: Int) -> Double {
        return max(p.w[r - 1], 0.1)
    }

    public func initDifficulty(_ rating: Rating) -> Double {
        return initDifficulty(r: rating.rawValue)
    }

    public func initDifficulty(r: Int) -> Double {
        return min(max(p.w[4] - p.w[5] * Double(r - 3), 1.0), 10.0)
    }

    public func nextInterval(s: Double) -> Double {
        let interval = s * 9 * (1 / p.requestRetention - 1)
        return min(max(round(interval), 1), p.maximumInterval)
    }

    public func nextDifficulty(d: Double, rating: Rating) -> Double {
        let r = rating.rawValue
        let nextD = d - p.w[6] * Double(r - 3)
        return min(max(meanReversion(p.w[4], current: nextD), 1.0), 10.0)
    }

    func meanReversion(_ initial: Double, current: Double) -> Double {
        return p.w[7] * initial + (1 - p.w[7]) * current
    }

    public func nextRecallStability(d: Double, s: Double, r: Double, rating: Rating) -> Double {
        let hardPenalty = (rating == .hard) ? p.w[15] : 1
        let easyBonus = (rating == .easy) ? p.w[16] : 1
        return s * (1 + exp(p.w[8]) * (11 - d) * pow(s, -p.w[9]) * (exp((1 - r) * p.w[10]) - 1) * hardPenalty * easyBonus)
    }

    public func nextForgetStability(d: Double, s: Double, r: Double) -> Double {
        p.w[11] * pow(d, -p.w[12]) * (pow(s + 1.0, p.w[13]) - 1) * exp((1 - r) * p.w[14])
    }
}
