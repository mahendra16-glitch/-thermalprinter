/// Source of "now" for persistence. Tests can replace [Clock.now].
class Clock {
  Clock._();

  static DateTime Function() now = DateTime.now;

  /// Current time as UTC epoch milliseconds (the storage format).
  static int nowMs() => now().toUtc().millisecondsSinceEpoch;

  /// Converts a stored epoch-ms value to a local [DateTime] for display.
  static DateTime toLocal(int epochMs) =>
      DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true).toLocal();
}
