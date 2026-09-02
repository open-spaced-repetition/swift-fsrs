A Swift implementation of FSRS-6.0 (FSRS-5.0 supported via 19-length `w`).

[![codecov](https://codecov.io/gh/open-spaced-repetition/swift-fsrs/graph/badge.svg?token=K2C0Z5PFEH)](https://codecov.io/gh/open-spaced-repetition/swift-fsrs)

```swift
import FSRS

// v5 (default — 19-length w):
let v5 = FSRS(parameters: .init())

// v6 with ts-fsrs 5.4.2-compatible defaults, clipping, and 17/19 migration:
let v6 = FSRS(parameters: .tsFSRS6Compatible())

let card = FSRSDefaults().createEmptyCard()
let next = try v6.next(card: card, now: Date(), grade: .good).card
```

`FSRSParameters.tsFSRS6Compatible(...)` is opt-in so existing Swift clients
that rely on the legacy 19-weight default keep their current schedules. It
accepts 17-, 19-, or 21-weight vectors and produces the canonical clipped
21-weight FSRS-6 parameters used by `ts-fsrs@5.4.2`.
