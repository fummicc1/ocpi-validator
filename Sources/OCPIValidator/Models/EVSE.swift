import Foundation

public struct EVSE: Codable {
  public let uid: String
  public let evseId: String?
  public let status: EVSEStatus
  public let statusSchedule: [StatusSchedule]?
  public let capabilities: [Capability]?
  public let connectors: [Connector]
  public let floorLevel: String?
  public let coordinates: GeoLocation?
  public let physicalReference: String?
  public let directions: [DisplayText]?
  public let parkingRestrictions: [ParkingRestriction]?
  public let images: [Image]?
  public let lastUpdated: Date

  private enum CodingKeys: String, CodingKey {
    case uid
    case evseId = "evse_id"
    case status
    case statusSchedule = "status_schedule"
    case capabilities
    case connectors
    case floorLevel = "floor_level"
    case coordinates
    case physicalReference = "physical_reference"
    case directions
    case parkingRestrictions = "parking_restrictions"
    case images
    case lastUpdated = "last_updated"
  }
}

public enum EVSEStatus: String, Codable {
  case available = "AVAILABLE"
  case blocked = "BLOCKED"
  case charging = "CHARGING"
  case inoperative = "INOPERATIVE"
  case outOfOrder = "OUT_OF_ORDER"
  case planned = "PLANNED"
  case removed = "REMOVED"
  case reserved = "RESERVED"
  case unknown = "UNKNOWN"
}

public struct StatusSchedule: Codable {
  public let periodBegin: Date
  public let periodEnd: Date?
  public let status: EVSEStatus

  private enum CodingKeys: String, CodingKey {
    case periodBegin = "period_begin"
    case periodEnd = "period_end"
    case status
  }
}

public enum Capability: String, Codable {
  case charging = "CHARGING"
  case unlockConnector = "UNLOCK_CONNECTOR"
  case reservable = "RESERVABLE"
  case rfidReader = "RFID_READER"
  case creditCard = "CREDIT_CARD"
  case remote = "REMOTE"
}

public struct Connector: Codable {
  public let id: String
  public let standard: ConnectorType
  public let format: ConnectorFormat
  public let powerType: PowerType
  public let maxVoltage: Int
  public let maxAmperage: Int
  public let maxElectricPower: Int?
  public let tariffIds: [String]?
  public let termsAndConditions: URL?
  public let lastUpdated: Date

  private enum CodingKeys: String, CodingKey {
    case id
    case standard
    case format
    case powerType = "power_type"
    case maxVoltage = "max_voltage"
    case maxAmperage = "max_amperage"
    case maxElectricPower = "max_electric_power"
    case tariffIds = "tariff_ids"
    case termsAndConditions = "terms_and_conditions"
    case lastUpdated = "last_updated"
  }
}

public enum ConnectorType: String, Codable {
  case chademo = "CHADEMO"
  case domesticA = "DOMESTIC_A"
  case domesticB = "DOMESTIC_B"
  case domesticC = "DOMESTIC_C"
  case domesticD = "DOMESTIC_D"
  case domesticE = "DOMESTIC_E"
  case domesticF = "DOMESTIC_F"
  case iec603092Single = "IEC_60309_2_SINGLE"
  case iec603092Three = "IEC_60309_2_THREE"
  case teslaR = "TESLA_R"
  case teslaS = "TESLA_S"
  case type1 = "TYPE_1"
  case type2 = "TYPE_2"
  case type3 = "TYPE_3"
}

public enum ConnectorFormat: String, Codable {
  case socket = "SOCKET"
  case cable = "CABLE"
}

public enum PowerType: String, Codable {
  case ac1Phase = "AC_1_PHASE"
  case ac3Phase = "AC_3_PHASE"
  case dc = "DC"
}

public enum ParkingRestriction: String, Codable {
  case ev = "EV"
  case pluggedIn = "PLUGGED_IN"
  case disabled = "DISABLED"
  case customers = "CUSTOMERS"
  case motorcycles = "MOTORCYCLES"
}
