//
//  FSRSDefaults.swift
//
//  Created by nkq on 10/13/24.
//

import Foundation

/// Algorithm version, derived from the length of the `w` parameter vector.
///
/// - `.v5` — 19-element `w` (legacy default, frozen for parity with existing tests).
/// - `.v6` — 21-element `w` (FSRS-6.0). `w[19]` is the short-term last-stability
///   exponent; `w[20]` is the learnable decay (defaults to 0.1542).
public enum FSRSAlgorithmVersion: Equatable {
    case v5
    case v6

    /// Infer version from a `w` vector. 19-length is v5; 21-length is v6.
    /// 17-length (legacy v4) is treated as v5 because the existing migration
    /// path pads to 19, not 21.
    public static func detect(_ w: [Double]) -> FSRSAlgorithmVersion {
        w.count == 21 ? .v6 : .v5
    }
}

public class FSRSDefaults {
    /// Lower bound for stability under FSRS-5 semantics.
    static let S_MIN = 0.01
    /// Lower bound for stability under FSRS-6 semantics (matches upstream ts-fsrs).
    static let S_MIN_V6 = 0.001
    static let INIT_S_MAX = 100.0

    /// Decay value that, when used as `w[20]`, makes v6's learnable decay match v5's
    /// constant `decay = -0.5` (i.e. `factor = 19/81`). Used when migrating 17- or
    /// 19-length parameters into v6 land.
    static let FSRS5_DEFAULT_DECAY = 0.5
    /// Default decay for fresh v6 models (canonical value from ts-fsrs).
    static let FSRS6_DEFAULT_DECAY = 0.1542

    /// Default ceiling for `w[17]` and `w[18]` when relearning_steps is empty
    /// or has length ≤ 1. ts-fsrs derives a tighter ceiling from the relearning
    /// steps count when > 1 (see `clampParametersV6`).
    static let W17_W18_CEILING = 2.0

    static let CLAMP_PARAMETERS = [
        [S_MIN, INIT_S_MAX] /** initial stability (Again) */,
        [S_MIN, INIT_S_MAX] /** initial stability (Hard) */,
        [S_MIN, INIT_S_MAX] /** initial stability (Good) */,
        [S_MIN, INIT_S_MAX] /** initial stability (Easy) */,
        [1.0, 10.0] /** initial difficulty (Good) */,
        [0.001, 4.0] /** initial difficulty (multiplier) */,
        [0.001, 4.0] /** difficulty (multiplier) */,
        [0.001, 0.75] /** difficulty (multiplier) */,
        [0.0, 4.5] /** stability (exponent) */,
        [0.0, 0.8] /** stability (negative power) */,
        [0.001, 3.5] /** stability (exponent) */,
        [0.001, 5.0] /** fail stability (multiplier) */,
        [0.001, 0.25] /** fail stability (negative power) */,
        [0.001, 0.9] /** fail stability (power) */,
        [0.0, 4.0] /** fail stability (exponent) */,
        [0.0, 1.0] /** stability (multiplier for Hard) */,
        [1.0, 6.0] /** stability (multiplier for Easy) */,
        [0.0, 2.0] /** short-term stability (exponent) */,
        [0.0, 2.0] /** short-term stability (exponent) */,
    ]

    /// V6 clamp ranges. Mirrors ts-fsrs's CLAMP_PARAMETERS function: rows 17/18
    /// share a configurable ceiling; row 19 (short-term last-stability exponent)
    /// has a lower bound that depends on `enable_short_term`; row 20 is decay.
    static func clampParametersV6(
        w17W18Ceiling: Double = W17_W18_CEILING,
        enableShortTerm: Bool = true
    ) -> [[Double]] {
        let base = CLAMP_PARAMETERS
            .prefix(17)
            .map { $0 } + [
                [0.0, w17W18Ceiling] /** short-term stability (exponent) */,
                [0.0, w17W18Ceiling] /** short-term stability (exponent) */,
                [enableShortTerm ? 0.01 : 0.0, 0.8] /** short-term last-stability (exponent) */,
                [0.1, 0.8] /** decay */,
            ]
        return base
    }

