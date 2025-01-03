import Foundation

public struct CDRValidator {
    public init() {}
    
    public func validate(_ jsonData: Data) throws -> ValidationResult {
        var errors: [ValidationError] = []
        
        // First, validate required fields using dictionary
        if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            let requiredFields = [
                "id", "start_date_time", "end_date_time", "auth_id", "auth_method",
                "location", "currency", "charging_periods", "total_cost", "total_energy",
                "total_time", "last_updated"
            ]
            for field in requiredFields {
                if json[field] == nil {
                    errors.append(.missingRequiredField(field))
                }
            }
            
            // Validate location required fields
            if let location = json["location"] as? [String: Any] {
                let requiredLocationFields = ["id", "address", "city", "country", "coordinates"]
                for field in requiredLocationFields {
                    if location[field] == nil {
                        errors.append(.missingRequiredField("location.\(field)"))
                    }
                }
                
                // Validate coordinates
                if let coordinates = location["coordinates"] as? [String: Any] {
                    let requiredCoordinateFields = ["latitude", "longitude"]
                    for field in requiredCoordinateFields {
                        if coordinates[field] == nil {
                            errors.append(.missingRequiredField("location.coordinates.\(field)"))
                        }
                    }
                }
            }
            
            // Validate charging periods
            if let periods = json["charging_periods"] as? [[String: Any]] {
                for (index, period) in periods.enumerated() {
                    let requiredPeriodFields = ["start_date_time", "dimensions"]
                    for field in requiredPeriodFields {
                        if period[field] == nil {
                            errors.append(.missingRequiredField("charging_periods[\(index)].\(field)"))
                        }
                    }
                    
                    // Validate dimensions
                    if let dimensions = period["dimensions"] as? [[String: Any]] {
                        for (dimIndex, dimension) in dimensions.enumerated() {
                            let requiredDimensionFields = ["type", "volume"]
                            for field in requiredDimensionFields {
                                if dimension[field] == nil {
                                    errors.append(.missingRequiredField("charging_periods[\(index)].dimensions[\(dimIndex)].\(field)"))
                                }
                            }
                        }
                    }
                }
            }
        } else {
            errors.append(.invalidJSON)
            return ValidationResult(isValid: false, errors: errors)
        }
        
        // If there are missing required fields, return early
        if !errors.isEmpty {
            return ValidationResult(isValid: false, errors: errors)
        }
        
        // Then proceed with full decoding and validation
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let cdr = try decoder.decode(CDR.self, from: jsonData)
            
