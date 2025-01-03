import ArgumentParser
import Foundation
import OCPIValidator

@main
struct OCPIValidatorCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "ocpi-validator",
    abstract: "A tool for validating OCPI JSON data",
    version: "1.0.0"
  )

  @Argument(help: "Path to the JSON file to validate")
  var inputFile: String

  @Option(
    name: .shortAndLong,
    help: "Type of OCPI object to validate (location, tariff, session, cdr, token)")
  var type: String = "location"

  mutating func run() throws {
    let validator = OCPIValidator()

    guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: inputFile)) else {
      print("❌ Error: Could not read file at path: \(inputFile)")
      throw ExitCode.failure
    }

    guard let objectType = OCPIObjectType(rawValue: type.lowercased()) else {
      print("❌ Error: Invalid object type. Supported types: location, tariff, session, cdr, token")
      throw ExitCode.failure
    }

    do {
      let result = try validator.validate(jsonData, type: objectType)
      if result.isValid {
        print("✅ Validation successful")
      } else {
        print("❌ Validation failed")
        for error in result.errors {
          print("- \(error.localizedDescription)")
        }
        throw ExitCode.failure
      }
    } catch {
      print("❌ Error: \(error.localizedDescription)")
      throw ExitCode.failure
    }
  }
}

extension OCPIObjectType: RawRepresentable {
  public init?(rawValue: String) {
    switch rawValue {
    case "location": self = .location
    case "tariff": self = .tariff
    case "session": self = .session
    case "cdr": self = .cdr
    case "token": self = .token
    default: return nil
    }
  }

  public var rawValue: String {
    switch self {
    case .location: return "location"
    case .tariff: return "tariff"
    case .session: return "session"
    case .cdr: return "cdr"
    case .token: return "token"
    }
  }
}
