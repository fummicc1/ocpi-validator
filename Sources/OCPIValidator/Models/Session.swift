import Foundation

public struct Session: Codable {
    public let id: String
    public let startDateTime: Date
    public let endDateTime: Date?
    public let kwh: Double
    public let authId: String
    public let authMethod: AuthMethod
    public let location: Location
    public let evse: EVSE?
    public let connector: Connector?
    public let meterId: String?
    public let currency: String
    public let status: SessionStatus
    public let lastUpdated: Date
    public let chargingPeriods: [ChargingPeriod]?
    public let totalCost: Double?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case startDateTime = "start_date_time"
        case endDateTime = "end_date_time"
        case kwh
        case authId = "auth_id"
        case authMethod = "auth_method"
        case location
        case evse
        case connector
        case meterId = "meter_id"
        case currency
        case status
        case lastUpdated = "last_updated"
        case chargingPeriods = "charging_periods"
        case totalCost = "total_cost"
    }
}

public enum SessionStatus: String, Codable {
    case active = "ACTIVE"
    case completed = "COMPLETED"
    case invalid = "INVALID"
    case pending = "PENDING"
    case reserved = "RESERVED"
}
