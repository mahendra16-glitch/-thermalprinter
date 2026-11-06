/// "Just now", "12 min", "1 h 05 min".
String elapsedLabel(DateTime since, DateTime now) {
  final m = now.difference(since).inMinutes;
  if (m < 1) return 'Just now';
  if (m < 60) return '$m min';
  final h = m ~/ 60;
  return '$h h ${(m % 60).toString().padLeft(2, '0')} min';
}
