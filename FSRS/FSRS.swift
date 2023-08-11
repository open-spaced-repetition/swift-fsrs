//
//  FlashCardEngine.swift
//
//  Created by Ben on 09/08/2023.
//

import Foundation

public class Const {
    public static let secondsInMinute = 60.0
    public static let secondsInHour = 3600.0
    public static let secondsInDay = 86400.0
}

enum Status: Int {
    case New = 0, Learning, Review, Relearning
    
    var description : String {
      switch self {
      case .New: return "New"
      case .Learning: return "Learning"
      case .Review: return "Review"
      case .Relearning: return "Relearning"
      }
    }
}

enum Rating: Int, Encodable {
    case Again = 1, Hard, Good, Easy
    
    var description : String {
      switch self {
      case .Again: return "Again"
      case .Hard: return "Hard"
      case .Good: return "Good"
      case .Easy: return "Easy"
      }
    }
}

class ReviewLog {
    var rating: Rating
    var elapsedDays: Double
    var scheduledDays: Double
    var review: Date
    var status: Status

    init(rating: Rating, elapsedDays: Double, scheduledDays: Double, review: Date, status: Status) {
        self.rating = rating
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.review = review
        self.status = status
    }
    
    func data() -> [String: Encodable] {
        return [
            "rating": rating,
            "elapsedDays": elapsedDays,
            "scheduledDays": scheduledDays,
            "review": review,
            "state": status.description,
        ]
    }
    
}

class Card: NSCopying {
    
    var due: Date
    var stability: Double
    var difficulty: Double
    var elapsedDays: Double
    var scheduledDays: Double
    var reps: Int
    var lapses: Int
    var status: Status
    var lastReview: Date

    init() {
        self.due = Date()
        self.stability = 0
        self.difficulty = 0
        self.elapsedDays = 0
        self.scheduledDays = 0
        self.reps = 0
        self.lapses = 0
        self.status = .New
        self.lastReview = Date()
    }

    func retrievability(for now: Date) -> Double? {
        var retrievability: Double?
        if status == .Review {
            let elapsedDays = max(0, (now.timeIntervalSince(lastReview) / Const.secondsInDay))
            retrievability = exp(log(0.9) * Double(elapsedDays) / stability)
        }
        return retrievability
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let card = Card()
        card.due = due
        card.stability = stability
        card.difficulty = difficulty
        card.elapsedDays = elapsedDays
        card.scheduledDays = scheduledDays
        card.reps = reps
        card.lapses = lapses
        card.status = status
        card.lastReview = lastReview
        return card
    }
    
    func data() -> [String: Encodable] {
        return [
            "due": due,
            "stability": stability,
            "difficulty": difficulty,
            "elapsed_days": elapsedDays,
            "scheduled_days": scheduledDays,
            "reps": reps,
            "lapses": lapses,
            "state": status.description,
            "last_review": lastReview,
        ]
    }
    
    func printLog() {
        do {
            let data = try JSONSerialization.data(withJSONObject: data(), options: .prettyPrinted)
            print(data)
        } catch {
            print("Error serializing JSON: \(error)")
        }
    }
    
}

class SchedulingInfo {
    var card: Card
    var reviewLog: ReviewLog
    
    init(card: Card, reviewLog: ReviewLog) {
        self.card = card
        self.reviewLog = reviewLog
    }
    
    init(rating: Rating, reference: Card, current: Card, review: Date) {
        self.card = reference
        self.reviewLog = ReviewLog(rating: rating, elapsedDays: reference.scheduledDays, scheduledDays: current.elapsedDays, review: review, status: current.status)
    }
    
    func data() -> [String: [String: Encodable]] {
        return [
            "log": reviewLog.data(),
            "card": card.data()
        ]
    }

}

class SchedulingCards {
    var again: Card
    var hard: Card
    var good: Card
    var easy: Card

    init(card: Card) {
        self.again = card.copy() as! Card
        self.hard = card.copy() as! Card
        self.good = card.copy() as! Card
        self.easy = card.copy() as! Card
    }

    func updateStatus(to status: Status) {
        if status == .New {
            [again, hard, good].forEach { $0.status = .Learning }
            easy.status = .Review
            again.lapses += 1
        } else if status == .Learning || status == .Relearning {
            [again, hard].forEach { $0.status = status }
            [good, easy].forEach { $0.status = .Review }
        } else if status == .Review {
            again.status = .Relearning
            [hard, good, easy].forEach { $0.status = .Review }
            again.lapses += 1
        }
    }

    func schedule(now: Date, hardInterval: Double, goodInterval: Double, easyInterval: Double) {

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
    
    public func addTime(_ now: Date, value: Double, unit: Calendar.Component) -> Date {
        var seconds = 1.0
        switch unit {
            case .second:
                seconds = 1.0
            case .minute:
                seconds = Const.secondsInMinute
            case .hour:
                seconds = Const.secondsInMinute
            case .day:
                seconds = Const.secondsInDay
            default:
                assert(false)
            }
        
        return Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate + seconds * value)
//        return Calendar.current.date(byAdding: unit, value: value, to: now)!
    }

    func recordLog(for card: Card, now: Date) -> [Rating: SchedulingInfo] {
        return [
            .Again: SchedulingInfo(rating: .Again, reference: again, current: card, review: now),
            .Hard: SchedulingInfo(rating: .Hard, reference: hard, current: card, review: now),
            .Good: SchedulingInfo(rating: .Good, reference: good, current: card, review: now),
            .Easy: SchedulingInfo(rating: .Easy, reference: easy, current: card, review: now),
        ]
    }
    
    func data() -> [String: [String: Encodable]] {
        return [
            "again": again.data(),
            "hard": hard.data(),
            "good": good.data(),
            "easy": easy.data(),
        ]
    }
    
}

