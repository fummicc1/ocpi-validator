import Foundation

extension String {
    func formatJSON() -> String {
        guard let data = self.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formattedData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) else {
            return self
        }
        return String(data: formattedData, encoding: .utf8) ?? self
    }
    
    var isValidJSON: Bool {
        guard let data = self.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: data) else {
            return false
        }
        return true
    }
} 