import Foundation

public struct OCPIValidator {
  private let locationValidator: LocationValidator

  public init() {
    self.locationValidator = LocationValidator()
  }

  /// Validates OCPI JSON data
  /// - Parameters:
  ///   - jsonData: The JSON data to validate
  ///   - type: The type of OCPI object to validate
  /// - Returns: A validation result indicating success or failure with detailed error information
  public func validate(_ jsonData: Data, type: OCPIObjectType) throws -> ValidationResult {
    switch type {
    case .location:
      return try locationValidator.validate(jsonData)
    case .tariff, .session, .cdr, .token:
      // TODO: Implement other validators
      throw ValidationError.notImplemented
    }
  }
}

public enum OCPIObjectType {
  case location
  case tariff
  case session
  case cdr
  case token
}

public struct ValidationResult {
  public let isValid: Bool
  public let errors: [ValidationError]

  public init(isValid: Bool, errors: [ValidationError] = []) {
    self.isValid = isValid
    self.errors = errors
  }
}

public enum ValidationError: Error {
  case notImplemented
  case invalidJSON
  case missingRequiredField(String)
  case invalidFieldType(field: String, expectedType: String)
  case invalidValue(field: String, reason: String)

  public var localizedDescription: String {
    switch self {
    case .notImplemented:
      return "This validation is not implemented yet"
    case .invalidJSON:
      return "Invalid JSON format"
    case .missingRequiredField(let field):
      return "Missing required field: \(field)"
    case .invalidFieldType(let field, let type):
      return "Invalid type for field \(field): expected \(type)"
    case .invalidValue(let field, let reason):
      return "Invalid value for field \(field): \(reason)"
    }
  }
}
