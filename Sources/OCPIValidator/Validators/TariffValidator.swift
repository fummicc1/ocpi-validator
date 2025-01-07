import Foundation

public struct TariffValidator {
  public init() {}

  public func validate(_ jsonData: Data) throws -> ValidationResult {
    var errors: [ValidationError] = []

    do {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601

      let tariff = try decoder.decode(Tariff.self, from: jsonData)

      // Required fields validation
      if tariff.id.isEmpty {
        errors.append(.missingRequiredField("id"))
      }

      if tariff.currency.isEmpty {
        errors.append(.missingRequiredField("currency"))
      } else if !isValidCurrencyCode(tariff.currency) {
        errors.append(.invalidValue(field: "currency", reason: "Invalid ISO 4217 currency code"))
      }

      if tariff.countryCode.isEmpty {
        errors.append(.missingRequiredField("country_code"))
      } else if !isValidCountryCode(tariff.countryCode) {
        errors.append(
          .invalidValue(field: "country_code", reason: "Invalid ISO 3166-1 alpha-2 country code"))
      }

      if tariff.partyId.isEmpty {
        errors.append(.missingRequiredField("party_id"))
      }

      if tariff.elements.isEmpty {
        errors.append(.missingRequiredField("elements"))
      }

      // Validate each tariff element
      for (elementIndex, element) in tariff.elements.enumerated() {
        if element.priceComponents.isEmpty {
          errors.append(.missingRequiredField("elements[\(elementIndex)].price_components"))
        }

        // Validate price components
        for (componentIndex, component) in element.priceComponents.enumerated() {
          if component.stepSize <= 0 {
            errors.append(
              .invalidValue(
                field: "elements[\(elementIndex)].price_components[\(componentIndex)].step_size",
                reason: "Must be greater than 0"
              ))
          }

          if let vat = component.vat {
            if vat < 0 || vat > 100 {
              errors.append(
                .invalidValue(
                  field: "elements[\(elementIndex)].price_components[\(componentIndex)].vat",
                  reason: "Must be between 0 and 100"
                ))
            }
          }
        }

        // Validate restrictions if present
        if let restrictions = element.restrictions {
          validateTimeRestrictions(restrictions, elementIndex: elementIndex, errors: &errors)
          validatePowerRestrictions(restrictions, elementIndex: elementIndex, errors: &errors)
          validateDurationRestrictions(restrictions, elementIndex: elementIndex, errors: &errors)
        }
      }

      // Validate date ranges
      if let startDateTime = tariff.startDateTime,
        let endDateTime = tariff.endDateTime,
        startDateTime >= endDateTime
      {
        errors.append(
          .invalidValue(
            field: "end_date_time",
            reason: "Must be later than start_date_time"
          ))
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

  private func validateTimeRestrictions(
    _ restrictions: TariffRestrictions, elementIndex: Int, errors: inout [ValidationError]
  ) {
    if let startTime = restrictions.startTime {
      if !isValidTimeString(startTime) {
        errors.append(
          .invalidValue(
            field: "elements[\(elementIndex)].restrictions.start_time",
            reason: "Invalid time format. Must be in HH:mm format"
          ))
      }
    }

    if let endTime = restrictions.endTime {
      if !isValidTimeString(endTime) {
        errors.append(
          .invalidValue(
            field: "elements[\(elementIndex)].restrictions.end_time",
            reason: "Invalid time format. Must be in HH:mm format"
          ))
      }
    }

    if let startDate = restrictions.startDate,
      let endDate = restrictions.endDate,
      startDate >= endDate
    {
      errors.append(
        .invalidValue(
          field: "elements[\(elementIndex)].restrictions.end_date",
          reason: "Must be later than start_date"
        ))
    }
  }

  private func validatePowerRestrictions(
    _ restrictions: TariffRestrictions, elementIndex: Int, errors: inout [ValidationError]
  ) {
    if let minKwh = restrictions.minKwh, minKwh < 0 {
      errors.append(
        .invalidValue(
          field: "elements[\(elementIndex)].restrictions.min_kwh",
          reason: "Must be greater than or equal to 0"
        ))
    }

    if let maxKwh = restrictions.maxKwh, maxKwh < 0 {
      errors.append(
        .invalidValue(
          field: "elements[\(elementIndex)].restrictions.max_kwh",
          reason: "Must be greater than or equal to 0"
        ))
    }

    if let minPower = restrictions.minPower, minPower < 0 {
      errors.append(
        .invalidValue(
          field: "elements[\(elementIndex)].restrictions.min_power",
          reason: "Must be greater than or equal to 0"
        ))
    }

    if let maxPower = restrictions.maxPower, maxPower < 0 {
      errors.append(
        .invalidValue(
          field: "elements[\(elementIndex)].restrictions.max_power",
          reason: "Must be greater than or equal to 0"
        ))
    }

    if let minKwh = restrictions.minKwh,
      let maxKwh = restrictions.maxKwh,
      minKwh > maxKwh
    {
      errors.append(
        .invalidValue(
          field: "elements[\(elementIndex)].restrictions.max_kwh",
          reason: "Must be greater than min_kwh"
        ))
    }

    if let minPower = restrictions.minPower,
      let maxPower = restrictions.maxPower,
      minPower > maxPower
    {
      errors.append(
        .invalidValue(
          field: "elements[\(elementIndex)].restrictions.max_power",
          reason: "Must be greater than min_power"
        ))
    }
  }

  private func validateDurationRestrictions(
    _ restrictions: TariffRestrictions, elementIndex: Int, errors: inout [ValidationError]
  ) {
    if let minDuration = restrictions.minDuration, minDuration < 0 {
      errors.append(
        .invalidValue(
          field: "elements[\(elementIndex)].restrictions.min_duration",
          reason: "Must be greater than or equal to 0"
        ))
    }

    if let maxDuration = restrictions.maxDuration, maxDuration < 0 {
      errors.append(
        .invalidValue(
          field: "elements[\(elementIndex)].restrictions.max_duration",
          reason: "Must be greater than or equal to 0"
        ))
    }

    if let minDuration = restrictions.minDuration,
      let maxDuration = restrictions.maxDuration,
      minDuration > maxDuration
    {
      errors.append(
        .invalidValue(
          field: "elements[\(elementIndex)].restrictions.max_duration",
          reason: "Must be greater than min_duration"
        ))
    }
  }

  private func isValidTimeString(_ time: String) -> Bool {
    let timeRegex = try! NSRegularExpression(pattern: "^([01]?[0-9]|2[0-3]):[0-5][0-9]$")
    let range = NSRange(location: 0, length: time.utf16.count)
    return timeRegex.firstMatch(in: time, range: range) != nil
  }

  private func isValidCurrencyCode(_ code: String) -> Bool {
    // Simple validation for ISO 4217 currency code format
    let currencyRegex = try! NSRegularExpression(pattern: "^[A-Z]{3}$")
    let range = NSRange(location: 0, length: code.utf16.count)
    return currencyRegex.firstMatch(in: code, range: range) != nil
  }

  private func isValidCountryCode(_ code: String) -> Bool {
    // Simple validation for ISO 3166-1 alpha-2 country code format
    let countryRegex = try! NSRegularExpression(pattern: "^[A-Z]{2}$")
    let range = NSRange(location: 0, length: code.utf16.count)
    return countryRegex.firstMatch(in: code, range: range) != nil
  }
}
