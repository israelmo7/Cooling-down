import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/clock.dart';
import '../../domain/entities/worker.dart';
import '../../domain/repositories/worker_repository.dart';
import '../../domain/workers/worker_session.dart';
import '../db/app_database.dart';
import '../db/ensure_settings.dart';

class DriftWorkerRepository implements WorkerRepository {
  DriftWorkerRepository(this._db, {Clock? clock, Uuid? uuid})
    : _clock = clock ?? const Clock(),
      _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Clock _clock;
  final Uuid _uuid;

  @override
  Stream<List<Worker>> watchAll() {
    final statement = _db.select(_db.workers)
      ..orderBy([(table) => OrderingTerm(expression: table.name)]);
    return statement.watch().map(
      (rows) => [
        for (final row in rows)
          Worker(id: row.id, name: row.name, createdAt: row.createdAt),
      ],
    );
  }

  @override
  Stream<WorkerSession> watchSession() {
    final controller = StreamController<WorkerSession>();
    LocalSettingsRow? settings;
    List<WorkerRow>? workers;

    void emit() {
      final row = settings;
      final catalog = workers;
      if (row == null || catalog == null || controller.isClosed) {
        return;
      }
      controller.add(_session(row, catalog));
    }

    final settingsSub =
        (_db.select(_db.localSettings)
              ..where((table) => table.id.equals(localSettingsId)))
            .watch()
            .listen((rows) {
              settings = rows.isEmpty ? null : rows.single;
              if (settings == null) {
                if (!controller.isClosed) {
                  controller.add(const WorkerSession());
                }
                return;
              }
              emit();
            });
    final workersSub = _db.select(_db.workers).watch().listen((rows) {
      workers = rows;
      emit();
    });
    controller.onCancel = () async {
      await settingsSub.cancel();
      await workersSub.cancel();
    };
    return controller.stream;
  }

  @override
  Future<WorkerSession> readSession() async {
    final row = await ensureLocalSettingsRow(_db);
    final workers = await _db.select(_db.workers).get();
    return _session(row, workers);
  }

  @override
  Future<Worker?> addWorker(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final existing = await _named(trimmed);
    if (existing != null) {
      return Worker(
        id: existing.id,
        name: existing.name,
        createdAt: existing.createdAt,
      );
    }
    final createdAt = _clock.now().toUtc();
    final id = _uuid.v4();
    await _db
        .into(_db.workers)
        .insert(
          WorkersCompanion.insert(id: id, name: trimmed, createdAt: createdAt),
        );
    return Worker(id: id, name: trimmed, createdAt: createdAt);
  }

  @override
  Future<void> renameWorker(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    await (_db.update(_db.workers)..where((table) => table.id.equals(id)))
        .write(WorkersCompanion(name: Value(trimmed)));
  }

  @override
  Future<void> deleteWorker(String id) async {
    await (_db.delete(_db.workers)..where((table) => table.id.equals(id))).go();
    final settings = await ensureLocalSettingsRow(_db);
    if (settings.currentWorkerId != id) {
      return;
    }
    await (_db.update(
      _db.localSettings,
    )..where((table) => table.id.equals(localSettingsId))).write(
      const LocalSettingsCompanion(
        currentWorkerId: Value(null),
        workerActiveAt: Value(null),
      ),
    );
  }

  @override
  Future<void> selectWorker(String id, {DateTime? at}) async {
    final worker = await (_db.select(
      _db.workers,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (worker == null) {
      return;
    }
    await ensureLocalSettingsRow(_db);
    await (_db.update(
      _db.localSettings,
    )..where((table) => table.id.equals(localSettingsId))).write(
      LocalSettingsCompanion(
        currentWorkerId: Value(id),
        workerActiveAt: Value((at ?? _clock.now()).toUtc()),
      ),
    );
  }

  @override
  Future<void> noteActivity(DateTime at) async {
    final settings = await ensureLocalSettingsRow(_db);
    if (settings.currentWorkerId == null) {
      return;
    }
    await (_db.update(_db.localSettings)
          ..where((table) => table.id.equals(localSettingsId)))
        .write(LocalSettingsCompanion(workerActiveAt: Value(at.toUtc())));
  }

  WorkerSession _session(LocalSettingsRow row, List<WorkerRow> workers) {
    WorkerRow? match;
    for (final worker in workers) {
      if (worker.id == row.currentWorkerId) {
        match = worker;
      }
    }
    if (match == null) {
      return const WorkerSession();
    }
    return WorkerSession(
      workerId: match.id,
      workerName: match.name,
      activeAt: row.workerActiveAt,
    );
  }

  Future<WorkerRow?> _named(String name) {
    return (_db.select(
      _db.workers,
    )..where((table) => table.name.equals(name))).getSingleOrNull();
  }
}
