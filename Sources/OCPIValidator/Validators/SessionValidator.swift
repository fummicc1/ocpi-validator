import Foundation

public struct SessionValidator {
    public init() {}
    
    public func validate(_ jsonData: Data) throws -> ValidationResult {
        var errors: [ValidationError] = []
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let session = try decoder.decode(Session.self, from: jsonData)
            
            // Required fields validation
            if session.id.isEmpty {
                errors.append(.missingRequiredField("id"))
            }
            
            if session.authId.isEmpty {
                errors.append(.missingRequiredField("auth_id"))
            }
            
            if session.currency.isEmpty {
                errors.append(.missingRequiredField("currency"))
            } else if !isValidCurrencyCode(session.currency) {
                errors.append(.invalidValue(field: "currency", reason: "Invalid ISO 4217 currency code"))
            }
            
            // Validate kwh
            if session.kwh < 0 {
                errors.append(.invalidValue(field: "kwh", reason: "Must be greater than or equal to 0"))
            }
            
            // Date validation
            if let endDateTime = session.endDateTime {
                if session.startDateTime >= endDateTime {
                    errors.append(.invalidValue(
                        field: "end_date_time",
                        reason: "Must be later than start_date_time"
                    ))
                }
                
                // If session is completed, end_date_time must be present
                if session.status == .completed && session.endDateTime == nil {
                    errors.append(.missingRequiredField("end_date_time for COMPLETED session"))
                }
            }
            
            // Status-specific validations
            validateStatusConsistency(session, errors: &errors)
            
            // Location validation
            validateLocation(session.location, errors: &errors)
            
            // EVSE and Connector validation
            if let evse = session.evse {
                validateEVSE(evse, errors: &errors)
            }
            
            if let connector = session.connector {
                validateConnector(connector, errors: &errors)
            }
            
            // Charging periods validation
            if let chargingPeriods = session.chargingPeriods {
                validateChargingPeriods(chargingPeriods, errors: &errors)
            }
            
            // Cost validation
            if let totalCost = session.totalCost, totalCost < 0 {
                errors.append(.invalidValue(field: "total_cost", reason: "Must be greater than or equal to 0"))
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
    
    private func validateStatusConsistency(_ session: Session, errors: inout [ValidationError]) {
        switch session.status {
        case .completed:
            if session.endDateTime == nil {
                errors.append(.missingRequiredField("end_date_time for COMPLETED session"))
            }
            if session.totalCost == nil {
                errors.append(.missingRequiredField("total_cost for COMPLETED session"))
            }
        case .active:
            if session.endDateTime != nil {
                errors.append(.invalidValue(
                    field: "end_date_time",
                    reason: "Should not be present for ACTIVE session"
                ))
            }
        case .invalid:
            // Additional validations for invalid sessions could be added here
            break
        case .pending:
            if session.endDateTime != nil {
                errors.append(.invalidValue(
                    field: "end_date_time",
                    reason: "Should not be present for PENDING session"
                ))
            }
        case .reserved:
            if session.kwh != 0 {
                errors.append(.invalidValue(
                    field: "kwh",
                    reason: "Should be 0 for RESERVED session"
                ))
            }
        }
    }
    
    private func validateChargingPeriods(_ periods: [ChargingPeriod], errors: inout [ValidationError]) {
        var previousPeriodStart: Date?
        
        for (periodIndex, period) in periods.enumerated() {
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
            errors.append(.invalidValue(
                field: "\(fieldPrefix).type",
                reason: "FLAT dimension type is not allowed in Sessions"
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