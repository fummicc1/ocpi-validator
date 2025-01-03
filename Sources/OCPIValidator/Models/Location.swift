import Foundation

public struct Location: Codable {
  public let id: String
  public let type: LocationType
  public let name: String?
  public let address: String
  public let city: String
  public let postalCode: String
  public let country: String
  public let coordinates: GeoLocation
  public let relatedLocations: [AdditionalGeoLocation]?
  public let evses: [EVSE]?
  public let directions: [DisplayText]?
  public let operatingCompany: BusinessDetails?
  public let suboperator: BusinessDetails?
  public let owner: BusinessDetails?
  public let facilities: [Facility]?
  public let timeZone: String
  public let openingTimes: OpeningTimes?
  public let chargingWhenClosed: Bool?
  public let images: [Image]?
  public let energyMix: EnergyMix?
  public let lastUpdated: Date

  private enum CodingKeys: String, CodingKey {
    case id
    case type
    case name
    case address
    case city
    case postalCode = "postal_code"
    case country
    case coordinates
    case relatedLocations = "related_locations"
    case evses
    case directions
    case operatingCompany = "operator"
    case suboperator
    case owner
    case facilities
    case timeZone = "time_zone"
    case openingTimes = "opening_times"
    case chargingWhenClosed = "charging_when_closed"
    case images
    case energyMix = "energy_mix"
    case lastUpdated = "last_updated"
  }
}

public struct GeoLocation: Codable {
  public let latitude: String
  public let longitude: String
}

public struct AdditionalGeoLocation: Codable {
  public let latitude: String
  public let longitude: String
  public let name: DisplayText?
}

public enum LocationType: String, Codable {
  case onStreet = "ON_STREET"
  case parkingGarage = "PARKING_GARAGE"
  case undergroundGarage = "UNDERGROUND_GARAGE"
  case parkingLot = "PARKING_LOT"
  case other = "OTHER"
  case unknown = "UNKNOWN"
}

public enum Facility: String, Codable {
  case hotel
  case restaurant
  case cafe
  case mall
  case supermarket
  case sport
  case recreationArea = "recreation_area"
  case other
}

public struct OpeningTimes: Codable {
  public let regularHours: [RegularHours]?
  public let exceptionalOpenings: [ExceptionalPeriod]?
  public let exceptionalClosings: [ExceptionalPeriod]?

  private enum CodingKeys: String, CodingKey {
    case regularHours = "regular_hours"
    case exceptionalOpenings = "exceptional_openings"
    case exceptionalClosings = "exceptional_closings"
  }
}

public struct RegularHours: Codable {
  public let weekday: Int
  public let periodBegin: String
  public let periodEnd: String

  private enum CodingKeys: String, CodingKey {
    case weekday
    case periodBegin = "period_begin"
    case periodEnd = "period_end"
  }
}

public struct ExceptionalPeriod: Codable {
  public let periodBegin: Date
  public let periodEnd: Date

  private enum CodingKeys: String, CodingKey {
    case periodBegin = "period_begin"
    case periodEnd = "period_end"
  }
}

public struct EnergyMix: Codable {
  public let isGreenEnergy: Bool
  public let energySources: [EnergySource]?
  public let environImpact: [EnvironmentalImpact]?
  public let supplierName: String?
  public let energyProductName: String?

  private enum CodingKeys: String, CodingKey {
    case isGreenEnergy = "is_green_energy"
    case energySources = "energy_sources"
    case environImpact = "environ_impact"
    case supplierName = "supplier_name"
    case energyProductName = "energy_product_name"
  }
}

public struct EnergySource: Codable {
  public let source: String
  public let percentage: Float
}

public struct EnvironmentalImpact: Codable {
  public let category: String
  public let amount: Float
}
