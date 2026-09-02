//
//  FSRSTypes.swift
//
//  Created by nkq on 10/13/24.
//

import Foundation

public struct IPreview: Sendable {
    var recordLog: RecordLog

    init(recordLog: RecordLog) {
        self.recordLog = recordLog
    }

    public subscript(rating: Rating) -> RecordLogItem? {
        get {
            recordLog[rating]
        }
        set {
            recordLog[rating] = newValue
        }
    }
}

public protocol IScheduler {
    var preview: IPreview { get throws }
    func review(_ g: Rating) throws -> RecordLogItem
}

/**
 * Options for rescheduling.
 *
 * @template T - The type of the result returned by the `recordLogHandler` function.
 */
public struct RescheduleOptions: Sendable {
    /**
     * A function that handles recording the log.
     *
     * @param recordLog - The log to be recorded.
     * @returns The result of recording the log.
     */
    public var recordLogHandler: (@Sendable (_ recordLog: RecordLogItem?) -> RecordLogItem?)?

    /**
     * A function that defines the order of reviews.
     *
     * @param a - The first FSRSHistory object.
     * @param b - The second FSRSHistory object.
     */
    public var reviewsOrderBy: (@Sendable (_ a: ReviewLog, _ b: ReviewLog) -> Bool)?

    /**
     * Indicating whether to skip manual steps.
     */
    public var skipManual: Bool

    /**
     * Indicating whether to update the FSRS memory state.
     */
    public var updateMemoryState: Bool

    /**
     * The current date and time.
     */
    public var now: Date

    /**
     * The input for the first card.
     */
    public var firstCard: Card?

    public init(
        recordLogHandler: (@Sendable (_ recordLog: RecordLogItem?) -> RecordLogItem?)? = nil,
        reviewsOrderBy: (@Sendable (_ a: ReviewLog, _ b: ReviewLog) -> Bool)? = nil,
        skipManual: Bool = true,
        updateMemoryState: Bool = false,
        now: Date = Date(),
        firstCard: Card? = nil
    ) {
        self.recordLogHandler = recordLogHandler
        self.reviewsOrderBy = reviewsOrderBy
        self.skipManual = skipManual
        self.updateMemoryState = updateMemoryState
        self.now = now
        self.firstCard = firstCard
    }
}

public struct IReschedule: Equatable, Sendable {
    public var collections: [RecordLogItem?]
    public var rescheduleItem: RecordLogItem?

    public init(collections: [RecordLogItem?], rescheduleItem: RecordLogItem?) {
        self.collections = collections
        self.rescheduleItem = rescheduleItem
    }
}
