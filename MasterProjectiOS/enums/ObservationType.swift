import Foundation

enum ObservationType: String, CaseIterable, Codable {
    case basalBodyTemperature = "BASAL_BODY_TEMPERATURE"
    case basalMetabolicRate = "BASAL_METABOLIC_RATE"
    case bodyFat = "BODY_FAT"
    case bodyTemperature = "BODY_TEMPERATURE"
    case distance = "DISTANCE"
    case heartRate = "HEART_RATE"
    case heartRateVariability = "HEART_RATE_VARIABILITY"
    case oxygenSaturation = "OXYGEN_SATURATION"
    case respiratoryRate = "RESPIRATORY_RATE"
    case restingHeartRate = "RESTING_HEART_RATE"
    case sleep = "SLEEP"
    case steps = "STEPS"
    case vo2Max = "VO2_MAX"
}

