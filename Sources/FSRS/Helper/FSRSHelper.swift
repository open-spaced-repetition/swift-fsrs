//
//  FSRSHelper.swift
//
//  Created by nkq on 10/14/24.
//

import Foundation

class FSRSHelper {
    struct FuzzRange {
        let start: Double
        let end: Double
        let factor: Double
    }
    
    static let fuzzRanges = [
        FuzzRange(start: 2.5, end: 7.0, factor: 0.15),
        .init(start: 7.0, end: 20.0, factor: 0.1),
        .init(start: 20, end: .infinity, factor: 0.05)
    ]
    
    static func getFuzzRange(
        interval: Double,
        elapsedDays: Double,
        maximumInterval: Double
    ) -> (minIvl: Double, maxIvl: Double) {
        var delta = 1.0
        for range in fuzzRanges {
            delta += range.factor * max(min(interval, range.end) - range.start, 0.0)
        }
        let newInterval = min(interval, maximumInterval)
        var minIvl = max(2, round(newInterval - delta))
        let maxIvl = min(round(newInterval + delta), maximumInterval)
        if newInterval > elapsedDays {
            minIvl = max(minIvl, elapsedDays + 1)
        }
        minIvl = min(minIvl, maxIvl)
        return (minIvl, maxIvl)
    }

    static func clamp(_ value: Double, _ minV: Double, _ maxV: Double) -> Double {
        min(max(value, minV), maxV)
    }
}

public struct FSRSError: Error, Equatable {
    enum Reason: String, Error {
        case invalidInterval
        case invalidRating
        case invalidRetention
        case invalidParam
    }
    var errorReason: Reason
    var message: String?
    
    init(_ errorReason: Reason, _ message: String? = nil) {
        self.message = message
        self.errorReason = errorReason
    }
}

extension Date {
    
    enum TimeUnit: String, Codable {
        case days
        case minutes
    }

    /**
     * 计算日期和时间的偏移，并返回一个新的日期对象。
     * @param now 当前日期和时间
     * @param t 时间偏移量，当 isDay 为 true 时表示天数，为 false 时表示分钟
     * @param unit （可选）是否按天数单位进行偏移，默认为 minutes，表示按分钟单位计算偏移
     * @returns 偏移后的日期和时间对象
     */
    static func dateScheduler(now: Date, t: Double, unit: TimeUnit = .minutes) -> Date {
        Date(timeIntervalSince1970:
            unit == .days
             ? now.timeIntervalSince1970 + t * 24 * 60 * 60
             : now.timeIntervalSince1970 + t * 60
        )
    }

    static func dateDiff(now: Date, pre: Date?, unit: TimeUnit) -> Double {
        guard let pre = pre else { return 0.0 }
        let diff = now.timeIntervalSince1970 - pre.timeIntervalSince1970
        var r = 0.0
        switch unit {
        case .days:
            r = floor(diff / (24 * 60 * 60))
        case .minutes:
            r = floor(diff / 60)
        }
        return r
    }

    static func dateDiffInDays(from last: Date?, to cur: Date) -> Double {
        guard let last = last else { return 0.0 }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .autoupdatingCurrent
        let startOfLast = calendar.startOfDay(for: last)
        let startOfCur = calendar.startOfDay(for: cur)
        return floor((startOfCur.timeIntervalSince1970 - startOfLast.timeIntervalSince1970) / (24 * 60 * 60))
    }

    func toString(_ dateFormat: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        return formatter.string(from: self)
    }

    static func formatDate(date: Date) -> String {
        date.toString("yyyy-MM-dd HH:mm:ss") ?? ""
    }

    static func fromString(_ date: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let gmt = TimeZone(secondsFromGMT: 0) {
            formatter.timeZone = gmt
        }
        return formatter.date(from: date)
    }

    static let timeUnit = [60.0, 60, 24, 31, 12]
    static let timeUnitsFormat = ["second", "min", "hour", "day", "month", "year"]
    static func showDiffMessage(
        _ due: Date,
        _ lastReview: Date,
        _ detailed: Bool = false,
        _ unit: [String] = timeUnitsFormat
    ) -> String {
        var unit = unit
        if unit.count != timeUnitsFormat.count {
            unit = timeUnitsFormat
        }
        var diff = due.timeIntervalSince1970 - lastReview.timeIntervalSince1970
        var i = 0
        for (index, unit) in timeUnit.enumerated() {
            if diff < unit {
                i = index
                break
            } else {
                diff /= unit
            }
            i += 1
        }
        return "\(Int(floor(diff)))\(detailed ? (unit[i]) : "")"
    }
}

extension Double {
    func toFixed(_ places: Int) -> String {
        return String(format: "%.\(places)f", self)
    }

    func toFixedNumber(_ places: Int) -> Double {
        return Double(String(format: "%.\(places)f", self)) ?? 0
    }
}
