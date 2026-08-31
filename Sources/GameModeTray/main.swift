import AppKit

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments == ["--start-session"] || arguments == ["--stop-session"] {
  do {
    let session = GamingSession()
    if arguments[0] == "--start-session" {
      try session.start(suppressHotCorners: true)
    } else {
      try session.stop()
    }
    exit(EXIT_SUCCESS)
  } catch {
    FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
    exit(EXIT_FAILURE)
  }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
