import Foundation

public struct LocationValidator {
  public init() {}

  public func validate(_ jsonData: Data) throws -> ValidationResult {
    var errors: [ValidationError] = []

    do {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      let location = try decoder.decode(Location.self, from: jsonData)

      // Required fields validation
      if location.id.isEmpty {
        errors.append(.missingRequiredField("id"))
      }

      if location.address.isEmpty {
        errors.append(.missingRequiredField("address"))
      }

      if location.city.isEmpty {
        errors.append(.missingRequiredField("city"))
      }

      if location.country.isEmpty {
        errors.append(.missingRequiredField("country"))
      }

      // Coordinates validation
      if !isValidLatitude(location.coordinates.latitude) {
        errors.append(.invalidValue(field: "latitude", reason: "Must be between -90 and 90"))
      }

      if !isValidLongitude(location.coordinates.longitude) {
        errors.append(.invalidValue(field: "longitude", reason: "Must be between -180 and 180"))
      }

      // EVSE validation
      if let evses = location.evses {
        for (index, evse) in evses.enumerated() {
          if evse.uid.isEmpty {
            errors.append(.missingRequiredField("evses[\(index)].uid"))
          }

          if evse.connectors.isEmpty {
            errors.append(.missingRequiredField("evses[\(index)].connectors"))
          }

          // Connector validation
          for (connectorIndex, connector) in evse.connectors.enumerated() {
            if connector.id.isEmpty {
              errors.append(
                .missingRequiredField("evses[\(index)].connectors[\(connectorIndex)].id"))
            }

            if connector.maxVoltage <= 0 {
              errors.append(
                .invalidValue(
                  field: "evses[\(index)].connectors[\(connectorIndex)].max_voltage",
                  reason: "Must be greater than 0"))
            }

            if connector.maxAmperage <= 0 {
              errors.append(
                .invalidValue(
                  field: "evses[\(index)].connectors[\(connectorIndex)].max_amperage",
                  reason: "Must be greater than 0"))
            }
          }
        }
      }

      // Time zone validation
      if !isValidTimeZone(location.timeZone) {
        errors.append(.invalidValue(field: "time_zone", reason: "Invalid time zone identifier"))
      }

    } catch {
      if let decodingError = error as? DecodingError {
        switch decodingError {
        case .keyNotFound(let key, _):
          errors.append(.missingRequiredField(key.stringValue))
        case .typeMismatch(_, let context):
          errors.append(
            .invalidFieldType(
              field: context.codingPath.map { $0.stringValue }.joined(separator: "."),
              expectedType: context.debugDescription))
        default:
          errors.append(.invalidJSON)
        }
      } else {
        errors.append(.invalidJSON)
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors)
  }

  private func isValidLatitude(_ latitude: String) -> Bool {
    guard let lat = Double(latitude) else { return false }
    return lat >= -90 && lat <= 90
  }

  private func isValidLongitude(_ longitude: String) -> Bool {
    guard let lon = Double(longitude) else { return false }
    return lon >= -180 && lon <= 180
  }

  private func isValidTimeZone(_ identifier: String) -> Bool {
    return TimeZone(identifier: identifier) != nil
  }
}
