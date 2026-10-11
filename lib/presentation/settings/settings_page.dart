import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/reports/daily_report.dart';
import '../../domain/settings/device_settings.dart';
import '../providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _environment = TextEditingController();
  final _deviceName = TextEditingController();
  final _serverUrl = TextEditingController();
  final _token = TextEditingController();
  final _email = TextEditingController();
  var _loaded = false;
  var _reportEnabled = false;
  var _hour = 21;
  var _minute = 0;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _environment.dispose();
    _deviceName.dispose();
    _serverUrl.dispose();
    _token.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await ref.read(settingsRepositoryProvider).ensure();
    if (!mounted) {
      return;
    }
    setState(() {
      _environment.text = settings.environmentName;
      _deviceName.text = settings.deviceName;
      _serverUrl.text = settings.serverUrl;
      _token.text = settings.serverToken;
      _email.text = settings.ownerEmail;
      _reportEnabled = settings.dailyReportEnabled;
      _hour = settings.reportHour;
      _minute = settings.reportMinute;
      _loaded = true;
    });
  }

  Future<DeviceSettings?> _save() async {
    final current = await ref.read(settingsRepositoryProvider).ensure();
    final email = _email.text.trim();
    if (email.isNotEmpty && !email.contains('@')) {
      _show('Enter a full email address.');
      return null;
    }
    final next = current.copyWith(
      deviceName: _deviceName.text,
      environmentName: _environment.text,
      serverUrl: _serverUrl.text,
      serverToken: _token.text,
      ownerEmail: email,
      dailyReportEnabled: _reportEnabled,
      reportHour: _hour,
      reportMinute: _minute,
    );
    await ref.read(settingsRepositoryProvider).save(next);
    return ref.read(settingsRepositoryProvider).ensure();
  }

  Future<void> _syncNow() async {
    await _run(() async {
      final saved = await _save();
      if (saved == null) {
        return;
      }
      final attempt = await ref.read(syncRepositoryProvider).trySync();
      if (!mounted) {
        return;
      }
      if (!saved.hasServer) {
        _show('Saved on this tablet. Add a server address to share it.');
        return;
      }
      if (attempt.stoppedBecause != null) {
        _show(attempt.stoppedBecause!);
        return;
      }
      _show(
        'Synced. Sent ${attempt.synced} from this tablet and received ${attempt.pulled}.',
      );
    });
  }

  Future<void> _sendReport() async {
    await _run(() async {
      final saved = await _save();
      if (saved == null) {
        return;
      }
      final message = await ref
          .read(dailyReportServiceProvider)
          .deliverToday(manual: true);
      if (!mounted || message.isEmpty) {
        return;
      }
      _show(message);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error) {
      if (mounted) {
        _show(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).asData?.value;
    final report = ref.watch(latestReportProvider).asData?.value;
    final minutes = {0, 15, 30, 45, _minute}.toList()..sort();

    final fields = <Widget>[
      Text(
        'This tablet keeps every check-in and check-out. A server is optional and lets other tablets share the same kitchen or pharmacy.',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 24),
      _field(
        controller: _environment,
        label: 'Environment name',
        helper:
            'Use the same name on every tablet that should share one record.',
      ),
      _field(
        controller: _deviceName,
        label: 'Device name',
        helper: 'Shown so you can tell the tablets apart.',
      ),
      _field(
        controller: _serverUrl,
        label: 'Server address',
        helper: 'Leave empty to stay on this tablet only.',
      ),
      _field(
        controller: _token,
        label: 'Access token',
        helper: 'The token stays on this tablet. Keep the server on your own network.',
        obscure: true,
      ),
      _field(
        controller: _email,
        label: 'Owner email',
        helper: 'The end-of-day report is sent here when a server is set.',
        keyboard: TextInputType.emailAddress,
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Email a report at the end of each day'),
        value: _reportEnabled,
        onChanged: _busy
            ? null
            : (value) => setState(() => _reportEnabled = value),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _hour,
              decoration: const InputDecoration(labelText: 'Report hour'),
              items: [
                for (var hour = 0; hour < 24; hour++)
                  DropdownMenuItem(
                    value: hour,
                    child: Text(hour.toString().padLeft(2, '0')),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _hour = value ?? _hour),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _minute,
              decoration: const InputDecoration(labelText: 'Report minute'),
              items: [
                for (final minute in minutes)
                  DropdownMenuItem(
                    value: minute,
                    child: Text(minute.toString().padLeft(2, '0')),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _minute = value ?? _minute),
            ),
          ),
        ],
      ),
    ];
    final actions = <Widget>[
      FilledButton(
        onPressed: _busy
            ? null
            : () => _run(() async {
                final saved = await _save();
                if (saved != null && mounted) {
                  _show('Settings saved.');
                }
              }),
        child: const Text('Save'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _busy ? null : _syncNow,
        child: const Text('Sync now'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _busy ? null : _sendReport,
        child: const Text("Send today's report"),
      ),
      const SizedBox(height: 28),
      Text('Last sync: ${_lastSync(settings)}'),
      const SizedBox(height: 8),
      Text('Last report: ${_lastReport(report)}'),
      const SizedBox(height: 8),
      Text(
        'Device id: ${settings?.deviceId ?? ''}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loaded
          ? LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                if (!wide) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    children: [
                      ...fields,
                      const SizedBox(height: 24),
                      ...actions,
                    ],
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: ListView(children: fields)),
                      const SizedBox(width: 32),
                      SizedBox(width: 280, child: ListView(children: actions)),
                    ],
                  ),
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String helper,
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        enabled: !_busy,
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  String _lastSync(DeviceSettings? settings) {
    if (settings == null || settings.lastSyncAt == null) {
      return settings?.lastSyncError ?? 'Not synced yet';
    }
    final clock = formatReportClock(settings.lastSyncAt!);
    final error = settings.lastSyncError;
    if (error != null && error.isNotEmpty) {
      return '$clock · $error';
    }
    return clock;
  }

  String _lastReport(StoredDailyReport? report) {
    if (report == null) {
      return 'None yet';
    }
    return '${report.reportDate} · ${report.status}';
  }
}
