import Darwin
import Foundation
import GameModeCore

struct GamingSession: Sendable {
  private let gameMode = GameModeController()
  private let hotCorners = HotCornerController()
  private let store = SessionStore()

  func start(owner: String, processID: Int32? = nil, suppressHotCorners: Bool) throws {
    try validate(owner: owner)
    try validate(processID: processID)
    try store.withLock { lockedStore in
      var previousState = try lockedStore.load()
      if var state = previousState {
        state.owners = state.owners.filter { isProcessAlive($0.value.processID) }
        previousState = state
      }
      var state: GamingSessionState
      if let previousState {
        state = previousState
      } else {
        state = GamingSessionState(
          originalGameModePolicy: try gameMode.policy(),
          hotCorners: nil,
          owners: [:]
        )
      }

      state.owners[owner] = SessionOwner(
        suppressHotCorners: suppressHotCorners,
        processID: processID
      )
      if state.suppressesHotCorners, state.hotCorners == nil {
        state.hotCorners = try hotCorners.snapshot()
      }

      // Persist ownership and the baseline before changing system state so a
      // relaunch can recover after a crash.
      try lockedStore.save(state)
      do {
        try applyActiveState(&state)
        try lockedStore.save(state)
      } catch {
        let startError = error
        do {
          if var previousState {
            try lockedStore.save(previousState)
            try applyState(&previousState)
            if previousState.owners.isEmpty {
              try lockedStore.clear()
            } else {
              try lockedStore.save(previousState)
            }
          } else {
            try restoreSystemState(state)
            try lockedStore.clear()
          }
        } catch let rollbackError {
          throw SessionError.startAndRollbackFailed(
            startError: startError,
            rollbackError: rollbackError
          )
        }
        throw startError
      }
    }
  }

  func stop(owner: String) throws {
    try validate(owner: owner)
    try store.withLock { lockedStore in
      guard var state = try lockedStore.load() else {
        return
      }

      state.owners = state.owners.filter { isProcessAlive($0.value.processID) }
      state.owners.removeValue(forKey: owner)
      try lockedStore.save(state)

      if state.owners.isEmpty {
        try restoreSystemState(state)
        try lockedStore.clear()
      } else {
        try applyActiveState(&state)
        try lockedStore.save(state)
      }
    }
  }

  func setHotCornerSuppression(owner: String, processID: Int32? = nil, enabled: Bool) throws {
    try start(owner: owner, processID: processID, suppressHotCorners: enabled)
  }

  private func applyState(_ state: inout GamingSessionState) throws {
    if state.owners.isEmpty {
      try restoreSystemState(state)
    } else {
      try applyActiveState(&state)
    }
  }

  private func applyActiveState(_ state: inout GamingSessionState) throws {
    try gameMode.setPolicy(.on)
    if state.suppressesHotCorners {
      try hotCorners.suppress()
    } else if let snapshot = state.hotCorners {
      try hotCorners.restore(snapshot)
      state.hotCorners = nil
    }
  }

  private func restoreSystemState(_ state: GamingSessionState) throws {
    var errors: [Error] = []
    if let snapshot = state.hotCorners {
      do {
        try hotCorners.restore(snapshot)
      } catch {
        errors.append(error)
      }
    }
    do {
      try gameMode.setPolicy(state.originalGameModePolicy)
    } catch {
      errors.append(error)
    }

    if !errors.isEmpty {
      throw SessionError.restoreFailed(errors)
    }
  }

  private func validate(owner: String) throws {
    guard !owner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw SessionError.invalidOwner
    }
  }

  private func validate(processID: Int32?) throws {
    guard processID == nil || processID! > 0 else {
      throw SessionError.invalidProcessID
    }
  }

  private func isProcessAlive(_ processID: Int32?) -> Bool {
    guard let processID else {
      return true
    }
    if kill(processID, 0) == 0 {
      return true
    }
    return errno == EPERM
  }
}

enum SessionError: LocalizedError {
  case invalidOwner
  case invalidProcessID
  case startAndRollbackFailed(startError: Error, rollbackError: Error)
  case restoreFailed([Error])

  var errorDescription: String? {
    switch self {
    case .invalidOwner:
      return "A gaming session owner is required."
    case .invalidProcessID:
      return "A gaming session process ID must be greater than zero."
    case .startAndRollbackFailed(let startError, let rollbackError):
      return """
        The gaming session could not start, and its settings could not be rolled back.

        Start error: \(startError.localizedDescription)

        Rollback error: \(rollbackError.localizedDescription)
        """
    case .restoreFailed(let errors):
      return "Some gaming settings could not be restored:\n\n"
        + errors.map { $0.localizedDescription }.joined(separator: "\n\n")
    }
  }
}
