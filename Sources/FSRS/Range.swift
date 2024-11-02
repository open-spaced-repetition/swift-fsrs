extension ClosedRange {
    func clamp(_ bound: Bound) -> Bound {
        Swift.min(Swift.max(bound, lowerBound), upperBound)
    }
}
