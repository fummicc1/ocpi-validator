import Foundation

public struct TokenValidator {
    public init() {}
    
    public func validate(_ jsonData: Data) throws -> ValidationResult {
        var errors: [ValidationError] = []
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let token = try decoder.decode(Token.self, from: jsonData)
            
            // Required fields validation
            if token.uid.isEmpty {
                errors.append(.missingRequiredField("uid"))
            }
            
            if token.authId.isEmpty {
                errors.append(.missingRequiredField("auth_id"))
            }
            
            if token.issuer.isEmpty {
                errors.append(.missingRequiredField("issuer"))
            }
            
            // Type-specific validations
            validateTypeSpecificFields(token, errors: &errors)
            
            // Language validation
            if let language = token.language {
                if !isValidLanguageCode(language) {
                    errors.append(.invalidValue(
                        field: "language",
                        reason: "Invalid ISO 639-1 language code"
                    ))
                }
            }
            
            // Whitelist validation
            validateWhitelistConsistency(token, errors: &errors)
            
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
    
    private func validateTypeSpecificFields(_ token: Token, errors: inout [ValidationError]) {
        switch token.type {
        case .rfid:
            // For RFID tokens, visual_number should be present
            if token.visualNumber == nil || token.visualNumber?.isEmpty == true {
                errors.append(.missingRequiredField("visual_number for RFID token"))
            }
            
            // RFID tokens should have a specific format for uid
            if !isValidRFIDUid(token.uid) {
                errors.append(.invalidValue(
                    field: "uid",
                    reason: "Invalid RFID uid format"
                ))
            }
            
        case .app_user:
            // App users might have specific requirements for auth_id format
            if !isValidAppUserAuthId(token.authId) {
                errors.append(.invalidValue(
                    field: "auth_id",
                    reason: "Invalid app user auth_id format"
                ))
            }
            
        case .ad_hoc_user:
            // Ad-hoc users might have specific validation rules
            if token.whitelist == .always || token.whitelist == .allowed_offline {
                errors.append(.invalidValue(
                    field: "whitelist",
                    reason: "Ad-hoc users cannot have ALWAYS or ALLOWED_OFFLINE whitelist type"
                ))
            }
            
        case .other:
            // No specific validation for other types
            break
        }
    }
    
    private func validateWhitelistConsistency(_ token: Token, errors: inout [ValidationError]) {
        // If token is not valid, it should not be whitelisted as ALWAYS or ALLOWED_OFFLINE
        if !token.valid && (token.whitelist == .always || token.whitelist == .allowed_offline) {
            errors.append(.invalidValue(
                field: "whitelist",
                reason: "Invalid tokens cannot have ALWAYS or ALLOWED_OFFLINE whitelist type"
            ))
        }
        
        // If whitelist is NEVER, token should not be valid
        if token.whitelist == .never && token.valid {
            errors.append(.invalidValue(
                field: "valid",
                reason: "Token cannot be valid when whitelist is NEVER"
            ))
        }
    }
    
    private func isValidLanguageCode(_ code: String) -> Bool {
        // Simple validation for ISO 639-1 language code format
        let languageRegex = try! NSRegularExpression(pattern: "^[a-z]{2}$")
        let range = NSRange(location: 0, length: code.utf16.count)
        return languageRegex.firstMatch(in: code, range: range) != nil
    }
    
    private func isValidRFIDUid(_ uid: String) -> Bool {
        // RFID uid format validation (example: should be hexadecimal and have specific length)
        let rfidRegex = try! NSRegularExpression(pattern: "^[A-Fa-f0-9]{8,24}$")
        let range = NSRange(location: 0, length: uid.utf16.count)
        return rfidRegex.firstMatch(in: uid, range: range) != nil
    }
    
    private func isValidAppUserAuthId(_ authId: String) -> Bool {
        // App user auth_id format validation (example: should be email-like)
        let emailRegex = try! NSRegularExpression(pattern: "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
        let range = NSRange(location: 0, length: authId.utf16.count)
        return emailRegex.firstMatch(in: authId, range: range) != nil
    }
} 