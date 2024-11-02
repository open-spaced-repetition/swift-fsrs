import Foundation

extension Date {
    func addingMinutes(_ minutes: Int64) -> Date {
        addingTimeInterval(Double(minutes * 60))
    }
    
    func addingHours(_ hours: Int64) -> Date {
        addingMinutes(hours * 60)
    }
    
    func addingDays(_ days: Int64) -> Date {
        addingHours(days * 24)
    }
}
