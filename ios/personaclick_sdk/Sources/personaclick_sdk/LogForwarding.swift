import Foundation
@_spi(Bridge) import PersonaClick

/// The native SDK's log messages, for the engines whose Dart set a log handler (`PersonaClick.setLogHandler`).
/// The native handler is process-global: it is set while at least one engine wants the messages, and
/// removed when the last one stops or goes. Each message goes to every such engine.
final class LogForwarding {
  static let shared = LogForwarding()

  /// One engine's receiver.
  final class Sink {
    let send: (PersonaClick.SdkLogMessage) -> Void

    init(_ send: @escaping (PersonaClick.SdkLogMessage) -> Void) {
      self.send = send
    }
  }

  private let lock = NSLock()
  private var sinks: [Sink] = []

  /// Sets the native handler. Tests record what it is set to.
  var install: (((PersonaClick.SdkLogMessage) -> Void)?) -> Void = { handler in
    PersonaClick.setLogHandler(handler)
  }

  func add(_ sink: Sink) {
    lock.lock()
    guard !sinks.contains(where: { $0 === sink }) else {
      lock.unlock()
      return
    }
    sinks.append(sink)
    let first = sinks.count == 1
    lock.unlock()
    if first { install { [weak self] message in self?.forward(message) } }
  }

  func remove(_ sink: Sink) {
    lock.lock()
    let before = sinks.count
    sinks.removeAll { $0 === sink }
    let emptied = before > 0 && sinks.isEmpty
    lock.unlock()
    if emptied { install(nil) }
  }

  /// Called by the native SDK on a background queue.
  func forward(_ message: PersonaClick.SdkLogMessage) {
    lock.lock()
    let targets = sinks
    lock.unlock()
    targets.forEach { $0.send(message) }
  }

  var attached: Int {
    lock.lock()
    defer { lock.unlock() }
    return sinks.count
  }
}

extension PersonaClick.LogLevel {
  /// The level's name in the contract: `debug`, `info`, `warning`, `error`, `none`.
  var wireName: String { "\(self)" }
}

extension PersonaClick.SdkLogMessage {
  func toWire() -> SdkLogMessageWire {
    SdkLogMessageWire(
      level: level.wireName,
      code: code,
      message: message,
      shopId: shopId,
      context: context.mapValues { $0 as Any? }
    )
  }
}
