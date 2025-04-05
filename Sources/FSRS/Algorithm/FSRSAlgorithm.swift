//
//  FSRSAlgorithm.swift
//
//  Created by nkq on 10/14/24.
//

import Foundation
/**
 * @see https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm#fsrs-45
 */
public class FSRSAlgorithm {
    /**
     * @default DECAY = -0.5
     */
    let decay = -0.5
    /**
     * FACTOR = Math.pow(0.9, 1 / DECAY) - 1= 19 / 81
     *
     * $$\text{FACTOR} = \frac{19}{81}$$
     * @default FACTOR = 19 / 81
     */
    let factor: Double = 19 / 81
    
    let defaults = FSRSDefaults()
    
    internal var parameters: FSRSParameters

    var params: FSRSParameters {
        get {
            parameters
        }
        set {
            processparameters(newValue)
        }
    }

    func processparameters(_ parameters: FSRSParameters) {
        let parameters = defaults.generatorParameters(props: parameters)
        if parameters.requestRetention.isFinite {
            do {
                intervalModifier = try calculateIntervalModifier(
                    requestRetention: parameters.requestRetention
                )
            } catch {
                print(error.localizedDescription)
            }

        }
        if parameters != self.parameters {
            self.parameters = parameters
        }
    }

    var intervalModifier: Double = 1
    var seed: String?
    
    init(parameters: FSRSParameters) {
        self.parameters = parameters
        processparameters(parameters)
    }

    /**
     * @see https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm#fsrs-45
     *
     * The formula used is: $$I(r,s) = (r^{\frac{1}{DECAY}} - 1) / FACTOR \times s$$
     * @param request_retention 0<request_retention<=1,Requested retention rate
     * @throws {Error} Requested retention rate should be in the range (0,1]
     */
    func calculateIntervalModifier(requestRetention: Double) throws -> Double {
        guard requestRetention > 0 && requestRetention <= 1 else {
            throw FSRSError(.invalidRetention, "Requested retention rate should be in the range (0,1]")
        }
        let result = (pow(requestRetention, 1 / decay) - 1.0) / factor
        return result.toFixedNumber(8)
    }

    /**
     * The formula used is :
     * $$ S_0(G) = w_{G-1}$$
     * $$S_0 = \max \lbrace S_0,0.1\rbrace $$

     * @param g Grade (rating at Anki) [1.again,2.hard,3.good,4.easy]
     * @return Stability (interval when R=90%)
     */
    func initStability(g: Rating) -> Double {
        max(parameters.w[g.rawValue - 1], 0.1)
    }

    /**
     * The formula used is :
     * $$D_0(G) = w_4 - e^{(G-1) \cdot w_5} + 1 $$
     * $$D_0 = \min \lbrace \max \lbrace D_0(G),1 \rbrace,10 \rbrace$$
     * where the $$D_0(1)=w_4$$ when the first rating is good.
     *
     * @param {Grade} g Grade (rating at Anki) [1.again,2.hard,3.good,4.easy]
     * @return {number} Difficulty $$D \in [1,10]$$
     */
    func initDifficulty(_ grade: Rating) -> Double {
        constrainDifficulty(
            r: parameters.w[4] - exp((Double(grade.rawValue) - 1) * parameters.w[5]) + 1
        )
    }

    func constrainDifficulty(r: Double) -> Double {
        min(max(r.toFixedNumber(8), 1.0), 10.0)
    }

    /**
     * If fuzzing is disabled or ivl is less than 2.5, it returns the original interval.
     * @param {number} ivl - The interval to be fuzzed.
     * @param {number} elapsed_days t days since the last review
     * @return {number} - The fuzzed interval.
     **/
    func applyFuzz(ivl: Double, elapsedDays: Double) -> Int {
        guard parameters.enableFuzz && ivl >= 2.5 else { return Int(round(ivl)) }
        let genetaor = alea(seed: seed)
        let fuzzFactor = genetaor.next()
        let ivls = FSRSHelper.getFuzzRange(
            interval: ivl,
            elapsedDays: elapsedDays,
            maximumInterval: parameters.maximumInterval
        )
        return Int(floor(fuzzFactor * (ivls.maxIvl - ivls.minIvl + 1) + ivls.minIvl))
    }

    /**
     *   @see The formula used is : {@link FSRSAlgorithm.calculate_interval_modifier}
     *   @param {number} s - Stability (interval when R=90%)
     *   @param {number} elapsed_days t days since the last review
     */
    func nextInterval(s: Double, elapsedDays: Double) -> Int {
        let newInterval = min(max(1, round(s * intervalModifier)), parameters.maximumInterval)
        return applyFuzz(ivl: newInterval, elapsedDays: elapsedDays)
    }

