import Testing
@testable import OCPIValidator

struct TokenValidatorTests {
    @Test("Valid token should pass validation")
    func testValidToken() async throws {
        let validator = TokenValidator()
        let json = """
        {
            "uid": "012345678",
            "type": "RFID",
            "auth_id": "FA54320",
            "visual_number": "DF000-2001-8999",
            "issuer": "Example Corp",
            "valid": true,
            "whitelist": "ALLOWED",
            "language": "en",
            "last_updated": "2023-12-25T10:00:00Z"
        }
        """.data(using: .utf8)!
        
        let result = try validator.validate(json)
        #expect(result.isValid)
        #expect(result.errors.isEmpty)
    }
    
    @Test("Token with missing required fields should fail validation")
    func testInvalidToken_MissingRequiredFields() async throws {
        let validator = TokenValidator()
        let json = """
        {
            "type": "RFID",
            "valid": true,
            "whitelist": "ALLOWED",
            "last_updated": "2023-12-25T10:00:00Z"
        }
        """.data(using: .utf8)!
        
        let result = try validator.validate(json)
        #expect(!result.isValid)
        #expect(result.errors.count == 3)
        #expect(result.errors.contains { error in
            if case .missingRequiredField("uid") = error { return true }
            return false
        })
        #expect(result.errors.contains { error in
            if case .missingRequiredField("auth_id") = error { return true }
            return false
        })
        #expect(result.errors.contains { error in
            if case .missingRequiredField("issuer") = error { return true }
            return false
        })
    }
    
    @Test("RFID token with invalid UID format should fail validation")
    func testInvalidToken_InvalidRFIDFormat() async throws {
        let validator = TokenValidator()
        let json = """
        {
            "uid": "invalid-uid",
            "type": "RFID",
            "auth_id": "FA54320",
            "visual_number": "DF000-2001-8999",
            "issuer": "Example Corp",
            "valid": true,
            "whitelist": "ALLOWED",
            "last_updated": "2023-12-25T10:00:00Z"
        }
        """.data(using: .utf8)!
        
        let result = try validator.validate(json)
        #expect(!result.isValid)
        #expect(result.errors.contains { error in
            if case .invalidValue(field: "uid", reason: "Invalid RFID uid format") = error { return true }
            return false
        })
    }
    
    @Test("Invalid whitelist consistency should fail validation")
    func testInvalidToken_WhitelistConsistency() async throws {
        let validator = TokenValidator()
        let json = """
        {
            "uid": "012345678",
            "type": "RFID",
            "auth_id": "FA54320",
            "visual_number": "DF000-2001-8999",
            "issuer": "Example Corp",
            "valid": false,
            "whitelist": "ALWAYS",
            "last_updated": "2023-12-25T10:00:00Z"
        }
        """.data(using: .utf8)!
        
        let result = try validator.validate(json)
        #expect(!result.isValid)
        #expect(result.errors.contains { error in
            if case .invalidValue(field: "whitelist", reason: "Invalid tokens cannot have ALWAYS or ALLOWED_OFFLINE whitelist type") = error { return true }
            return false
        })
    }
    
    @Test("Invalid language code should fail validation")
    func testInvalidToken_InvalidLanguageCode() async throws {
        let validator = TokenValidator()
        let json = """
        {
            "uid": "012345678",
            "type": "RFID",
            "auth_id": "FA54320",
            "visual_number": "DF000-2001-8999",
            "issuer": "Example Corp",
            "valid": true,
            "whitelist": "ALLOWED",
            "language": "invalid",
            "last_updated": "2023-12-25T10:00:00Z"
        }
        """.data(using: .utf8)!
        
        let result = try validator.validate(json)
        #expect(!result.isValid)
        #expect(result.errors.contains { error in
            if case .invalidValue(field: "language", reason: "Invalid ISO 639-1 language code") = error { return true }
            return false
        })
    }
    
    @Test("Invalid JSON should fail validation")
    func testInvalidToken_InvalidJSON() async throws {
        let validator = TokenValidator()
        let json = "invalid json".data(using: .utf8)!
        
        let result = try validator.validate(json)
        #expect(!result.isValid)
        #expect(result.errors.contains { error in
            if case .invalidJSON = error { return true }
            return false
        })
    }
    
    @Test("App user token with invalid auth_id should fail validation")
    func testAppUserToken_InvalidAuthId() async throws {
        let validator = TokenValidator()
        let json = """
        {
            "uid": "app-user-123",
            "type": "APP_USER",
            "auth_id": "invalid-email",
            "issuer": "Example Corp",
            "valid": true,
            "whitelist": "ALLOWED",
            "last_updated": "2023-12-25T10:00:00Z"
        }
        """.data(using: .utf8)!
        
        let result = try validator.validate(json)
        #expect(!result.isValid)
        #expect(result.errors.contains { error in
            if case .invalidValue(field: "auth_id", reason: "Invalid app user auth_id format") = error { return true }
            return false
        })
    }
    
    @Test("Ad-hoc user token with invalid whitelist should fail validation")
    func testAdHocUserToken_InvalidWhitelist() async throws {
        let validator = TokenValidator()
        let json = """
        {
            "uid": "adhoc-123",
            "type": "AD_HOC_USER",
            "auth_id": "ADHOC001",
            "issuer": "Example Corp",
            "valid": true,
            "whitelist": "ALWAYS",
            "last_updated": "2023-12-25T10:00:00Z"
        }
        """.data(using: .utf8)!
        
        let result = try validator.validate(json)
        #expect(!result.isValid)
        #expect(result.errors.contains { error in
            if case .invalidValue(field: "whitelist", reason: "Ad-hoc users cannot have ALWAYS or ALLOWED_OFFLINE whitelist type") = error { return true }
            return false
        })
    }
} 
