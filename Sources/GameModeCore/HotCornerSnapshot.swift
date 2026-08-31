import Foundation

public struct HotCornerSnapshot: Codable, Equatable, Sendable {
  public static let keys = [
    "wvous-tl-corner",
    "wvous-tr-corner",
    "wvous-bl-corner",
    "wvous-br-corner",
  ]

  public let values: [String: Int]
  public let absentKeys: Set<String>

  public init(values: [String: Int], absentKeys: Set<String>) {
    self.values = values
    self.absentKeys = absentKeys
  }
}
