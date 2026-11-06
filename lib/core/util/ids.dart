import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Stable unique id for any record that may later be synced or merged.
String newId() => _uuid.v4();
