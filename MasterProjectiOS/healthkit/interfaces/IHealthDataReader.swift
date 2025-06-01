import Foundation
import HealthKit

import Foundation
import HealthKit

protocol IHealthDataReader {

    func getIntervalSamples(type: String, from start: Date, to end: Date) async -> [HKSample]

    func convertToString(samples: [HKSample]) -> String

    func convertToDataPoints(samples: [HKSample]) -> [HealthDataPoint]
}