class Params {
    var requestRetention: Double
    var maximumInterval: Double
    var w: [Double]

    init() {
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


class FSRS {
    var p: Params
    

    init() {
        self.p = Params()
    }

    // Was repeat
    func `repeat`(card: Card, now: Date) -> [Rating: SchedulingInfo] {
        let card = card.copy() as! Card

        if card.status == .New {
            card.elapsedDays = 0
        } else {
            // Check this is positive...
            card.elapsedDays = (now.timeIntervalSince(card.lastReview)) / Const.secondsInDay
        }
        
        print("Elapsed \(card.elapsedDays)")
        card.lastReview = now
        card.reps += 1
        
        let s = SchedulingCards(card: card)
        s.updateStatus(to: card.status)
        
        if card.status == .New {
            initDS(s: s)
            
            s.again.due = s.addTime(now, value: 1, unit: .minute)
            s.hard.due = s.addTime(now, value: 5, unit: .minute)
            s.good.due = s.addTime(now, value: 10, unit: .minute)

            let easyInterval = nextInterval(s: s.easy.stability)
            
            s.easy.scheduledDays = easyInterval
            s.easy.due = s.addTime(now, value: easyInterval, unit: .day)

        } else if card.status == .Learning || card.status == .Relearning {
            let hardInterval = 0.0
            let goodInterval = nextInterval(s: s.good.stability)
            let easyInterval = max(nextInterval(s: s.easy.stability), goodInterval + 1)
            s.schedule(now: now, hardInterval: hardInterval, goodInterval: goodInterval, easyInterval: easyInterval)
        } else if card.status == .Review {
            
            let interval = card.elapsedDays
            let lastDifficulty = card.difficulty
            let lastStability = card.stability
            
            let retrievability = pow(1 + Double(interval) / (9 * lastStability), -1)

            nextDS(s, lastDifficulty: lastDifficulty, lastStability: lastStability, retrievability: retrievability)

            var hardInterval = nextInterval(s: s.hard.stability)
            var goodInterval = nextInterval(s: s.good.stability)
            
            hardInterval = min(hardInterval, goodInterval)
            goodInterval = max(goodInterval, hardInterval + 1)
            
            let easyInterval = max(nextInterval(s: s.easy.stability), goodInterval + 1)
            s.schedule(now: now, hardInterval: hardInterval, goodInterval: goodInterval, easyInterval: easyInterval)
        }
        
        return s.recordLog(for: card, now: now)
    }

    func initDS(s: SchedulingCards) {
        s.again.difficulty = initDifficulty(.Again)
        s.again.stability = initStability(.Again)
        s.hard.difficulty = initDifficulty(.Hard)
        s.hard.stability = initStability(.Hard)
        s.good.difficulty = initDifficulty(.Good)
        s.good.stability = initStability(.Good)
        s.easy.difficulty = initDifficulty(.Easy)
        s.easy.stability = initStability(.Easy)
    }

    func nextDS(_ scheduling: SchedulingCards, lastDifficulty d: Double, lastStability s: Double, retrievability: Double) {
        scheduling.again.difficulty = nextDifficulty(d: d, rating: .Again)
        scheduling.again.stability = nextForgetStability(d: scheduling.again.difficulty, s: s, r: retrievability)
        scheduling.hard.difficulty = nextDifficulty(d: d, rating: .Hard)
        scheduling.hard.stability = nextRecallStability(d: scheduling.hard.difficulty, s: s, r: retrievability, rating: .Hard)
        scheduling.good.difficulty = nextDifficulty(d: d, rating: .Good)
        scheduling.good.stability = nextRecallStability(d: scheduling.good.difficulty, s: s, r: retrievability, rating: .Good)
        scheduling.easy.difficulty = nextDifficulty(d: d, rating: .Easy)
        scheduling.easy.stability = nextRecallStability(d: scheduling.easy.difficulty, s: s, r: retrievability, rating: .Easy)
    }

    func initStability(_ rating: Rating) -> Double {
        return initStability(r: rating.rawValue)
    }

    func initStability(r: Int) -> Double {
        return max(p.w[r - 1], 0.1)
    }

    func initDifficulty(_ rating: Rating) -> Double {
        return initDifficulty(r: rating.rawValue)
    }

    func initDifficulty(r: Int) -> Double {
        return min(max(p.w[4] - p.w[5] * Double(r - 3), 1.0), 10.0)
    }

    func nextInterval(s: Double) -> Double {
        let interval = s * 9 * (1 / p.requestRetention - 1)
        return min(max(round(interval), 1), p.maximumInterval)
    }

    func nextDifficulty(d: Double, rating: Rating) -> Double {
        let r = rating.rawValue
        let nextD = d - p.w[6] * Double(r - 3)
        return min(max(meanReversion(p.w[4], current: nextD), 1.0), 10.0)
    }

    func meanReversion(_ initial: Double, current: Double) -> Double {
        return p.w[7] * initial + (1 - p.w[7]) * current
    }

    func nextRecallStability(d: Double, s: Double, r: Double, rating: Rating) -> Double {
        let hardPenalty = (rating == .Hard) ? p.w[15] : 1
        let easyBonus = (rating == .Easy) ? p.w[16] : 1
        return s * (1 + exp(p.w[8]) * (11 - d) * pow(s, -p.w[9]) * (exp((1 - r) * p.w[10]) - 1) * hardPenalty * easyBonus)
    }

    func nextForgetStability(d: Double, s: Double, r: Double) -> Double {
        return p.w[11] * pow(d, -p.w[12]) * (pow(s + 1.0, p.w[13]) - 1) * exp((1 - r) * p.w[14])
    }
}

