import Foundation

public struct SessionValidator {
  public init() {}

  public func validate(_ jsonData: Data) throws -> ValidationResult {
    var errors: [ValidationError] = []

    // First, validate required fields using dictionary
    if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
      let requiredFields = [
        "id", "start_date_time", "kwh", "auth_id", "auth_method",
        "location", "currency", "status", "last_updated",
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

      // Validate charging periods if present
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
                  errors.append(
                    .missingRequiredField(
                      "charging_periods[\(index)].dimensions[\(dimIndex)].\(field)"))
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

      let session = try decoder.decode(Session.self, from: jsonData)

      validateSession(session, errors: &errors)

    } catch {
      if let decodingError = error as? DecodingError {
        switch decodingError {
        case .typeMismatch(_, let context):
          errors.append(
            .invalidFieldType(
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

  private func validateSession(_ session: Session, errors: inout [ValidationError]) {
    // Validate kwh
    if session.kwh < 0 {
      errors.append(
        .invalidValue(
          field: "kwh",
          reason: "Must be greater than or equal to 0"
        ))
    }

    // Validate dates
    if let endDateTime = session.endDateTime {
      if session.startDateTime >= endDateTime {
        errors.append(
          .invalidValue(
            field: "end_date_time",
            reason: "Must be later than start_date_time"
          ))
      }
    }

    // Validate total cost if present
    if let totalCost = session.totalCost, totalCost < 0 {
      errors.append(
        .invalidValue(
          field: "total_cost",
          reason: "Must be greater than or equal to 0"
        ))
    }

    // Validate location
    validateLocation(session.location, errors: &errors)

    // Validate EVSE if present
    if let evse = session.evse {
      validateEVSE(evse, errors: &errors)
    }

    // Validate connector if present
    if let connector = session.connector {
      validateConnector(connector, errors: &errors)
    }

    // Validate charging periods if present
    if let periods = session.chargingPeriods {
      for (periodIndex, period) in periods.enumerated() {
        validateChargingPeriod(period, periodIndex: periodIndex, errors: &errors)
      }
    }
  }

  private func validateLocation(_ location: Location, errors: inout [ValidationError]) {
    if let latitude = Double(location.coordinates.latitude), latitude < -90 || latitude > 90 {
      errors.append(
        .invalidValue(
          field: "location.coordinates.latitude",
          reason: "Must be between -90 and 90"
        ))
    }

    if let longitude = Double(location.coordinates.longitude), longitude < -180 || longitude > 180 {
      errors.append(
        .invalidValue(
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
      errors.append(
        .invalidValue(
          field: "connector.max_voltage",
          reason: "Must be greater than 0"
        ))
    }

    if connector.maxAmperage <= 0 {
      errors.append(
        .invalidValue(
          field: "connector.max_amperage",
          reason: "Must be greater than 0"
        ))
    }
  }

  private func validateChargingPeriod(
    _ period: ChargingPeriod, periodIndex: Int, errors: inout [ValidationError]
  ) {
    for (dimensionIndex, dimension) in period.dimensions.enumerated() {
      validateDimension(
        dimension, periodIndex: periodIndex, dimensionIndex: dimensionIndex, errors: &errors)
    }
  }

  private func validateDimension(
    _ dimension: Dimension, periodIndex: Int, dimensionIndex: Int, errors: inout [ValidationError]
  ) {
    let fieldPrefix = "charging_periods[\(periodIndex)].dimensions[\(dimensionIndex)]"

    switch dimension.type {
    case .current, .energy, .energyExport, .energyImport, .power, .voltage:
      if dimension.volume < 0 {
        errors.append(
          .invalidValue(
            field: "\(fieldPrefix).volume",
            reason: "Must be greater than or equal to 0"
          ))
      }
    case .maxCurrent, .minCurrent, .maxPower, .minPower:
      if dimension.volume <= 0 {
        errors.append(
          .invalidValue(
            field: "\(fieldPrefix).volume",
            reason: "Must be greater than 0"
          ))
      }
    case .powerFactor:
      if dimension.volume < -1 || dimension.volume > 1 {
        errors.append(
          .invalidValue(
            field: "\(fieldPrefix).volume",
            reason: "Must be between -1 and 1"
          ))
      }
    case .soc:
      if dimension.volume < 0 || dimension.volume > 100 {
        errors.append(
          .invalidValue(
            field: "\(fieldPrefix).volume",
            reason: "Must be between 0 and 100"
          ))
      }
    case .time, .parkingTime:
      if dimension.volume < 0 {
        errors.append(
          .invalidValue(
            field: "\(fieldPrefix).volume",
            reason: "Must be greater than or equal to 0"
          ))
      }
    case .flat:
      errors.append(
        .invalidValue(
          field: "\(fieldPrefix).type",
          reason: "FLAT dimension type is not allowed in Sessions"
        ))
    }
  }
}
