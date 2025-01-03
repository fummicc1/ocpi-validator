import Foundation

public struct ChargingPeriod: Codable {
    public let startDateTime: Date
    public let dimensions: [Dimension]
    public let tariffId: String?
    
    private enum CodingKeys: String, CodingKey {
        case startDateTime = "start_date_time"
        case dimensions
        case tariffId = "tariff_id"
    }
}

public struct Dimension: Codable {
    public let type: DimensionType
    public let volume: Double
    
    private enum CodingKeys: String, CodingKey {
        case type
        case volume
    }
}

public enum DimensionType: String, Codable {
    // Basic types used in both CDR and Session
    case current = "CURRENT"
    case energy = "ENERGY"
    case energyExport = "ENERGY_EXPORT"
    case energyImport = "ENERGY_IMPORT"
    case maxCurrent = "MAX_CURRENT"
    case minCurrent = "MIN_CURRENT"
    case maxPower = "MAX_POWER"
    case minPower = "MIN_POWER"
    case parkingTime = "PARKING_TIME"
    case power = "POWER"
    case powerFactor = "POWER_FACTOR"
    case soc = "SOC"
    case time = "TIME"
    case voltage = "VOLTAGE"
    
    // Additional types specific to CDR
    case flat = "FLAT"
} 