import Foundation
import GameModeCore

struct HotCornerController: Sendable {
  private let runner = CommandRunner()
  private let domain = "com.apple.dock"

  func snapshot() throws -> HotCornerSnapshot {
    var values: [String: Int] = [:]
    var absentKeys = Set<String>()

    for key in HotCornerSnapshot.keys {
      do {
        let output = try runner.run("/usr/bin/defaults", ["read", domain, key])
          .standardOutput
          .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Int(output) else {
          throw HotCornerError.invalidValue(key: key, value: output)
        }
        values[key] = value
      } catch let error as CommandError {
        if case .failed(_, _, let status, _) = error, status == 1 {
          absentKeys.insert(key)
        } else {
          throw error
        }
      }
    }

    return HotCornerSnapshot(values: values, absentKeys: absentKeys)
  }

  func suppress() throws {
    for key in HotCornerSnapshot.keys {
      _ = try runner.run("/usr/bin/defaults", ["write", domain, key, "-int", "0"])
    }
    try restartDock()
  }

  func restore(_ snapshot: HotCornerSnapshot) throws {
    for key in snapshot.absentKeys {
      do {
        _ = try runner.run("/usr/bin/defaults", ["delete", domain, key])
      } catch let error as CommandError {
        if case .failed(_, _, let status, _) = error, status != 1 {
          throw error
        }
      }
    }
    for (key, value) in snapshot.values {
      _ = try runner.run("/usr/bin/defaults", ["write", domain, key, "-int", String(value)])
    }
    try restartDock()
  }

  private func restartDock() throws {
    var lastUnavailableError: Error?

    for _ in 0..<20 {
      do {
        _ = try runner.run("/usr/bin/killall", ["Dock"])
        return
      } catch let error as CommandError {
        guard case .failed(_, _, let status, let output) = error,
          status == 1,
          output.contains("No matching processes")
        else {
          throw error
        }
        lastUnavailableError = error
        Thread.sleep(forTimeInterval: 0.1)
      }
    }

    throw lastUnavailableError ?? HotCornerError.dockUnavailable
  }
}

enum HotCornerError: LocalizedError {
  case dockUnavailable
  case invalidValue(key: String, value: String)

  var errorDescription: String? {
    switch self {
    case .dockUnavailable:
      return "Dock did not become available to reload Hot Corner settings."
    case .invalidValue(let key, let value):
      return "The Dock preference \(key) has an invalid value: \(value)"
    }
  }
}
