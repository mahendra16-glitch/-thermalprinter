import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:thermalprinter/data/db/app_database.dart';

/// Fresh in-memory database with the production schema.
AppDatabase openTestDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
