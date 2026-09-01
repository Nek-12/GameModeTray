import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let sessionOwner = "tray"
  private let session = GamingSession()
  private let worker = DispatchQueue(label: "com.nek12.GameModeTray.session", qos: .userInitiated)
  private var statusItem: NSStatusItem!
  private var sessionActive = false
  private var suppressHotCorners = true
  private var operationInProgress = false

  private lazy var statusMenuItem = NSMenuItem(
    title: "Starting Gaming Session…", action: nil, keyEquivalent: "")
  private lazy var toggleSessionMenuItem = NSMenuItem(
    title: "Stop Gaming Session",
    action: #selector(toggleSession),
    keyEquivalent: ""
  )
  private lazy var hotCornersMenuItem = NSMenuItem(
    title: "Suppress Hot Corners",
    action: #selector(toggleHotCorners),
    keyEquivalent: ""
  )

  func applicationDidFinishLaunching(_ notification: Notification) {
    configureStatusItem()
    startSession()
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    guard !operationInProgress else {
      return .terminateCancel
    }

    setBusy(true, status: "Restoring System Settings…")
    worker.async { [session] in
      let result = Result { try session.stop(owner: self.sessionOwner) }
      DispatchQueue.main.async {
        switch result {
        case .success:
          NSApplication.shared.reply(toApplicationShouldTerminate: true)
        case .failure(let error):
          self.present(error)
          self.setBusy(false, status: "Gaming Session Active")
          NSApplication.shared.reply(toApplicationShouldTerminate: false)
        }
      }
    }
    return .terminateLater
  }

  private func configureStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.autosaveName = "GameModeTrayStatus"
    statusItem.isVisible = true
    statusItem.button?.title = "🎮 …"
    statusItem.button?.toolTip = "Game Mode Tray"

    let menu = NSMenu()
    statusMenuItem.isEnabled = false
    menu.addItem(statusMenuItem)
    menu.addItem(.separator())
    toggleSessionMenuItem.target = self
    menu.addItem(toggleSessionMenuItem)
    hotCornersMenuItem.target = self
    hotCornersMenuItem.state = .on
    menu.addItem(hotCornersMenuItem)
    menu.addItem(.separator())
    let quitItem = NSMenuItem(
      title: "Quit Game Mode Tray",
      action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q"
    )
    menu.addItem(quitItem)
    statusItem.menu = menu
  }

  @objc private func toggleSession() {
    if sessionActive {
      stopSession()
    } else {
      startSession()
    }
  }

  @objc private func toggleHotCorners() {
    let enabled = !suppressHotCorners
    setBusy(true, status: enabled ? "Suppressing Hot Corners…" : "Restoring Hot Corners…")
    worker.async { [session] in
      let result = Result {
        try session.setHotCornerSuppression(owner: self.sessionOwner, enabled: enabled)
      }
      DispatchQueue.main.async {
        switch result {
        case .success:
          self.suppressHotCorners = enabled
          self.hotCornersMenuItem.state = enabled ? .on : .off
        case .failure(let error):
          self.present(error)
        }
        self.setBusy(
          false, status: self.sessionActive ? "Gaming Session Active" : "Gaming Session Stopped")
      }
    }
  }

  private func startSession() {
    setBusy(true, status: "Starting Gaming Session…")
    worker.async { [session, suppressHotCorners] in
      let result = Result {
        try session.start(owner: self.sessionOwner, suppressHotCorners: suppressHotCorners)
      }
      DispatchQueue.main.async {
        switch result {
        case .success:
          self.sessionActive = true
          self.toggleSessionMenuItem.title = "Stop Gaming Session"
        case .failure(let error):
          self.present(error)
        }
        self.setBusy(
          false, status: result.isSuccess ? "Gaming Session Active" : "Gaming Session Failed")
      }
    }
  }

  private func stopSession() {
    setBusy(true, status: "Restoring System Settings…")
    worker.async { [session] in
      let result = Result { try session.stop(owner: self.sessionOwner) }
      DispatchQueue.main.async {
        switch result {
        case .success:
          self.sessionActive = false
          self.toggleSessionMenuItem.title = "Start Gaming Session"
        case .failure(let error):
          self.present(error)
        }
        self.setBusy(false, status: result.isSuccess ? "Gaming Session Stopped" : "Restore Failed")
      }
    }
  }

  private func setBusy(_ busy: Bool, status: String) {
    operationInProgress = busy
    statusMenuItem.title = status
    toggleSessionMenuItem.isEnabled = !busy
    hotCornersMenuItem.isEnabled = !busy && sessionActive
    statusItem.button?.title = busy ? "🎮 …" : (sessionActive ? "🎮 ON" : "🎮 OFF")
  }

  private func present(_ error: Error) {
    let alert = NSAlert(error: error)
    alert.runModal()
  }
}

extension Result {
  fileprivate var isSuccess: Bool {
    if case .success = self {
      return true
    }
    return false
  }
}
