//
//  FSRSDefaults.swift
//
//  Created by nkq on 10/13/24.
//

import Foundation

public class FSRSDefaults {
    static let S_MIN = 0.01

    var defaultRequestRetention = 0.9
    var defaultMaximumInterval = 36500.0
    var defaultW = [
        0.40255, 1.18385, 3.173, 15.69105, 7.1949,
        0.5345, 1.4604, 0.0046, 1.54575, 0.1192,
        1.01925, 1.9395, 0.11, 0.29605, 2.2698,
        0.2315, 2.9898, 0.51655, 0.6621
    ]
    var defaultEnableFuzz = false
    var defaultEnableShortTerm = true

    var FSRSVersion: String = "v5.1.0 using FSRS-5.0"

    func generatorParameters(props: FSRSParameters? = nil) -> FSRSParameters {
        var w = defaultW
        if let p = props {
            if p.w.count == 19 {
                w = p.w
            } else if p.w.count == 17 {
                w = p.w
                w.append(0.0)
                w.append(0.0)
                w[4] = (w[5] * 2.0 + w[4]).toFixedNumber(8)
                w[5] = (log(w[5] * 3.0 + 1.0) / 3.0).toFixedNumber(8)
                w[6] = (w[6] + 0.5).toFixedNumber(8)
                print("[FSRS V5]auto fill w to 19 length")
            }
        }

        return FSRSParameters(
            requestRetention: props?.requestRetention ?? defaultRequestRetention,
            maximumInterval: props?.maximumInterval ?? defaultMaximumInterval,
            w: w,
            enableFuzz: props?.enableFuzz ?? defaultEnableFuzz,
            enableShortTerm: props?.enableShortTerm ?? defaultEnableShortTerm
        )
    }

    
    /**
     * Create an empty card
     * @param now Current time
     * @param afterHandler Convert the result to another type. (Optional)
     * @example
     * ```
     * const card: Card = createEmptyCard(new Date());
     * ```
     * @example
     * ```
     * interface CardUnChecked
     *   extends Omit<Card, "due" | "last_review" | "state"> {
     *   cid: string;
     *   due: Date | number;
     *   last_review: Date | null | number;
     *   state: StateType;
     * }
     *
     * function cardAfterHandler(card: Card) {
     *      return {
     *       ...card,
     *       cid: "test001",
     *       state: State[card.state],
     *       last_review: card.last_review ?? null,
     *     } as CardUnChecked;
     * }
     *
     * const card: CardUnChecked = createEmptyCard(new Date(), cardAfterHandler);
     * ```
     */
    func createEmptyCard(now: Date = Date(), afterHandler: ((Card) -> Card)? = nil) -> Card {
        let card = Card(due: now)
        return afterHandler?(card) ?? card
    }
}
