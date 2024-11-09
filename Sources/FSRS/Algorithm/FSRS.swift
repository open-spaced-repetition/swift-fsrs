//
//  FSRS.swift
//
//  Created by nkq on 10/13/24.
//

import Foundation

public class FSRS: FSRSAlgorithm {
    
    override func processparameters(_ parameters: FSRSParameters) {
        let parameters = defaults.generatorParameters(props: parameters)
        if parameters.requestRetention.isFinite {
            do {
                intervalModifier = try calculateIntervalModifier(requestRetention: parameters.requestRetention)
            } catch {
                print(error.localizedDescription)
            }
        }
        if parameters != self.parameters {
            self.parameters = parameters
        }
    }
    
    override public init(parameters: FSRSParameters) {
        super.init(parameters: parameters)
    }
    
    /**
     * Display the collection of cards and logs for the four scenarios after scheduling the card at the current time.
     * @param card Card to be processed
     * @param now Current time or scheduled time
     * @param afterHandler Convert the result to another type. (Optional)
     * @example
     * ```
     * const card: Card = createEmptyCard(new Date());
     * const f = fsrs();
     * const recordLog = f.repeat(card, new Date());
     * ```
     * @example
     * ```
     * interface RevLogUnchecked
     *   extends Omit<ReviewLog, "due" | "review" | "state" | "rating"> {
     *   cid: string;
     *   due: Date | number;
     *   state: StateType;
     *   review: Date | number;
     *   rating: RatingType;
     * }
     *
     * interface RepeatRecordLog {
     *   card: CardUnChecked; //see method: createEmptyCard
     *   log: RevLogUnchecked;
     * }
     *
     * function repeatAfterHandler(recordLog: RecordLog) {
     *     const record: { [key in Grade]: RepeatRecordLog } = {} as {
     *       [key in Grade]: RepeatRecordLog;
     *     };
     *     for (const grade of Grades) {
     *       record[grade] = {
     *         card: {
     *           ...(recordLog[grade].card as Card & { cid: string }),
     *           due: recordLog[grade].card.due.getTime(),
     *           state: State[recordLog[grade].card.state] as StateType,
     *           last_review: recordLog[grade].card.last_review
     *             ? recordLog[grade].card.last_review!.getTime()
     *             : null,
     *         },
     *         log: {
     *           ...recordLog[grade].log,
     *           cid: (recordLog[grade].card as Card & { cid: string }).cid,
     *           due: recordLog[grade].log.due.getTime(),
     *           review: recordLog[grade].log.review.getTime(),
     *           state: State[recordLog[grade].log.state] as StateType,
     *           rating: Rating[recordLog[grade].log.rating] as RatingType,
     *         },
     *       };
     *     }
     *     return record;
     * }
     * const card: Card = createEmptyCard(new Date(), cardAfterHandler); //see method:  createEmptyCard
     * const f = fsrs();
     * const recordLog = f.repeat(card, new Date(), repeatAfterHandler);
     * ```
     */
    public func `repeat`(
        card: Card,
        now: Date,
        _ completion: ((_ log: IPreview) -> IPreview)? = nil
    ) -> IPreview {
        let obj = params.enableShortTerm
        ? BasicScheduler(card: card, reviewTime: now, algorithm: self)
        : LongTermScheduler(card: card, reviewTime: now, algorithm: self)
        let log = obj.preview
        if let completion = completion {
            return completion(log)
        } else {
            return log
        }
    }
    
    /**
     * Display the collection of cards and logs for the card scheduled at the current time, after applying a specific grade rating.
     * @param card Card to be processed
     * @param now Current time or scheduled time
     * @param grade Rating of the review (Again, Hard, Good, Easy)
     * @param afterHandler Convert the result to another type. (Optional)
     * @example
     * ```
     * const card: Card = createEmptyCard(new Date());
     * const f = fsrs();
     * const recordLogItem = f.next(card, new Date(), Rating.Again);
     * ```
     * @example
     * ```
     * interface RevLogUnchecked
     *   extends Omit<ReviewLog, "due" | "review" | "state" | "rating"> {
     *   cid: string;
     *   due: Date | number;
     *   state: StateType;
     *   review: Date | number;
     *   rating: RatingType;
     * }
     *
     * interface NextRecordLog {
     *   card: CardUnChecked; //see method: createEmptyCard
     *   log: RevLogUnchecked;
     * }
     *
     function nextAfterHandler(recordLogItem: RecordLogItem) {
     const recordItem = {
     card: {
     ...(recordLogItem.card as Card & { cid: string }),
     due: recordLogItem.card.due.getTime(),
     state: State[recordLogItem.card.state] as StateType,
     last_review: recordLogItem.card.last_review
     ? recordLogItem.card.last_review!.getTime()
     : null,
     },
     log: {
     ...recordLogItem.log,
     cid: (recordLogItem.card as Card & { cid: string }).cid,
     due: recordLogItem.log.due.getTime(),
     review: recordLogItem.log.review.getTime(),
     state: State[recordLogItem.log.state] as StateType,
     rating: Rating[recordLogItem.log.rating] as RatingType,
     },
     };
     return recordItem
     }
     * const card: Card = createEmptyCard(new Date(), cardAfterHandler); //see method:  createEmptyCard
     * const f = fsrs();
     * const recordLogItem = f.repeat(card, new Date(), Rating.Again, nextAfterHandler);
     * ```
     */
    func next(
        card: Card,
        now: Date,
        grade: Rating,
        completion: ((_ log: RecordLogItem) -> RecordLogItem)? = nil
    ) throws -> RecordLogItem {
        if grade == .manual {
            throw FSRSError(.invalidRating, "Cannot review a manual rating")
        }
        let obj = params.enableShortTerm
        ? BasicScheduler(card: card, reviewTime: now, algorithm: self)
        : LongTermScheduler(card: card, reviewTime: now, algorithm: self)
        let log = obj.review(grade)
        if let completion = completion {
            return completion(log)
        } else {
            return log
        }
    }
    
