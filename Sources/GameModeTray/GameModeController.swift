import Foundation
import GameModeCore

struct GameModeController: Sendable {
  private let runner = CommandRunner()

  func policy() throws -> GameModePolicy {
    let tool = try toolPath()
    let status = try runner.run(tool, ["game-mode", "status"]).standardOutput
    guard let policy = GameModePolicyParser.parse(status: status) else {
      throw ControllerError.unrecognizedGameModeStatus(status)
    }
    return policy
  }

  func setPolicy(_ policy: GameModePolicy) throws {
    let tool = try toolPath()
    _ = try runner.run(tool, ["game-mode", "set", policy.rawValue])
  }

  private func toolPath() throws -> String {
    let output = try runner.run("/usr/bin/xcrun", ["--find", "gamepolicyctl"])
      .standardOutput
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard !output.isEmpty else {
      throw ControllerError.gamePolicyToolUnavailable
    }
    return output
  }
}

enum ControllerError: LocalizedError {
  case gamePolicyToolUnavailable
  case unrecognizedGameModeStatus(String)

  var errorDescription: String? {
    switch self {
    case .gamePolicyToolUnavailable:
      return
        "gamepolicyctl is unavailable. Install Xcode 27 or newer and select it with xcode-select."
    case .unrecognizedGameModeStatus(let status):
      return "gamepolicyctl returned an unrecognized status:\n\n\(status)"
    }
  }
}
