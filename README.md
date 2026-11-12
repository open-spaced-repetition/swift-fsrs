# swift-fsrs

[![codecov](https://codecov.io/gh/open-spaced-repetition/swift-fsrs/graph/badge.svg?token=K2C0Z5PFEH)](https://codecov.io/gh/open-spaced-repetition/swift-fsrs)

A Swift implementation of the [FSRS](https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm) spaced repetition scheduler. It supports FSRS-6 and FSRS-5 and follows [ts-fsrs](https://github.com/open-spaced-repetition/ts-fsrs).

## Installation

Add the package in Xcode, or in `Package.swift`:

```swift
.package(url: "https://github.com/open-spaced-repetition/swift-fsrs", from: "6.0.0")
```

and add the `FSRS` product to your target:

```swift
.product(name: "FSRS", package: "swift-fsrs")
```

Requires iOS 14 or macOS 10.13.

## Usage

```swift
import FSRS

let fsrs = FSRS(parameters: .init(w: FSRSDefaults.defaultWv6))
let card = FSRSDefaults().createEmptyCard()
let now = Date()

// Rate the card
let result = try fsrs.next(card: card, now: now, grade: .good)
let updated = result.card   // save this
let log = result.log        // and this, if you keep a review history

// Or look at all four ratings before the user picks one
let preview = try fsrs.repeat(card: card, now: now)
let dueIfEasy = preview[.easy]?.card.due
```

`FSRS` is immutable and `Sendable`, so one instance can be shared across tasks.

## FSRS-5 or FSRS-6

The algorithm version follows the length of `w`:

- 21 weights: FSRS-6. Use `FSRSDefaults.defaultWv6` or your own optimized weights.
- 19 weights: FSRS-5. This is what `FSRSParameters()` gives you when `w` is left out, so existing setups keep their scheduling.

With FSRS-6 the learning and relearning steps are configurable:

```swift
let params = FSRSParameters(
    w: FSRSDefaults.defaultWv6,
    learningSteps: ["1m", "10m"],
    relearningSteps: ["10m"]
)
```

## Upgrading from 5.x

- `repeat` now throws, like `next`.
- Parameters can't be changed after `FSRS` is created. Make a new instance instead.
- `Card` and `ReviewLog` have a new `learningSteps` field. Data saved by older versions still decodes.
- The default FSRS-5 weights were updated to match ts-fsrs, so intervals with default parameters shift slightly.
- Elapsed days are counted by UTC calendar day rather than by 24-hour periods.
