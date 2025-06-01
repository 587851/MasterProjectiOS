import Foundation
import HealthKit

class HealthDataFormatter: IHealthDataFormatter {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy 'at' HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    func formatToString(samples: [HKSample]) -> String {
        var output = ""
        var count = 0

        for sample in samples {
            if let quantitySample = sample as? HKQuantitySample {
                let id = quantitySample.quantityType.identifier
                let type = userFriendlyNames[id] ?? id
                let unit = unitMap[id] ?? HKUnit.count()

                let value = quantitySample.quantity.doubleValue(for: unit)
                let formattedValue = String(format: "%.2f", value)

                output += "\(type): \(formattedValue) \(unit.description)\n"
                output += "Time: \(dateFormatter.string(from: quantitySample.startDate))\n\n"
                count += 1

            } else if let categorySample = sample as? HKCategorySample {
                let id = categorySample.categoryType.identifier
                let type = userFriendlyNames[id] ?? id

                output += "\(type): \(getStageDescription(categorySample.value))\n"
                output += "Start: \(dateFormatter.string(from: categorySample.startDate))\n"
                output += "End: \(dateFormatter.string(from: categorySample.endDate))\n\n"
                count += 1
            }
        }

        return "Total data points: \(count)\n\n" + output
    }



    func formatToPoints(samples: [HKSample]) -> [HealthDataPoint] {
        var points: [HealthDataPoint] = []

        for sample in samples {
            if let quantitySample = sample as? HKQuantitySample {
                let id = quantitySample.quantityType.identifier
                let unit = unitMap[id] ?? HKUnit.count() // fallback to avoid crash

                let value = quantitySample.quantity.doubleValue(for: unit)
                points.append(HealthDataPoint(timestamp: quantitySample.startDate, value: value))
            } else if let categorySample = sample as? HKCategorySample {
                points.append(HealthDataPoint(timestamp: categorySample.startDate, value: Double(categorySample.value)))
            }
        }

        return points.sorted(by: { $0.timestamp < $1.timestamp })
    }



    let userFriendlyNames: [String: String] = [
        HKQuantityTypeIdentifier.basalBodyTemperature.rawValue: "Basal Body Temperature",
        HKQuantityTypeIdentifier.basalEnergyBurned.rawValue: "Basal Metabolic Rate",
        HKQuantityTypeIdentifier.bodyFatPercentage.rawValue: "Body Fat",
        HKQuantityTypeIdentifier.bodyTemperature.rawValue: "Body Temperature",
        HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue: "Distance",
        HKQuantityTypeIdentifier.heartRate.rawValue: "Heart Rate",
        HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue: "Heart Rate Variability",
        HKQuantityTypeIdentifier.oxygenSaturation.rawValue: "Oxygen Saturation",
        HKQuantityTypeIdentifier.respiratoryRate.rawValue: "Respiratory Rate",
        HKQuantityTypeIdentifier.restingHeartRate.rawValue: "Resting Heart Rate",
        HKQuantityTypeIdentifier.stepCount.rawValue: "Steps",
        HKQuantityTypeIdentifier.vo2Max.rawValue: "VO₂ Max",
        HKCategoryTypeIdentifier.sleepAnalysis.rawValue: "Sleep"
    ]
    
    let unitMap: [String: HKUnit] = [
        HKQuantityTypeIdentifier.heartRate.rawValue: HKUnit(from: "count/min"),
        HKQuantityTypeIdentifier.stepCount.rawValue: HKUnit.count(),
        HKQuantityTypeIdentifier.vo2Max.rawValue: HKUnit(from: "mL/kg·min"),
        HKQuantityTypeIdentifier.basalBodyTemperature.rawValue: HKUnit.degreeCelsius(),
        HKQuantityTypeIdentifier.bodyTemperature.rawValue: HKUnit.degreeCelsius(),
        HKQuantityTypeIdentifier.bodyFatPercentage.rawValue: HKUnit.percent(),
        HKQuantityTypeIdentifier.basalEnergyBurned.rawValue: HKUnit.kilocalorie(),
        HKQuantityTypeIdentifier.oxygenSaturation.rawValue: HKUnit.percent(),
        HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue: HKUnit.meter(),
        HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue: HKUnit(from: "ms"),
        HKQuantityTypeIdentifier.respiratoryRate.rawValue: HKUnit(from: "count/min"),
        HKQuantityTypeIdentifier.restingHeartRate.rawValue: HKUnit(from: "count/min")
    ]


    
    func getStageDescription(_ value: Int) -> String {
        switch value {
        case 1: return "Awake, maybe in bed"
        case 7: return "Awake, in bed"
        case 5: return "Deep sleep"
        case 4: return "Light sleep"
        case 3: return "Awake, out of bed"
        case 6: return "REM sleep"
        case 2: return "Asleep, unknown stage"
        case 0: return "Unknown stage"
        default: return "Unrecognized stage"
        }
    }
    
}

