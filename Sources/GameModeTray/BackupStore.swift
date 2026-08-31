import Foundation
import GameModeCore

struct BackupStore: Sendable {
  private var defaults: UserDefaults {
    UserDefaults(suiteName: "com.nek12.GameModeTray.shared")!
  }
  private let backupKey = "activeSessionBackup"

  func load() throws -> SessionBackup? {
    guard let data = defaults.data(forKey: backupKey) else {
      return nil
    }
    return try JSONDecoder().decode(SessionBackup.self, from: data)
  }

  func save(_ backup: SessionBackup) throws {
    defaults.set(try JSONEncoder().encode(backup), forKey: backupKey)
  }

  func clear() {
    defaults.removeObject(forKey: backupKey)
  }
}
