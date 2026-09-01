import Darwin
import Foundation
import GameModeCore

struct SessionOwner: Codable, Equatable, Sendable {
  var suppressHotCorners: Bool
  var processID: Int32?
}

struct GamingSessionState: Codable, Equatable, Sendable {
  let originalGameModePolicy: GameModePolicy
  var hotCorners: HotCornerSnapshot?
  var owners: [String: SessionOwner]

  var suppressesHotCorners: Bool {
    owners.values.contains { $0.suppressHotCorners }
  }
}

struct SessionStore: Sendable {
  private let directoryURL: URL
  private let stateURL: URL
  private let lockURL: URL

  init(fileManager: FileManager = .default) {
    let applicationSupport = fileManager.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    )[0]
    directoryURL = applicationSupport.appendingPathComponent("GameModeTray", isDirectory: true)
    stateURL = directoryURL.appendingPathComponent("session.json")
    lockURL = directoryURL.appendingPathComponent("session.lock")
  }

  func withLock<T>(_ operation: (LockedSessionStore) throws -> T) throws -> T {
    try FileManager.default.createDirectory(
      at: directoryURL,
      withIntermediateDirectories: true
    )

    let descriptor = open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
    guard descriptor >= 0 else {
      throw SessionStoreError.systemCallFailed(
        operation: "open",
        message: String(cString: strerror(errno))
      )
    }
    defer {
      flock(descriptor, LOCK_UN)
      close(descriptor)
    }

    guard flock(descriptor, LOCK_EX) == 0 else {
      throw SessionStoreError.systemCallFailed(
        operation: "flock",
        message: String(cString: strerror(errno))
      )
    }

    return try operation(LockedSessionStore(stateURL: stateURL))
  }
}

struct LockedSessionStore {
  let stateURL: URL

  func load() throws -> GamingSessionState? {
    guard FileManager.default.fileExists(atPath: stateURL.path) else {
      return nil
    }
    return try JSONDecoder().decode(
      GamingSessionState.self,
      from: Data(contentsOf: stateURL)
    )
  }

  func save(_ state: GamingSessionState) throws {
    try JSONEncoder().encode(state).write(to: stateURL, options: .atomic)
  }

  func clear() throws {
    guard FileManager.default.fileExists(atPath: stateURL.path) else {
      return
    }
    try FileManager.default.removeItem(at: stateURL)
  }
}

enum SessionStoreError: LocalizedError {
  case systemCallFailed(operation: String, message: String)

  var errorDescription: String? {
    switch self {
    case .systemCallFailed(let operation, let message):
      return "\(operation) failed while locking the gaming session: \(message)"
    }
  }
}
