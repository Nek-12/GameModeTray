import AppKit

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments.count >= 2,
  arguments[0] == "--start-session" || arguments[0] == "--stop-session"
{
  do {
    let session = GamingSession()
    if arguments[0] == "--start-session" {
      let processID: Int32?
      if arguments.count == 4, arguments[2] == "--process-id", let value = Int32(arguments[3]) {
        processID = value
      } else if arguments.count == 2 {
        processID = nil
      } else {
        throw CommandLineError.invalidArguments
      }
      try session.start(
        owner: arguments[1],
        processID: processID,
        suppressHotCorners: true
      )
    } else {
      guard arguments.count == 2 else {
        throw CommandLineError.invalidArguments
      }
      try session.stop(owner: arguments[1])
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

enum CommandLineError: LocalizedError {
  case invalidArguments

  var errorDescription: String? {
    "Usage: GameModeTray --start-session <owner> [--process-id <pid>] | --stop-session <owner>"
  }
}
