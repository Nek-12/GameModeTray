import Foundation

public enum GameModePolicy: String, Codable, Sendable {
  case automatic = "auto"
  case on
  case off
}

public enum GameModePolicyParser {
  private static let automaticStatus =
    "Game mode enablement policy is currently automatic. The system must meet all specified requirements to enable game mode."
  private static let forcedOnStatus =
    "Game mode enablement policy is currently disabled. Game mode is forced always on."
  private static let forcedOffStatus =
    "Game mode enablement policy is currently disabled. Game mode is forced always off."

  public static func parse(status: String) -> GameModePolicy? {
    let policyLines =
      status
      .split(whereSeparator: \.isNewline)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { $0.hasPrefix("Game mode enablement policy ") }

    guard policyLines.count == 1 else {
      return nil
    }

    switch policyLines[0] {
    case forcedOnStatus:
      return .on
    case forcedOffStatus:
      return .off
    case automaticStatus:
      return .automatic
    default:
      return nil
    }
  }
}
