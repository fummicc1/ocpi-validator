import Testing

@testable import OCPIValidator

struct LocationValidatorTests {
  @Test("Valid location should pass validation")
  func testValidLocation() async throws {
    let validator = LocationValidator()
    let json = """
      {
          "id": "LOC1",
          "type": "ON_STREET",
          "name": "Downtown Charging Station",
          "address": "123 Main St",
          "city": "Example City",
          "postal_code": "12345",
          "country": "US",
          "coordinates": {
              "latitude": "32.7767",
              "longitude": "-96.7970"
          },
          "evses": [
              {
                  "uid": "EVSE1",
                  "status": "AVAILABLE",
                  "connectors": [
                      {
                          "id": "1",
                          "standard": "IEC_62196_T2",
                          "format": "SOCKET",
                          "power_type": "AC_3_PHASE",
                          "max_voltage": 400,
                          "max_amperage": 32,
                          "last_updated": "2023-12-25T10:00:00Z"
                      }
                  ],
                  "last_updated": "2023-12-25T10:00:00Z"
              }
          ],
          "time_zone": "America/Chicago",
          "last_updated": "2023-12-25T10:00:00Z"
      }
      """.data(using: .utf8)!

    let result = try validator.validate(json)
    #expect(result.isValid)
    #expect(result.errors.isEmpty)
  }

  @Test("Location with missing required fields should fail validation")
  func testInvalidLocation_MissingRequiredFields() async throws {
    let validator = LocationValidator()
    let json = """
      {
          "type": "ON_STREET",
          "coordinates": {
              "latitude": "32.7767",
              "longitude": "-96.7970"
          },
          "last_updated": "2023-12-25T10:00:00Z"
      }
      """.data(using: .utf8)!

    let result = try validator.validate(json)
    #expect(!result.isValid)
    #expect(result.errors.count == 5)
    #expect(
      result.errors.contains { error in
        if case .missingRequiredField("id") = error { return true }
        return false
      })
    #expect(
      result.errors.contains { error in
        if case .missingRequiredField("name") = error { return true }
        return false
      })
    #expect(
      result.errors.contains { error in
        if case .missingRequiredField("address") = error { return true }
        return false
      })
    #expect(
      result.errors.contains { error in
        if case .missingRequiredField("city") = error { return true }
        return false
      })
    #expect(
      result.errors.contains { error in
        if case .missingRequiredField("country") = error { return true }
        return false
      })
  }

  @Test("Location with invalid coordinates should fail validation")
  func testInvalidLocation_InvalidCoordinates() async throws {
    let validator = LocationValidator()
    let json = """
      {
          "id": "LOC1",
          "type": "ON_STREET",
          "name": "Downtown Charging Station",
          "address": "123 Main St",
          "city": "Example City",
          "postal_code": "12345",
          "country": "US",
          "coordinates": {
              "latitude": "91.0000",
              "longitude": "181.0000"
          },
          "time_zone": "America/Chicago",
          "last_updated": "2023-12-25T10:00:00Z"
      }
      """.data(using: .utf8)!

    let result = try validator.validate(json)
    #expect(!result.isValid)
    #expect(
      result.errors.contains { error in
        if case .invalidValue(field: "coordinates.latitude", reason: "Must be between -90 and 90") =
          error
        {
          return true
        }
        return false
      })
    #expect(
      result.errors.contains { error in
        if case .invalidValue(
          field: "coordinates.longitude", reason: "Must be between -180 and 180") = error
        {
          return true
        }
        return false
      })
  }

  @Test("Location with invalid time zone should fail validation")
  func testInvalidLocation_InvalidTimeZone() async throws {
    let validator = LocationValidator()
    let json = """
      {
          "id": "LOC1",
          "type": "ON_STREET",
          "name": "Downtown Charging Station",
          "address": "123 Main St",
          "city": "Example City",
          "postal_code": "12345",
          "country": "US",
          "coordinates": {
              "latitude": "32.7767",
              "longitude": "-96.7970"
          },
          "time_zone": "Invalid/TimeZone",
          "last_updated": "2023-12-25T10:00:00Z"
      }
      """.data(using: .utf8)!

    let result = try validator.validate(json)
    #expect(!result.isValid)
    #expect(
      result.errors.contains { error in
        if case .invalidValue(field: "time_zone", reason: "Invalid time zone identifier") = error {
          return true
        }
        return false
      })
  }

  @Test("Location with invalid EVSE should fail validation")
  func testInvalidLocation_InvalidEVSE() async throws {
    let validator = LocationValidator()
    let json = """
      {
          "id": "LOC1",
          "type": "ON_STREET",
          "name": "Downtown Charging Station",
          "address": "123 Main St",
          "city": "Example City",
          "postal_code": "12345",
          "country": "US",
          "coordinates": {
              "latitude": "32.7767",
              "longitude": "-96.7970"
          },
          "evses": [
              {
                  "uid": "",
                  "status": "AVAILABLE",
                  "connectors": [],
                  "last_updated": "2023-12-25T10:00:00Z"
              }
          ],
          "time_zone": "America/Chicago",
          "last_updated": "2023-12-25T10:00:00Z"
      }
      """.data(using: .utf8)!

    let result = try validator.validate(json)
    #expect(!result.isValid)
    #expect(
      result.errors.contains { error in
        if case .missingRequiredField("evses[0].uid") = error { return true }
        return false
      })
    #expect(
      result.errors.contains { error in
        if case .missingRequiredField("evses[0].connectors") = error { return true }
        return false
      })
  }

  @Test("Location with invalid connector should fail validation")
  func testInvalidLocation_InvalidConnector() async throws {
    let validator = LocationValidator()
    let json = """
      {
          "id": "LOC1",
          "type": "ON_STREET",
          "name": "Downtown Charging Station",
          "address": "123 Main St",
          "city": "Example City",
          "postal_code": "12345",
          "country": "US",
          "coordinates": {
              "latitude": "32.7767",
              "longitude": "-96.7970"
          },
          "evses": [
              {
                  "uid": "EVSE1",
                  "status": "AVAILABLE",
                  "connectors": [
                      {
                          "id": "",
                          "standard": "IEC_62196_T2",
                          "format": "SOCKET",
                          "power_type": "AC_3_PHASE",
                          "max_voltage": 0,
                          "max_amperage": 0,
                          "last_updated": "2023-12-25T10:00:00Z"
                      }
                  ],
                  "last_updated": "2023-12-25T10:00:00Z"
              }
          ],
          "time_zone": "America/Chicago",
          "last_updated": "2023-12-25T10:00:00Z"
      }
      """.data(using: .utf8)!

    let result = try validator.validate(json)
    #expect(!result.isValid)
    #expect(
      result.errors.contains { error in
        if case .missingRequiredField("evses[0].connectors[0].id") = error { return true }
        return false
      })
    #expect(
      result.errors.contains { error in
        if case .invalidValue(
          field: "evses[0].connectors[0].max_voltage", reason: "Must be greater than 0") = error
        {
          return true
        }
        return false
      })
    #expect(
      result.errors.contains { error in
        if case .invalidValue(
          field: "evses[0].connectors[0].max_amperage", reason: "Must be greater than 0") = error
        {
          return true
        }
        return false
      })
  }
}
