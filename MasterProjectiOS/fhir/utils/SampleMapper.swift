import Foundation
import HealthKit

class SampleMapper {

    static let loincSystem = "http://loinc.org"
    static let categorySystem = "http://terminology.hl7.org/CodeSystem/observation-category"
    static let unitSystem = "http://unitsofmeasure.org"

    private let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    
    func mapToObservation(patientId: String, type: ObservationType, sample: HKSample) -> [FHIRObservation] {
        switch type {
        case .basalBodyTemperature:
            return convertQuantitySample(sample, patientId: patientId, code: "8310-5", display: "Basal body temperature", unit: "°C", category: vitalCategory)

        case .basalMetabolicRate:
            return convertQuantitySample(sample, patientId: patientId, code: "69429-9", display: "Basal metabolic rate", unit: "kcal/day", category: vitalCategory)

        case .bodyFat:
            return convertQuantitySample(sample, patientId: patientId, code: "41982-0", display: "Body fat", unit: "%", category: vitalCategory)

        case .bodyTemperature:
            return convertQuantitySample(sample, patientId: patientId, code: "8310-5", display: "Body temperature", unit: "°C", category: vitalCategory)

        case .distance:
            return convertQuantitySample(sample, patientId: patientId, code: "55430-3", display: "Distance traveled", unit: "m", category: activityCategory)

        case .heartRate:
            return convertQuantitySample(sample, patientId: patientId, code: "8867-4", display: "Heart rate", unit: "beats/minute", category: vitalCategory)

        case .heartRateVariability:
            return convertQuantitySample(sample, patientId: patientId, code: "80404-7", display: "Heart rate variability", unit: "ms", category: vitalCategory)

        case .oxygenSaturation:
            return convertQuantitySample(sample, patientId: patientId, code: "59408-5", display: "Oxygen saturation", unit: "%", category: vitalCategory)

        case .respiratoryRate:
            return convertQuantitySample(sample, patientId: patientId, code: "9279-1", display: "Respiratory rate", unit: "breaths/min", category: vitalCategory)

        case .restingHeartRate:
            return convertQuantitySample(sample, patientId: patientId, code: "40443-4", display: "Resting heart rate", unit: "beats/minute", category: vitalCategory)

        case .sleep:
            return convertCategorySample(sample, patientId: patientId, code: "93832-4", display: "Sleep session", unit: "sleep stage", category: activityCategory)

        case .steps:
            return convertQuantitySample(sample, patientId: patientId, code: "55423-8", display: "Step count", unit: "steps", category: activityCategory)

        case .vo2Max:
            return convertQuantitySample(sample, patientId: patientId, code: "60842-2", display: "VO2 max", unit: "mL/kg/min", category: vitalCategory)
        }
    }

    private func convertQuantitySample(
        _ sample: HKSample,
        patientId: String,
        code: String,
        display: String,
        unit: String,
        category: CodeableConcept
    ) -> [FHIRObservation] {
        guard let quantitySample = sample as? HKQuantitySample else {
            return []
        }

        let quantity = quantitySample.quantity
        guard let hkUnit = hkUnitMap[unit] else {
            print("Invalid or unmapped HKUnit string: \(unit)")
            return []
        }

        let value = quantity.doubleValue(for: hkUnit)
        let timestamp = formatter.string(from: quantitySample.startDate)

        let observation = FHIRObservation(
            status: "final",
            category: [category],
            code: CodeableConcept(
                coding: [Coding(system: Self.loincSystem, code: code, display: display)],
                text: display
            ),
            valueQuantity: Quantity(
                value: value,
                unit: unit,
                system: Self.unitSystem,
                code: unit
            ),
            subject: Reference(reference: "Patient/\(patientId)"),
            effectiveDateTime: timestamp,
            effectivePeriod: nil
        )
        return [observation]
    }
    
    private func convertCategorySample(
        _ sample: HKSample,
        patientId: String,
        code: String,
        display: String,
        unit: String,
        category: CodeableConcept
    ) -> [FHIRObservation] {
        guard let categorySample = sample as? HKCategorySample else {
            return []
        }

        let value = Double(categorySample.value)
        let startTimestamp = formatter.string(from: categorySample.startDate)
        let endTimestamp = formatter.string(from: categorySample.endDate)

        let observation = FHIRObservation(
            status: "final",
            category: [category],
            code: CodeableConcept(
                coding: [Coding(system: Self.loincSystem, code: code, display: display)],
                text: display
            ),
            valueQuantity: Quantity(
                value: value,
                unit: unit,
                system: Self.unitSystem,
                code: unit
            ),
            subject: Reference(reference: "Patient/\(patientId)"),
            effectiveDateTime: nil,
            effectivePeriod: Period(start: startTimestamp, end: endTimestamp)
        )

        return [observation]
    }

    
    private let vitalCategory = CodeableConcept(
        coding: [Coding(system: SampleMapper.categorySystem, code: "vital-signs", display: "Vital Signs")],
        text: "Vital Signs"
    )

    private let activityCategory = CodeableConcept(
        coding: [Coding(system: SampleMapper.categorySystem, code: "activity", display: "Activity")],
        text: "Activity"
    )
    
    private let hkUnitMap: [String: HKUnit] = [
        "beats/minute": HKUnit(from: "count/min"),
        "breaths/min": HKUnit(from: "count/min"),
        "steps": HKUnit.count(),
        "m": HKUnit.meter(),
        "kcal/day": HKUnit.kilocalorie().unitDivided(by: .day()),
        "°C": HKUnit.degreeCelsius(),
        "%": HKUnit.percent(),
        "ms": HKUnit(from: "ms"),
        "mL/kg/min": HKUnit(from: "mL/kg·min")
    ]


}
