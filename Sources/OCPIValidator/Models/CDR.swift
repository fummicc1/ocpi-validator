import Foundation

public struct CDR: Codable {
    public let id: String
    public let startDateTime: Date
    public let endDateTime: Date
    public let authId: String
    public let authMethod: AuthMethod
    public let location: Location
    public let evse: EVSE?
    public let connector: Connector?
    public let meterId: String?
    public let currency: String
    public let tariffs: [Tariff]?
    public let chargingPeriods: [ChargingPeriod]
    public let totalCost: Double
    public let totalEnergy: Double
    public let totalTime: Double
    public let totalParkingTime: Double?
    public let remark: String?
    public let lastUpdated: Date
    
    private enum CodingKeys: String, CodingKey {
        case id
        case startDateTime = "start_date_time"
        case endDateTime = "end_date_time"
        case authId = "auth_id"
        case authMethod = "auth_method"
        case location
        case evse
        case connector
        case meterId = "meter_id"
        case currency
        case tariffs
        case chargingPeriods = "charging_periods"
        case totalCost = "total_cost"
        case totalEnergy = "total_energy"
        case totalTime = "total_time"
        case totalParkingTime = "total_parking_time"
        case remark
        case lastUpdated = "last_updated"
    }
}

public enum AuthMethod: String, Codable {
    case auth_request = "AUTH_REQUEST"
    case command = "COMMAND"
    case whitelist = "WHITELIST"
}