    /**
     * Get the retrievability of the card
     * @param card  Card to be processed
     * @param now  Current time or scheduled time
     * @param format  default:true , Convert the result to another type. (Optional)
     * @returns  The retrievability of the card,if format is true, the result is a string, otherwise it is a number
     */
    func getRetrievability(
        card: Card,
        now: Date = Date()
    ) -> (string: String, number: Double) {
        let processed = card.newCard
        let time = processed.state != .new
        ? max(Date.dateDiff(now: now, pre: processed.lastReview, unit: .days), 0)
        : 0
        let retrievability = processed.state != .new
        ? forgettingCurve(elapsedDays: time, stability: processed.stability.toFixedNumber(8))
        : 0
        return ("\((retrievability * 100).toFixed(2))%", retrievability)
    }
    
    /**
     *
     * @param card Card to be processed
     * @param log last review log
     * @param afterHandler Convert the result to another type. (Optional)
     * @example
     * ```
     * const now = new Date();
     * const f = fsrs();
     * const emptyCardFormAfterHandler = createEmptyCard(now);
     * const repeatFormAfterHandler = f.repeat(emptyCardFormAfterHandler, now);
     * const { card, log } = repeatFormAfterHandler[Rating.Hard];
     * const rollbackFromAfterHandler = f.rollback(card, log);
     * ```
     *
     * @example
     * ```
     * const now = new Date();
     * const f = fsrs();
     * const emptyCardFormAfterHandler = createEmptyCard(now, cardAfterHandler);  //see method: createEmptyCard
     * const repeatFormAfterHandler = f.repeat(emptyCardFormAfterHandler, now, repeatAfterHandler); //see method: fsrs.repeat()
     * const { card, log } = repeatFormAfterHandler[Rating.Hard];
     * const rollbackFromAfterHandler = f.rollback(card, log, cardAfterHandler);
     * ```
     */
    func rollback(
        card: Card,
        log: ReviewLog,
        completion: ((Card) -> Card)? = nil
    ) throws -> Card {
        let processdCard = card.newCard
        let processedLog = log.newLog
        
        guard processedLog.rating != .manual else {
            throw FSRSError(.invalidRating, "Cannot rollback a manual rating")
        }
        var lastDue: Date, lastReview: Date?, lastLapses: Int
        guard let state = processedLog.state else {
            throw FSRSError(.invalidParam, "Rollback card must have a state")
        }
        switch state {
        case .new:
            guard let due = processedLog.due else {
                throw FSRSError(.invalidParam, "Rollback card must have a due date")
            }
            lastDue = due
            lastReview = nil
            lastLapses = 0
        case .learning, .review, .relearning:
            lastDue = processedLog.review
            lastReview = processedLog.due
            lastLapses = processdCard.lapses - (
                (processedLog.rating == .again && processedLog.state == .review) ? 1 : 0
            )
        }
        var previousCard = processdCard.newCard
        previousCard.due = lastDue
        previousCard.stability = processedLog.stability ?? 0
        previousCard.difficulty = processedLog.difficulty ?? 0
        previousCard.elapsedDays = processedLog.lastElapsedDays
        previousCard.scheduledDays = processedLog.scheduledDays
        previousCard.reps = max(0, processdCard.reps - 1)
        previousCard.lapses = max(0, lastLapses)
        previousCard.state = state
        previousCard.lastReview = lastReview
        
        if let completion = completion {
            return completion(previousCard)
        } else {
            return previousCard
        }
    }
    
