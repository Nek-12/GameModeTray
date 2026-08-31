import Foundation
import GameModeCore

struct GamingSession: Sendable {
  private let gameMode = GameModeController()
  private let hotCorners = HotCornerController()
  private let backupStore = BackupStore()

  func start(suppressHotCorners: Bool) throws {
    if let existingBackup = try backupStore.load() {
      try gameMode.setPolicy(.on)
      if suppressHotCorners, existingBackup.hotCorners != nil {
        try hotCorners.suppress()
      }
      return
    }

    let policy = try gameMode.policy()
    let cornerSnapshot = suppressHotCorners ? try hotCorners.snapshot() : nil
    let backup = SessionBackup(gameModePolicy: policy, hotCorners: cornerSnapshot)

    // Persist the baseline before changing system state so a relaunch can restore it after a crash.
    try backupStore.save(backup)
    do {
      try gameMode.setPolicy(.on)
      if suppressHotCorners {
        try hotCorners.suppress()
      }
    } catch {
      try? restore()
      throw error
    }
  }

  func stop() throws {
    try restore()
  }

  func setHotCornerSuppression(_ enabled: Bool) throws {
    guard let backup = try backupStore.load() else {
      return
    }
    if enabled {
      if backup.hotCorners == nil {
        let updated = SessionBackup(
          gameModePolicy: backup.gameModePolicy,
          hotCorners: try hotCorners.snapshot()
        )
        try backupStore.save(updated)
      }
      try hotCorners.suppress()
    } else if let snapshot = backup.hotCorners {
      try hotCorners.restore(snapshot)
      let updated = SessionBackup(
        gameModePolicy: backup.gameModePolicy,
        hotCorners: nil
      )
      try backupStore.save(updated)
    }
  }

  private func restore() throws {
    guard let backup = try backupStore.load() else {
      return
    }

    var errors: [Error] = []
    if let snapshot = backup.hotCorners {
      do {
        try hotCorners.restore(snapshot)
      } catch {
        errors.append(error)
      }
    }
    do {
      try gameMode.setPolicy(backup.gameModePolicy)
    } catch {
      errors.append(error)
    }

    if errors.isEmpty {
      backupStore.clear()
    } else {
      throw SessionError.restoreFailed(errors)
    }
  }
}

enum SessionError: LocalizedError {
  case restoreFailed([Error])

  var errorDescription: String? {
    switch self {
    case .restoreFailed(let errors):
      return "Some gaming settings could not be restored:\n\n"
        + errors.map { $0.localizedDescription }.joined(separator: "\n\n")
    }
  }
}
