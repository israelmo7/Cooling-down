import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../reports/daily_report_service.dart';

/// Pulls other tablets, then sends the end-of-day report when it is due.
class TabletMaintenance {
  TabletMaintenance({this.settings, this.sync, this.reports});

  factory TabletMaintenance.idle() => TabletMaintenance();

  final SettingsRepository? settings;
  final SyncRepository? sync;
  final DailyReportService? reports;

  Future<void> run() async {
    final settingsRepository = settings;
    final syncRepository = sync;
    final reportService = reports;
    if (settingsRepository == null ||
        syncRepository == null ||
        reportService == null) {
      return;
    }
    final current = await settingsRepository.ensure();
    if (!current.hubEnabled && current.hasServer) {
      await syncRepository.trySync();
    }
    await reportService.deliverToday(manual: false);
  }
}
