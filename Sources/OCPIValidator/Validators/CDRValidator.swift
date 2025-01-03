import Foundation

public struct CDRValidator {
    public init() {}
    
    public func validate(_ jsonData: Data) throws -> ValidationResult {
        var errors: [ValidationError] = []
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let cdr = try decoder.decode(CDR.self, from: jsonData)
            
            // Required fields validation
            if cdr.id.isEmpty {
                errors.append(.missingRequiredField("id"))
            }
            
            if cdr.authId.isEmpty {
                errors.append(.missingRequiredField("auth_id"))
            }
            
            if cdr.currency.isEmpty {
                errors.append(.missingRequiredField("currency"))
            } else if !isValidCurrencyCode(cdr.currency) {
                errors.append(.invalidValue(field: "currency", reason: "Invalid ISO 4217 currency code"))
            }
            
            // Date validation
            if cdr.startDateTime >= cdr.endDateTime {
                errors.append(.invalidValue(
                    field: "end_date_time",
                    reason: "Must be later than start_date_time"
                ))
            }
            
            // Charging periods validation
            if cdr.chargingPeriods.isEmpty {
                errors.append(.missingRequiredField("charging_periods"))
            }
            
            // Validate each charging period
            var previousPeriodStart: Date?
            for (periodIndex, period) in cdr.chargingPeriods.enumerated() {
                if period.dimensions.isEmpty {
                    errors.append(.missingRequiredField("charging_periods[\(periodIndex)].dimensions"))
                }
                
                // Check if charging periods are in chronological order
                if let previousStart = previousPeriodStart, period.startDateTime <= previousStart {
                    errors.append(.invalidValue(
                        field: "charging_periods[\(periodIndex)].start_date_time",
                        reason: "Charging periods must be in chronological order"
                    ))
                }
                previousPeriodStart = period.startDateTime
                
                // Validate dimensions
                for (dimensionIndex, dimension) in period.dimensions.enumerated() {
                    validateDimension(
                        dimension,
                        periodIndex: periodIndex,
                        dimensionIndex: dimensionIndex,
                        errors: &errors
                    )
                }
            }
            
            // Validate totals
            validateTotals(cdr, errors: &errors)
            
            // Location validation
            validateLocation(cdr.location, errors: &errors)
            
            // EVSE and Connector validation
            if let evse = cdr.evse {
                validateEVSE(evse, errors: &errors)
            }
            
            if let connector = cdr.connector {
                validateConnector(connector, errors: &errors)
            }
            
        } catch {
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, _):
                    errors.append(.missingRequiredField(key.stringValue))
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
    
    private func validateLocation(_ location: Location, errors: inout [ValidationError]) {
        if location.id.isEmpty {
            errors.append(.missingRequiredField("location.id"))
        }
        
        if location.address.isEmpty {
            errors.append(.missingRequiredField("location.address"))
        }
        
        if location.city.isEmpty {
            errors.append(.missingRequiredField("location.city"))
        }
        
        if location.country.isEmpty {
            errors.append(.missingRequiredField("location.country"))
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
    }
    
    private func isValidCurrencyCode(_ code: String) -> Bool {
        let currencyRegex = try! NSRegularExpression(pattern: "^[A-Z]{3}$")
        let range = NSRange(location: 0, length: code.utf16.count)
        return currencyRegex.firstMatch(in: code, range: range) != nil
    }
} 