    /**
     *
     * @param card Card to be processed
     * @param now Current time or scheduled time
     * @param reset_count Should the review count information(reps,lapses) be reset. (Optional)
     * @param afterHandler Convert the result to another type. (Optional)
     * @example
     * ```
     * const now = new Date();
     * const f = fsrs();
     * const emptyCard = createEmptyCard(now);
     * const scheduling_cards = f.repeat(emptyCard, now);
     * const { card, log } = scheduling_cards[Rating.Hard];
     * const forgetCard = f.forget(card, new Date(), true);
     * ```
     *
     * @example
     * ```
     * interface RepeatRecordLog {
     *   card: CardUnChecked; //see method: createEmptyCard
     *   log: RevLogUnchecked; //see method: fsrs.repeat()
     * }
     *
     * function forgetAfterHandler(recordLogItem: RecordLogItem): RepeatRecordLog {
     *     return {
     *       card: {
     *         ...(recordLogItem.card as Card & { cid: string }),
     *         due: recordLogItem.card.due.getTime(),
     *         state: State[recordLogItem.card.state] as StateType,
     *         last_review: recordLogItem.card.last_review
     *           ? recordLogItem.card.last_review!.getTime()
     *           : null,
     *       },
     *       log: {
     *         ...recordLogItem.log,
     *         cid: (recordLogItem.card as Card & { cid: string }).cid,
     *         due: recordLogItem.log.due.getTime(),
     *         review: recordLogItem.log.review.getTime(),
     *         state: State[recordLogItem.log.state] as StateType,
     *         rating: Rating[recordLogItem.log.rating] as RatingType,
     *       },
     *     };
     * }
     * const now = new Date();
     * const f = fsrs();
     * const emptyCardFormAfterHandler = createEmptyCard(now, cardAfterHandler); //see method:  createEmptyCard
     * const repeatFormAfterHandler = f.repeat(emptyCardFormAfterHandler, now, repeatAfterHandler); //see method: fsrs.repeat()
     * const { card } = repeatFormAfterHandler[Rating.Hard];
     * const forgetFromAfterHandler = f.forget(card, date_scheduler(now, 1, true), false, forgetAfterHandler);
     * ```
     */
    func forget(
        card: Card,
        now: Date,
        resetCount: Bool = false,
        _ completion: ((_ recordLogItem: RecordLogItem) -> RecordLogItem)? = nil
    ) -> RecordLogItem {
        let processedCard = card.newCard
        let scheduledDay = processedCard.state == .new
        ? 0
        : Date.dateDiff(now: now, pre: processedCard.lastReview, unit: .days)
        let forgetLog = ReviewLog(
            rating: .manual,
            state: processedCard.state,
            due: processedCard.due,
            stability: processedCard.stability,
            difficulty: processedCard.difficulty,
            elapsedDays: 0,
            lastElapsedDays: processedCard.elapsedDays,
            scheduledDays: scheduledDay,
            review: now
        )
        let forgetCard = Card(
            due: now,
            reps: resetCount ? 0 : processedCard.reps,
            lapses: resetCount ? 0 : processedCard.lapses,
            state: .new,
            lastReview: processedCard.lastReview
        )
        let log = RecordLogItem(card: forgetCard, log: forgetLog)
        if let completion = completion {
            return completion(log)
        } else {
            return log
        }
    }


    /**
     * Reschedules the current card and returns the rescheduled collections and reschedule item.
     *
     * @template T - The type of the record log item.
     * @param {CardInput | Card} current_card - The current card to be rescheduled.
     * @param {Array<FSRSHistory>} reviews - The array of FSRSHistory objects representing the reviews.
     * @param {Partial<RescheduleOptions<T>>} options - The optional reschedule options.
     * @returns {IReschedule<T>} - The rescheduled collections and reschedule item.
     *
     * @example
     * ```
      const f = fsrs()
          const grades: Grade[] = [Rating.Good, Rating.Good, Rating.Good, Rating.Good]
          const reviews_at = [
            new Date(2024, 8, 13),
            new Date(2024, 8, 13),
            new Date(2024, 8, 17),
            new Date(2024, 8, 28),
          ]

          const reviews: FSRSHistory[] = []
          for (let i = 0; i < grades.length; i++) {
            reviews.push({
              rating: grades[i],
              review: reviews_at[i],
            })
          }

          const results_short = scheduler.reschedule(
            createEmptyCard(),
            reviews,
            {
              skipManual: false,
            }
          )
          console.log(results_short)
     * ```
     */
    func reschedule(
        currentCard: Card,
        reviews: [ReviewLog],
        options: RescheduleOptions
    ) throws -> IReschedule {
        var reviews = reviews
        if let sortOrder = options.reviewsOrderBy {
            reviews.sort(by: sortOrder)
        }
        if options.skipManual {
            reviews = reviews.filter({ $0.rating != .manual })
        }
        let rescheduleSvc = FSRSReschedule(fsrs: self)
        let items = try rescheduleSvc.reschedule(
            currentCard: options.firstCard ?? FSRSDefaults().createEmptyCard(),
            reviews: reviews
        )
        
        let curCard = currentCard.newCard
        let manualItem = try rescheduleSvc.calculateManualRecord(
            currentCard: curCard,
            now: options.now,
            recordLogItem: items.last ?? nil,
            updateMemory: options.updateMemoryState
        )
        if let handler = options.recordLogHandler {
            return .init(
                collections: items.map(handler),
                rescheduleItem: manualItem == nil ? nil : handler(manualItem)
            )
        } else {
            return .init(collections: items, rescheduleItem: manualItem)
        }
    }
}