    /// Compute the dynamic `w17_w18_ceiling` from the relearning step count.
    /// Mirrors ts-fsrs's clipParameters derivation exactly.
    static func computeW17W18Ceiling(parameters: [Double], numRelearningSteps: Int) -> Double {
        guard max(0, numRelearningSteps) > 1 else { return W17_W18_CEILING }
        // PLS = w11 * D ^ -w12 * [(S + 1) ^ w13 - 1] * e ^ (w14 * (1 - R))
        // Given D = 1, R = 0.7, S = 1, this collapses to:
        //   PLS = w11 * (2 ^ w13 - 1) * e ^ (w14 * 0.3)
        // We require PLS * e ^ (n * w17 * w18) ≤ S = 1, so:
        //   n * w17 * w18 ≤ -[ln(w11) + ln(2 ^ w13 - 1) + w14 * 0.3]
        let value = -(
            log(parameters[11]) +
            log(pow(2.0, parameters[13]) - 1.0) +
            parameters[14] * 0.3
        ) / Double(numRelearningSteps)
        return FSRSHelper.clamp(value.toFixedNumber(8), 0.01, 2.0)
    }

    var defaultRequestRetention = 0.9
    var defaultMaximumInterval = 36500.0
    let defaultW = [
        0.40255, 1.18385, 3.173, 15.69105, 7.1949,
        0.5345, 1.4604, 0.0046, 1.54575, 0.1192,
        1.01925, 1.9395, 0.11, 0.29605, 2.2698,
        0.2315, 2.9898, 0.51655, 0.6621
    ]
    /// Canonical FSRS-6.0 default `w` (21 elements). Pass this to `FSRSParameters`
    /// to opt in to v6 semantics.
    public static let defaultWv6: [Double] = [
        0.212, 1.2931, 2.3065, 8.2956, 6.4133,
        0.8334, 3.0194, 0.001, 1.8722, 0.1666,
        0.796, 1.4835, 0.0614, 0.2629, 1.6483,
        0.6014, 1.8729, 0.5425, 0.0912, 0.0658,
        FSRS6_DEFAULT_DECAY,
    ]
    var defaultEnableFuzz = false
    var defaultEnableShortTerm = true

    /// Default learning steps used by v6 schedulers (no effect under v5).
    public static let defaultLearningSteps: [String] = ["1m", "10m"]
    /// Default relearning steps used by v6 schedulers (no effect under v5).
    public static let defaultRelearningSteps: [String] = ["10m"]

    var FSRSVersion: String = "v5.1.0 using FSRS-5.0"

    func generatorParameters(props: FSRSParameters? = nil) -> FSRSParameters {
        var w = defaultW
        let inputCount = props?.w.count ?? -1

        if let p = props {
            switch p.w.count {
            case 21:
                w = p.w
            case 19:
                w = p.w
            case 17:
                w = p.w
                w.append(0.0)
                w.append(0.0)
                w[4] = (w[5] * 2.0 + w[4]).toFixedNumber(8)
                w[5] = (log(w[5] * 3.0 + 1.0) / 3.0).toFixedNumber(8)
                w[6] = (w[6] + 0.5).toFixedNumber(8)
                print("[FSRS V5]auto fill w to 19 length")
            default:
                break
            }
        }

        let enableShortTerm = props?.enableShortTerm ?? defaultEnableShortTerm
        let learningSteps = props?.learningSteps ?? Self.defaultLearningSteps
        let relearningSteps = props?.relearningSteps ?? Self.defaultRelearningSteps

        // Pick the right clamp table based on the (possibly migrated) w length.
        let clampTable: [[Double]]
        if w.count == 21 {
            let ceiling = Self.computeW17W18Ceiling(
                parameters: w,
                numRelearningSteps: relearningSteps.count
            )
            clampTable = Self.clampParametersV6(
                w17W18Ceiling: ceiling,
                enableShortTerm: enableShortTerm
            )
        } else {
            clampTable = Self.CLAMP_PARAMETERS
        }

        w = w.enumerated().map({
            FSRSHelper.clamp($0.element, clampTable[$0.offset][0], clampTable[$0.offset][1])
        })

        // 17→19 (legacy v4→v5) was already handled above. Note: we deliberately do
        // NOT auto-migrate 19→21. Callers who want v6 must pass a 21-length w
        // (e.g. FSRSDefaults.defaultWv6) — silent migration would change behavior.
        _ = inputCount

        return FSRSParameters(
            requestRetention: props?.requestRetention ?? defaultRequestRetention,
            maximumInterval: props?.maximumInterval ?? defaultMaximumInterval,
            w: w,
            enableFuzz: props?.enableFuzz ?? defaultEnableFuzz,
            enableShortTerm: enableShortTerm,
            learningSteps: learningSteps,
            relearningSteps: relearningSteps
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
