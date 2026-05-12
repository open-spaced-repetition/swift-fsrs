A Swift implementation of FSRS-6.0 (FSRS-5.0 supported via 19-length `w`).

[![codecov](https://codecov.io/gh/open-spaced-repetition/swift-fsrs/graph/badge.svg?token=K2C0Z5PFEH)](https://codecov.io/gh/open-spaced-repetition/swift-fsrs)

```swift
import FSRS

// v5 (default — 19-length w):
let v5 = FSRS(parameters: .init())

// v6 — pass a 21-length w (e.g. the canonical default):
let v6 = FSRS(parameters: .init(w: FSRSDefaults.defaultWv6))

let card = FSRSDefaults().createEmptyCard()
let next = try v6.next(card: card, now: Date(), grade: .good).card
```
