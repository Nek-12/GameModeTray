import Foundation

public struct SessionBackup: Codable, Equatable, Sendable {
  public let gameModePolicy: GameModePolicy
  public let hotCorners: HotCornerSnapshot?

  public init(gameModePolicy: GameModePolicy, hotCorners: HotCornerSnapshot?) {
    self.gameModePolicy = gameModePolicy
    self.hotCorners = hotCorners
  }
}
