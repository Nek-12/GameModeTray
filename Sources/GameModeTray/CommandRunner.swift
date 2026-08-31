import Foundation

struct CommandOutput: Sendable {
  let standardOutput: String
  let standardError: String
}

enum CommandError: LocalizedError {
  case failed(executable: String, arguments: [String], status: Int32, output: String)

  var errorDescription: String? {
    switch self {
    case .failed(let executable, let arguments, let status, let output):
      let command = ([executable] + arguments).joined(separator: " ")
      return "\(command) exited with status \(status).\n\n\(output)"
    }
  }
}

struct CommandRunner: Sendable {
  func run(_ executable: String, _ arguments: [String]) throws -> CommandOutput {
    let process = Process()
    let standardOutput = Pipe()
    let standardError = Pipe()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = standardOutput
    process.standardError = standardError

    try process.run()
    process.waitUntilExit()

    let output = String(
      decoding: standardOutput.fileHandleForReading.readDataToEndOfFile(),
      as: UTF8.self
    )
    let error = String(
      decoding: standardError.fileHandleForReading.readDataToEndOfFile(),
      as: UTF8.self
    )

    guard process.terminationStatus == 0 else {
      throw CommandError.failed(
        executable: executable,
        arguments: arguments,
        status: process.terminationStatus,
        output: [output, error].filter { !$0.isEmpty }.joined(separator: "\n")
      )
    }

    return CommandOutput(standardOutput: output, standardError: error)
  }
}
