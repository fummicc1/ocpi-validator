import Foundation

public enum DisplayText: Codable {
  case simple(String)
  case localized(language: String, text: String)

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let simpleText = try? container.decode(String.self) {
      self = .simple(simpleText)
    } else {
      let nestedContainer = try decoder.container(keyedBy: CodingKeys.self)
      let language = try nestedContainer.decode(String.self, forKey: .language)
      let text = try nestedContainer.decode(String.self, forKey: .text)
      self = .localized(language: language, text: text)
    }
  }

  public func encode(to encoder: Encoder) throws {
    switch self {
    case .simple(let text):
      var container = encoder.singleValueContainer()
      try container.encode(text)
    case .localized(let language, let text):
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(language, forKey: .language)
      try container.encode(text, forKey: .text)
    }
  }

  private enum CodingKeys: String, CodingKey {
    case language
    case text
  }
}

public struct BusinessDetails: Codable {
  public let name: String
  public let website: URL?
  public let logo: Image?
}

public struct Image: Codable {
  public let url: URL
  public let thumbnail: URL?
  public let category: ImageCategory
  public let type: String
  public let width: Int?
  public let height: Int?
}

public enum ImageCategory: String, Codable {
  case charger
  case entrance
  case location
  case network
  case operatorImage = "operator"
  case other
  case owner
}
