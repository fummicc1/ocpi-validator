import Foundation

public struct LocationValidator {
  public init() {}

  public func validate(_ jsonData: Data) throws -> ValidationResult {
    var errors: [ValidationError] = []

    // First, validate required fields using dictionary
    if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
      let requiredFields = ["id", "type", "name", "address", "city", "country", "coordinates", "last_updated"]
      for field in requiredFields {
        if json[field] == nil {
          errors.append(.missingRequiredField(field))
        }
      }

      // Validate coordinates required fields
      if let coordinates = json["coordinates"] as? [String: Any] {
        let requiredCoordinateFields = ["latitude", "longitude"]
        for field in requiredCoordinateFields {
          if coordinates[field] == nil {
            errors.append(.missingRequiredField("coordinates.\(field)"))
          }
        }
      }

      // Validate EVSEs if present
      if let evses = json["evses"] as? [[String: Any]] {
        for (index, evse) in evses.enumerated() {
          let requiredEvseFields = ["uid", "status", "connectors"]
          for field in requiredEvseFields {
            if evse[field] == nil {
              errors.append(.missingRequiredField("evses[\(index)].\(field)"))
            }
          }

          // Validate connectors if present
          if let connectors = evse["connectors"] as? [[String: Any]] {
            for (connectorIndex, connector) in connectors.enumerated() {
              let requiredConnectorFields = ["id", "standard", "format", "power_type", "max_voltage", "max_amperage"]
              for field in requiredConnectorFields {
                if connector[field] == nil {
                  errors.append(.missingRequiredField("evses[\(index)].connectors[\(connectorIndex)].\(field)"))
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

      let location = try decoder.decode(Location.self, from: jsonData)

      validateLocation(location, errors: &errors)

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

  private func validateLocation(_ location: Location, errors: inout [ValidationError]) {
    // Validate coordinates
    validateCoordinates(location.coordinates, errors: &errors)

    // Validate time zone if present
    if !isValidTimeZone(location.timeZone) {
      errors.append(.invalidValue(
        field: "time_zone",
        reason: "Invalid time zone identifier"
      ))
    }

    // Validate EVSEs
    if let evses = location.evses {
      for (index, evse) in evses.enumerated() {
        validateEVSE(evse, index: index, errors: &errors)
      }
    }
  }

  private func validateCoordinates(_ coordinates: Location.Coordinates, errors: inout [ValidationError]) {
    if let latitude = Double(coordinates.latitude), latitude < -90 || latitude > 90 {
      errors.append(.invalidValue(
        field: "coordinates.latitude",
        reason: "Must be between -90 and 90"
      ))
    }

    if let longitude = Double(coordinates.longitude), longitude < -180 || longitude > 180 {
      errors.append(.invalidValue(
        field: "coordinates.longitude",
        reason: "Must be between -180 and 180"
      ))
    }
  }

  private func validateEVSE(_ evse: EVSE, index: Int, errors: inout [ValidationError]) {
    if evse.uid.isEmpty {
        errors.append(.missingRequiredField("evses[\(index)].uid"))
    }
    
    if evse.connectors.isEmpty {
        errors.append(.missingRequiredField("evses[\(index)].connectors"))
    }
    
    // Validate connectors
    for (connectorIndex, connector) in evse.connectors.enumerated() {
        validateConnector(connector, evseIndex: index, connectorIndex: connectorIndex, errors: &errors)
    }
  }

  private func validateConnector(_ connector: Connector, evseIndex: Int, connectorIndex: Int, errors: inout [ValidationError]) {
    let prefix = "evses[\(evseIndex)].connectors[\(connectorIndex)]"

    if connector.id.isEmpty {
      errors.append(.missingRequiredField("\(prefix).id"))
    }

    if connector.maxVoltage <= 0 {
      errors.append(.invalidValue(
        field: "\(prefix).max_voltage",
        reason: "Must be greater than 0"
      ))
    }

    if connector.maxAmperage <= 0 {
      errors.append(.invalidValue(
        field: "\(prefix).max_amperage",
        reason: "Must be greater than 0"
      ))
    }
  }

  private func isValidTimeZone(_ identifier: String) -> Bool {
    return TimeZone(identifier: identifier) != nil
  }
}
