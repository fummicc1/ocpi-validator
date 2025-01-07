import Foundation

public struct Token: Codable {
  public let uid: String
  public let type: TokenType
  public let authId: String
  public let visualNumber: String?
  public let issuer: String
  public let valid: Bool
  public let whitelist: WhitelistType
  public let language: String?
  public let lastUpdated: Date

  private enum CodingKeys: String, CodingKey {
    case uid
    case type
    case authId = "auth_id"
    case visualNumber = "visual_number"
    case issuer
    case valid
    case whitelist
    case language
    case lastUpdated = "last_updated"
  }
}

public enum TokenType: String, Codable {
  case ad_hoc_user = "AD_HOC_USER"
  case app_user = "APP_USER"
  case other = "OTHER"
  case rfid = "RFID"
}

public enum WhitelistType: String, Codable {
  case always = "ALWAYS"
  case allowed = "ALLOWED"
  case allowed_offline = "ALLOWED_OFFLINE"
  case never = "NEVER"
  case not_allowed = "NOT_ALLOWED"
}
