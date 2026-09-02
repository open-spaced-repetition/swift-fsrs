import Foundation
import FSRS
import Testing

@Suite struct FSRSPublicAPITests {
    @Test func tsCompatibleParametersAndRescheduleTypesArePublic() throws {
        let parameters = FSRSParameters.tsFSRS6Compatible()
        let scheduler = FSRS(parameters: parameters)
        let firstCard = FSRSDefaults().createEmptyCard(now: Date(timeIntervalSince1970: 0))
        let options = RescheduleOptions(
            skipManual: true,
            updateMemoryState: false,
            now: Date(timeIntervalSince1970: 86_400),
            firstCard: firstCard
        )
        let result = try scheduler.reschedule(
            currentCard: firstCard,
            reviews: [],
            options: options
        )
        #expect(result.collections.isEmpty)
        #expect(result.rescheduleItem == nil)
    }
}
