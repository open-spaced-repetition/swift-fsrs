//
//  FSRSDefaults.swift
//
//  Created by nkq on 10/13/24.
//

import Foundation

public class FSRSDefaults {
    var defaultRequestRetention = 0.9
    var defaultMaximumInterval = 36500.0
    var defaultW = [
      0.4072, 1.1829, 3.1262, 15.4722, 7.2102, 0.5316, 1.0651, 0.0234, 1.616,
      0.1544, 1.0824, 1.9813, 0.0953, 0.2975, 2.2042, 0.2407, 2.9466, 0.5034,
      0.6567,
    ]
    var defaultEnableFuzz = false
    var defaultEnableShortTerm = true

    var FSRSVersion: String = "v4.4.1 using FSRS V5.0"

    func generatorParameters(props: FSRSParameters? = nil) -> FSRSParameters {
        var w = defaultW
        if let p = props {
            if p.w.count == 19 {
                w = p.w
            } else if p.w.count == 17 {
                w = p.w
                w.append(0.0)
                w.append(0.0)
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
