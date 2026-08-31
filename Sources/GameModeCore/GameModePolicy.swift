import Foundation

public enum GameModePolicy: String, Codable, Sendable {
  case automatic = "auto"
  case on
  case off
}

public enum GameModePolicyParser {
  public static func parse(status: String) -> GameModePolicy? {
    let status = status.lowercased()

    if status.contains("forced always on") {
      return .on
    }
    if status.contains("forced always off") {
      return .off
    }
    if status.contains("policy is currently automatic") {
      return .automatic
    }
    return nil
  }
}
