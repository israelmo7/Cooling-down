import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

const localSettingsId = 'local';

/// Creates the single settings row the first time this tablet is opened.
Future<LocalSettingsRow> ensureLocalSettingsRow(
  AppDatabase db, {
  Uuid? uuid,
}) async {
  final existing = await _read(db);
  if (existing != null) {
    return existing;
  }
  await db
      .into(db.localSettings)
      .insert(
        LocalSettingsCompanion.insert(
          id: localSettingsId,
          deviceId: (uuid ?? const Uuid()).v4(),
          deviceName: 'הטאבלט הזה',
          environmentName: 'מטבח',
        ),
        mode: InsertMode.insertOrIgnore,
      );
  return (await _read(db))!;
}

Future<String> ensureDeviceId(AppDatabase db) async {
  return (await ensureLocalSettingsRow(db)).deviceId;
}

Future<LocalSettingsRow?> _read(AppDatabase db) {
  return (db.select(
    db.localSettings,
  )..where((table) => table.id.equals(localSettingsId))).getSingleOrNull();
}
