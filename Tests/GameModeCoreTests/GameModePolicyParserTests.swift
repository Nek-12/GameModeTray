import GameModeCore
import Testing

@Test func parsesAutomaticPolicy() {
  let status = """
    Game mode is off.
    Game mode enablement policy is currently automatic. The system must meet all specified requirements to enable game mode.
    """

  #expect(GameModePolicyParser.parse(status: status) == .automatic)
}

@Test func parsesForcedOnPolicy() {
  let status = """
    Game mode is on.
    Game mode enablement policy is currently disabled. Game mode is forced always on.
    """

  #expect(GameModePolicyParser.parse(status: status) == .on)
}

@Test func parsesForcedOffPolicy() {
  let status = """
    Game mode is off.
    Game mode enablement policy is currently disabled. Game mode is forced always off.
    """

  #expect(GameModePolicyParser.parse(status: status) == .off)
}

@Test func rejectsUnknownStatus() {
  #expect(GameModePolicyParser.parse(status: "something changed") == nil)
}
