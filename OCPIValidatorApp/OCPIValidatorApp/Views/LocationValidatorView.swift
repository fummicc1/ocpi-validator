import OCPIValidator
import SwiftUI

struct LocationValidatorView: View {
  @State private var jsonInput: String = ""
  @State private var validationResult: String = ""
  @State private var isValid: Bool = false

  var body: some View {
    HSplitView {
      TextEditor(text: $jsonInput)
        .font(.system(.body, design: .monospaced))
        .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
        .border(Color.gray.opacity(0.2))

      VStack {
        if !validationResult.isEmpty {
          Text(isValid ? "Valid ✅" : "Invalid ❌")
            .font(.headline)
            .foregroundColor(isValid ? .green : .red)
            .padding()

          ScrollView {
            Text(validationResult)
              .font(.system(.body, design: .monospaced))
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding()
          }
        }

        HStack {
          Button("Load Sample") {
            jsonInput = SampleJSON.location
          }

          Button("Format JSON") {
            jsonInput = jsonInput.formatJSON()
          }
          .disabled(!jsonInput.isValidJSON)

          Button("Validate") {
            validateLocation()
          }
          .keyboardShortcut(.return, modifiers: .command)
        }
        .padding()
      }
      .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
    }
    .padding()
  }

  private func validateLocation() {
    guard !jsonInput.isEmpty else {
      validationResult = "Please enter JSON data"
      isValid = false
      return
    }

    guard let jsonData = jsonInput.data(using: .utf8) else {
      validationResult = "Invalid JSON format"
      isValid = false
      return
    }

    do {
      let validator = LocationValidator()
      let result = try validator.validate(jsonData)

      isValid = result.isValid
      if result.isValid {
        validationResult = "Location object is valid"
      } else {
        validationResult = result.errors.map { "• \($0.localizedDescription)" }.joined(
          separator: "\n")
      }
    } catch {
      validationResult = "Validation error: \(error.localizedDescription)"
      isValid = false
    }
  }
}
