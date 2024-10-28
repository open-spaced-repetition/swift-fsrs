//
//  FSRSTypes.swift
//
//  Created by nkq on 10/13/24.
//

import Foundation

public struct IPreview {
    var recordLog: RecordLog
    
    init(recordLog: RecordLog) {
        self.recordLog = recordLog
    }
    
    subscript(rating: Rating) -> RecordLogItem? {
        get {
            recordLog[rating]
        }
        set {
            recordLog[rating] = newValue
        }
    }
}

public protocol IScheduler {
    var preview: IPreview { get }
    func review(_ g: Rating) -> RecordLogItem
}

/**
 * Options for rescheduling.
 *
 * @template T - The type of the result returned by the `recordLogHandler` function.
 */
public struct RescheduleOptions {
    /**
     * A function that handles recording the log.
     *
     * @param recordLog - The log to be recorded.
     * @returns The result of recording the log.
     */
    var recordLogHandler: ((_ recordLog: RecordLogItem?) -> RecordLogItem?)?

    /**
     * A function that defines the order of reviews.
     *
     * @param a - The first FSRSHistory object.
     * @param b - The second FSRSHistory object.
     */
    var reviewsOrderBy: ((_ a: ReviewLog, _ b: ReviewLog) -> Bool)?

    /**
     * Indicating whether to skip manual steps.
     */
    var skipManual: Bool = true

    /**
     * Indicating whether to update the FSRS memory state.
     */
    var updateMemoryState: Bool = false

    /**
     * The current date and time.
     */
    var now: Date = Date()

    /**
     * The input for the first card.
     */
    var firstCard: Card?
}

public struct IReschedule: Equatable {
    var collections: [RecordLogItem?]
    var rescheduleItem: RecordLogItem?
}
