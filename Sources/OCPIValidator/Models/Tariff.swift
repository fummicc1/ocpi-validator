import Foundation

public struct Tariff: Codable {
    public let id: String
    public let currency: String
    public let type: TariffType?
    public let countryCode: String
    public let partyId: String
    public let elements: [TariffElement]
    public let lastUpdated: Date
    public let startDateTime: Date?
    public let endDateTime: Date?
    public let energyMix: EnergyMix?
    public let minPrice: Price?
    public let maxPrice: Price?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case currency
        case type
        case countryCode = "country_code"
        case partyId = "party_id"
        case elements
        case lastUpdated = "last_updated"
        case startDateTime = "start_date_time"
        case endDateTime = "end_date_time"
        case energyMix = "energy_mix"
        case minPrice = "min_price"
        case maxPrice = "max_price"
    }
}

public enum TariffType: String, Codable {
    case ad_hoc_payment
    case profile_cheap
    case profile_fast
    case profile_green
    case regular
    case other
}

public struct TariffElement: Codable {
    public let priceComponents: [PriceComponent]
    public let restrictions: TariffRestrictions?
    
    private enum CodingKeys: String, CodingKey {
        case priceComponents = "price_components"
        case restrictions
    }
}

public struct PriceComponent: Codable {
    public let type: TariffDimensionType
    public let price: Double
    public let stepSize: Int
    public let vat: Double?
    
    private enum CodingKeys: String, CodingKey {
        case type
        case price
        case stepSize = "step_size"
        case vat
    }
}

public enum TariffDimensionType: String, Codable {
    case energy = "ENERGY"
    case flat = "FLAT"
    case parking = "PARKING_TIME"
    case time = "TIME"
}

public struct TariffRestrictions: Codable {
    public let startTime: String?
    public let endTime: String?
    public let startDate: Date?
    public let endDate: Date?
    public let minKwh: Double?
    public let maxKwh: Double?
    public let minPower: Double?
    public let maxPower: Double?
    public let minDuration: Int?
    public let maxDuration: Int?
    public let dayOfWeek: [DayOfWeek]?
    public let reservation: ReservationRestrictionType?
    
    private enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case endTime = "end_time"
        case startDate = "start_date"
        case endDate = "end_date"
        case minKwh = "min_kwh"
        case maxKwh = "max_kwh"
        case minPower = "min_power"
        case maxPower = "max_power"
        case minDuration = "min_duration"
        case maxDuration = "max_duration"
        case dayOfWeek = "day_of_week"
        case reservation
    }
}

public enum DayOfWeek: Int, Codable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7
}

public enum ReservationRestrictionType: String, Codable {
    case reservation
    case reservation_expires
}

public struct Price: Codable {
    public let excl_vat: Double
    public let incl_vat: Double?
} 