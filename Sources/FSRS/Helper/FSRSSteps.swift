//
//  FSRSSteps.swift
//
//  Step parsing and the BasicLearningStepsStrategy used by the v6 scheduler.
//  Mirrors ts-fsrs's `strategies/learning_steps.ts` and `models.ts` step types.
//

import Foundation

/// Per-grade outcome from a learning-steps strategy.
public struct LearningStepOutcome: Equatable {
    /// Schedule the card this many minutes from now (rounded). 0 means the
    /// strategy has no opinion — the scheduler should fall through to
    /// algorithm-driven intervals.
    public let scheduledMinutes: Int
    /// `Card.learningSteps` value to set on the resulting card.
    public let nextStep: Int
}

/// Strategy signature: given parameters, the card's current state, and the
/// current step index, return per-grade outcomes. Grades not present in the
/// dictionary fall through to algorithm-driven scheduling (typical for
/// `.easy`, and for `.hard`/`.good` when no step entry applies).
public typealias LearningStepsStrategy = (
    _ params: FSRSParameters,
    _ state: CardState,
    _ curStep: Int
) -> [Rating: LearningStepOutcome]

/// Convert a step unit string (`"1m"`, `"10m"`, `"1h"`, `"1d"`) to minutes.
/// Throws if the string is malformed.
public func convertStepUnitToMinutes(_ step: String) throws -> Int {
    guard let last = step.last else {
        throw FSRSError(.invalidParam, "Empty step unit")
    }
    let valuePart = String(step.dropLast())
    guard let value = Int(valuePart), value >= 0 else {
        throw FSRSError(.invalidParam, "Invalid step value: \(step)")
    }
    switch last {
    case "m": return value
    case "h": return value * 60
    case "d": return value * 1440
    default:
        throw FSRSError(.invalidParam, "Invalid step unit: \(step), expected m/h/d")
    }
}

/// Match JavaScript `Math.round` semantics: half values round away from zero
/// (e.g. 5.5 → 6, -1.5 → -2). Swift's default `.rounded()` uses banker's
/// rounding, which would diverge on exact halves.
@inline(__always)
private func jsRound(_ x: Double) -> Int {
    Int(x.rounded(.toNearestOrAwayFromZero))
}

/// Reference learning-steps strategy mirroring ts-fsrs's
/// `BasicLearningStepsStrategy`.
///
/// Behavior:
/// - State `.review` (Again was pressed on a Review card) returns only the
///   `.again` outcome with `scheduled_minutes = relearning_steps[curStep]`,
///   pushing the card into Relearning.
/// - Otherwise, `.again` resets to the first step, `.hard` repeats the
///   current step (with a derived interval), and `.good` advances to the
///   next step (if any). `.easy` is never set — it always graduates to
///   Review via algorithm-driven scheduling.
public func basicLearningStepsStrategy(
    params: FSRSParameters,
    state: CardState,
    curStep: Int
) -> [Rating: LearningStepOutcome] {
    let steps: [String] = (state == .relearning || state == .review)
        ? params.relearningSteps
        : params.learningSteps
    let stepsLength = steps.count

    if stepsLength == 0 || curStep >= stepsLength { return [:] }

    var result: [Rating: LearningStepOutcome] = [:]

    if state == .review {
        let info = steps[max(0, curStep)]
        guard let mins = try? convertStepUnitToMinutes(info) else { return [:] }
        result[.again] = LearningStepOutcome(scheduledMinutes: mins, nextStep: 0)
        return result
    }

    let firstStep = steps[0]
    guard let firstMins = try? convertStepUnitToMinutes(firstStep) else { return [:] }

    // Hard interval:
    //   1 step  → round(first * 1.5)
    //   N steps → round((first + second) / 2)
    let hardInterval: Int
    if stepsLength == 1 {
        hardInterval = jsRound(Double(firstMins) * 1.5)
    } else {
        guard let secondMins = try? convertStepUnitToMinutes(steps[1]) else { return [:] }
        hardInterval = jsRound(Double(firstMins + secondMins) / 2.0)
    }

    result[.again] = LearningStepOutcome(scheduledMinutes: firstMins, nextStep: 0)
    result[.hard] = LearningStepOutcome(scheduledMinutes: hardInterval, nextStep: curStep)

    let nextIdx = curStep + 1
    if nextIdx < stepsLength,
       let nextMins = try? convertStepUnitToMinutes(steps[nextIdx]) {
        result[.good] = LearningStepOutcome(scheduledMinutes: nextMins, nextStep: nextIdx)
    }

    return result
}