    /**
     * @see https://github.com/open-spaced-repetition/fsrs4anki/issues/697
     */
    func linearDamping(deltaD: Double, oldD: Double) -> Double {
        (deltaD * (10 - oldD) / 9).toFixedNumber(8)
    }
    
    /**
     * The formula used is :
     * $$\text{delta}_d = -w_6 \cdot (g - 3)$$
     * $$\text{next}_d = D + \text{linear damping}(\text{delta}_d , D)$$
     * $$D^\prime(D,R) = w_7 \cdot D_0(4) +(1 - w_7) \cdot \text{next}_d$$
     * @param {number} d Difficulty $$D \in [1,10]$$
     * @param {Grade} g Grade (rating at Anki) [1.again,2.hard,3.good,4.easy]
     * @return {number} $$\text{next}_D$$
     */
    func nextDifficulty(d: Double, g: Rating) -> Double {
        let deltaD = -(parameters.w[6] * Double(g.rawValue - 3))
        let nextD = d + linearDamping(deltaD: deltaD, oldD: d)
        return constrainDifficulty(r: meanReversion(initValue: initDifficulty(.easy), current: nextD))
    }
    
    /**
     * The formula used is :
     * $$w_7 \cdot \text{init} +(1 - w_7) \cdot \text{current}$$
     * @param {number} init $$w_2 : D_0(3) = w_2 + (R-2) \cdot w_3= w_2$$
     * @param {number} current $$D - w_6 \cdot (R - 2)$$
     * @return {number} difficulty
     */
    func meanReversion(initValue: Double, current: Double) -> Double {
        (parameters.w[7] * initValue + (1 - parameters.w[7]) * current).toFixedNumber(8)
    }

    func nextRecallStability(d: Double, s: Double, r: Double, g: Rating) -> Double {
        let hardPenalty = g == .hard ? parameters.w[15] : 1
        let easyBound = g == .easy ? parameters.w[16] : 1
        return FSRSHelper.clamp(
            s * (
                1 + exp(parameters.w[8]) * (11 - d) * pow(s, -(parameters.w[9])) *
                (exp((1 - r) * parameters.w[10]) - 1) * hardPenalty * easyBound
            ),
            0.01,
            36500
        )
        .toFixedNumber(8)
    }

    /**
     * The formula used is :
     * $$S^\prime_f(D,S,R) = w_{11}\cdot D^{-w_{12}}\cdot ((S+1)^{w_{13}}-1) \cdot e^{w_{14}\cdot(1-R)}$$
     * enable_short_term = true : $$S^\prime_f \in \min \lbrace \max \lbrace S^\prime_f,0.01\rbrace, \frac{S}{e^{w_{17} \cdot w_{18}}} \rbrace$$
     * enable_short_term = false : $$S^\prime_f \in \min \lbrace \max \lbrace S^\prime_f,0.01\rbrace, S \rbrace$$
     * @param {number} d Difficulty D \in [1,10]
     * @param {number} s Stability (interval when R=90%)
     * @param {number} r Retrievability (probability of recall)
     * @return {number} S^\prime_f new stability after forgetting
     */
    func nextForgetStability(d: Double, s: Double, r: Double) -> Double {
        let p1 = pow(d, -(parameters.w[12]))
        let p2 = pow(s + 1, parameters.w[13]) - 1
        let p3 = exp((1 - r) * parameters.w[14])
        return FSRSHelper.clamp(
            parameters.w[11] * p1 * p2 * p3,
            FSRSDefaults.S_MIN,
            36500
        ).toFixedNumber(8)
    }

    /**
     * The formula used is :
     * $$S^\prime_s(S,G) = S \cdot e^{w_{17} \cdot (G-3+w_{18})}$$
     * @param {number} s Stability (interval when R=90%)
     * @param {Grade} g Grade (Rating[0.again,1.hard,2.good,3.easy])
     */
    func nextShortTermStability(s: Double, g: Rating) -> Double {
        let part = Double(g.rawValue) - 3 + parameters.w[18]
        return FSRSHelper.clamp(
            s * exp(parameters.w[17] * part),
            FSRSDefaults.S_MIN,
            36500
        ).toFixedNumber(8)
    }

    /**
     * The formula used is :
     * $$R(t,S) = (1 + \text{FACTOR} \times \frac{t}{9 \cdot S})^{\text{DECAY}}$$
     * @param {number} elapsed_days t days since the last review
     * @param {number} stability Stability (interval when R=90%)
     * @return {number} r Retrievability (probability of recall)
     */
    func forgettingCurve(elapsedDays: Double, stability: Double) -> Double {
        pow(1 + ((factor * elapsedDays) / stability), decay).toFixedNumber(8)
    }
}
