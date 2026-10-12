import '../entities/worker.dart';
import '../workers/worker_session.dart';

/// Workers stay on this tablet. Each log copies the name at the moment of the action.
abstract class WorkerRepository {
  Stream<List<Worker>> watchAll();

  Future<List<Worker>> listWorkers();

  Stream<WorkerSession> watchSession();

  Future<WorkerSession> readSession();

  Future<Worker?> addWorker(String name);

  Future<void> renameWorker(String id, String name);

  Future<void> deleteWorker(String id);

  Future<void> selectWorker(String id, {DateTime? at});

  Future<void> noteActivity(DateTime at);
}