            validateCDR(cdr, errors: &errors)
            
        } catch {
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .typeMismatch(_, let context):
                    errors.append(.invalidFieldType(
                        field: context.codingPath.map { $0.stringValue }.joined(separator: "."),
                        expectedType: context.debugDescription
                    ))
                default:
                    errors.append(.invalidJSON)
                }
            } else {
                errors.append(.invalidJSON)
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    private func validateCDR(_ cdr: CDR, errors: inout [ValidationError]) {
        // Validate totals
        validateTotals(cdr, errors: &errors)
        
        // Validate charging periods
        for (periodIndex, period) in cdr.chargingPeriods.enumerated() {
            validateChargingPeriod(period, periodIndex: periodIndex, errors: &errors)
        }
        
        // Validate location
        validateLocation(cdr.location, errors: &errors)
        
        // Validate EVSE if present
        if let evse = cdr.evse {
            validateEVSE(evse, errors: &errors)
        }
        
        // Validate connector if present
        if let connector = cdr.connector {
            validateConnector(connector, errors: &errors)
        }
    }
    
    private func validateTotals(_ cdr: CDR, errors: inout [ValidationError]) {
        if cdr.totalCost < 0 {
            errors.append(.invalidValue(field: "total_cost", reason: "Must be greater than or equal to 0"))
        }
        
        if cdr.totalEnergy < 0 {
            errors.append(.invalidValue(field: "total_energy", reason: "Must be greater than or equal to 0"))
        }
        
        if cdr.totalTime < 0 {
            errors.append(.invalidValue(field: "total_time", reason: "Must be greater than or equal to 0"))
        }
        
        if let parkingTime = cdr.totalParkingTime, parkingTime < 0 {
            errors.append(.invalidValue(field: "total_parking_time", reason: "Must be greater than or equal to 0"))
        }
        
        // Validate if totals match the sum of charging periods
        validateTotalConsistency(cdr, errors: &errors)
    }
    
    private func validateChargingPeriod(_ period: ChargingPeriod, periodIndex: Int, errors: inout [ValidationError]) {
        for (dimensionIndex, dimension) in period.dimensions.enumerated() {
            validateDimension(dimension, periodIndex: periodIndex, dimensionIndex: dimensionIndex, errors: &errors)
        }
    }
    
    private func validateDimension(_ dimension: Dimension, periodIndex: Int, dimensionIndex: Int, errors: inout [ValidationError]) {
        let fieldPrefix = "charging_periods[\(periodIndex)].dimensions[\(dimensionIndex)]"
        
        switch dimension.type {
        case .current, .energy, .energyExport, .energyImport, .power, .voltage:
            if dimension.volume < 0 {
                errors.append(.invalidValue(
                    field: "\(fieldPrefix).volume",
                    reason: "Must be greater than or equal to 0"
                ))
            }
        case .maxCurrent, .minCurrent, .maxPower, .minPower:
            if dimension.volume <= 0 {
                errors.append(.invalidValue(
                    field: "\(fieldPrefix).volume",
                    reason: "Must be greater than 0"
                ))
            }
        case .powerFactor:
            if dimension.volume < -1 || dimension.volume > 1 {
                errors.append(.invalidValue(
                    field: "\(fieldPrefix).volume",
                    reason: "Must be between -1 and 1"
                ))
            }
        case .soc:
            if dimension.volume < 0 || dimension.volume > 100 {
                errors.append(.invalidValue(
                    field: "\(fieldPrefix).volume",
                    reason: "Must be between 0 and 100"
                ))
            }
        case .time, .parkingTime:
            if dimension.volume < 0 {
                errors.append(.invalidValue(
                    field: "\(fieldPrefix).volume",
                    reason: "Must be greater than or equal to 0"
                ))
            }
        case .flat:
            if dimension.volume != 1 {
                errors.append(.invalidValue(
                    field: "\(fieldPrefix).volume",
                    reason: "Flat dimension volume must be 1"
                ))
            }
        }
    }
    
    private func validateLocation(_ location: Location, errors: inout [ValidationError]) {
        if let latitude = Double(location.coordinates.latitude), latitude < -90 || latitude > 90 {
            errors.append(.invalidValue(
                field: "location.coordinates.latitude",
                reason: "Must be between -90 and 90"
            ))
        }
        
        if let longitude  = Double(location.coordinates.longitude), longitude < -180 || longitude > 180 {
            errors.append(.invalidValue(
                field: "location.coordinates.longitude",
                reason: "Must be between -180 and 180"
            ))
        }
    }
    
    private func validateEVSE(_ evse: EVSE, errors: inout [ValidationError]) {
        if evse.uid.isEmpty {
            errors.append(.missingRequiredField("evse.uid"))
        }
    }
    
    private func validateConnector(_ connector: Connector, errors: inout [ValidationError]) {
        if connector.id.isEmpty {
            errors.append(.missingRequiredField("connector.id"))
        }
        
        if connector.maxVoltage <= 0 {
            errors.append(.invalidValue(
                field: "connector.max_voltage",
                reason: "Must be greater than 0"
            ))
        }
        
        if connector.maxAmperage <= 0 {
            errors.append(.invalidValue(
                field: "connector.max_amperage",
                reason: "Must be greater than 0"
            ))
        }
    }
    
    private func validateTotalConsistency(_ cdr: CDR, errors: inout [ValidationError]) {
        var calculatedEnergy: Double = 0
        var calculatedTime: Double = 0
        var calculatedParkingTime: Double = 0
        
        for period in cdr.chargingPeriods {
            for dimension in period.dimensions {
                switch dimension.type {
                case .energy:
                    calculatedEnergy += dimension.volume
                case .time:
                    calculatedTime += dimension.volume
                case .parkingTime:
                    calculatedParkingTime += dimension.volume
                default:
                    break
                }
            }
        }
        
        let tolerance = 0.01 // Small tolerance for floating point comparisons
        
        if abs(calculatedEnergy - cdr.totalEnergy) > tolerance {
            errors.append(.invalidValue(
                field: "total_energy",
                reason: "Total energy does not match the sum of energy dimensions"
            ))
        }
        
        if abs(calculatedTime - cdr.totalTime) > tolerance {
            errors.append(.invalidValue(
                field: "total_time",
                reason: "Total time does not match the sum of time dimensions"
            ))
        }
        
        if let totalParkingTime = cdr.totalParkingTime,
           abs(calculatedParkingTime - totalParkingTime) > tolerance {
            errors.append(.invalidValue(
                field: "total_parking_time",
                reason: "Total parking time does not match the sum of parking time dimensions"
            ))
        }
    }
} 