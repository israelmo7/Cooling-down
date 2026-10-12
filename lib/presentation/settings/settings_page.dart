import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/reports/daily_report.dart';
import '../../domain/settings/device_settings.dart';
import '../providers.dart';
import 'product_catalog.dart';

const settingsEditPassword = '123459876';

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
  var _unlocked = false;
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
      _loaded = true;
    });
  }

  Future<DeviceSettings?> _save() async {
    final current = await ref.read(settingsRepositoryProvider).ensure();
    final email = _email.text.trim();
    if (email.isNotEmpty && !email.contains('@')) {
      _show('יש להזין כתובת אימייל מלאה.');
      return null;
    }
    final next = current.copyWith(
      deviceName: _deviceName.text,
      environmentName: _environment.text,
      serverUrl: _serverUrl.text,
      serverToken: _token.text.trim(),
      ownerEmail: email,
      dailyReportEnabled: true,
      reportHour: 0,
      reportMinute: 0,
      hubEnabled: false,
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
        _show('נשמר בטאבלט. יש להזין כתובת מחשב כדי לשתף.');
        return;
      }
      if (attempt.stoppedBecause != null) {
        _show(attempt.stoppedBecause!);
        return;
      }
      _show(
        'סונכרן. נשלחו ${attempt.synced} מהטאבלט ונקלטו ${attempt.pulled}.',
      );
    });
  }

  Future<void> _promptUnlock() async {
    final unlocked = await showDialog<bool>(
      context: context,
      builder: (context) => const _PasswordDialog(),
    );
    if (unlocked == true && mounted) {
      setState(() => _unlocked = true);
    }
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

    final fields = <Widget>[
      Text(
        'הטאבלט שומר כל קליטה והוצאה גם כשאין רשת. כשהמחשב בחנות זמין, הנתונים עולים אליו. בחצות המחשב שולח לבעלים דוח על היום שהסתיים.',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 24),
      _field(
        controller: _environment,
        label: 'שם הסביבה',
        helper: 'אותו שם בכל טאבלט שצריך לשתף את אותו מטבח או בית מרקחת.',
      ),
      _field(
        controller: _deviceName,
        label: 'שם המכשיר',
        helper: 'כדי להבדיל בין הטאבלטים.',
      ),
      _field(
        controller: _serverUrl,
        label: 'כתובת המחשב',
        helper:
            'למשל http://192.168.1.20:8080. בלי רשת הנתונים נשארים בטאבלט ומסתנכרנים אחר כך.',
      ),
      if (_unlocked)
        _field(
          controller: _token,
          label: 'אסימון גישה',
          helper: 'האסימון נשאר בטאבלט. המחשב נשאר ברשת של החנות.',
        ),
      _field(
        controller: _email,
        label: 'אימייל הבעלים',
        helper: 'הדוח היומי נשלח לכאן מהמחשב בחצות.',
        keyboard: TextInputType.emailAddress,
      ),
      const SizedBox(height: 8),
      ProductCatalogEditor(unlocked: _canEdit),
    ];
    final actions = <Widget>[
      if (!_unlocked)
        OutlinedButton(
          key: const Key('unlock-settings'),
          onPressed: _busy ? null : _promptUnlock,
          child: const Text('שינוי הגדרות'),
        ),
      if (_unlocked)
        FilledButton(
          onPressed: _busy
              ? null
              : () => _run(() async {
                  final saved = await _save();
                  if (saved != null && mounted) {
                    setState(() => _unlocked = false);
                    _show('ההגדרות נשמרו.');
                  }
                }),
          child: const Text('שמירה'),
        ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _busy ? null : _syncNow,
        child: const Text('סנכרון עכשיו'),
      ),
      const SizedBox(height: 28),
      Text('סנכרון אחרון: ${_lastSync(settings)}'),
      const SizedBox(height: 8),
      Text('דוח אחרון: ${_lastReport(report)}'),
      const SizedBox(height: 8),
      Text(
        'מזהה מכשיר: ${settings?.deviceId ?? ''}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('הגדרות')),
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
        key: Key('settings-field-$label'),
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        readOnly: !_unlocked,
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

  bool get _canEdit => _unlocked && !_busy;

  String _lastSync(DeviceSettings? settings) {
    if (settings == null || settings.lastSyncAt == null) {
      return settings?.lastSyncError ?? 'עדיין לא סונכרן';
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
      return 'עדיין אין';
    }
    return '${report.reportDate} · ${_reportStatus(report.status)}';
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();
  var _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final entered = _controller.text.replaceAll(RegExp(r'\D'), '');
    if (entered == settingsEditPassword) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _wrong = true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('שינוי הגדרות'),
      content: TextField(
        key: const Key('settings-password'),
        controller: _controller,
        obscureText: true,
        autofocus: true,
        keyboardType: TextInputType.visiblePassword,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'סיסמה',
          errorText: _wrong ? 'הסיסמה שגויה.' : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ביטול'),
        ),
        FilledButton(
          key: const Key('confirm-settings-password'),
          onPressed: _submit,
          child: const Text('אישור'),
        ),
      ],
    );
  }
}

String _reportStatus(String status) {
  switch (status) {
    case ReportStatus.sent:
      return 'נשלח';
    case ReportStatus.alreadySent:
      return 'כבר נשלח';
    case ReportStatus.stored:
      return 'נשמר במחשב';
    case ReportStatus.waiting:
      return 'ממתין לשליחה';
    case ReportStatus.failed:
      return 'השליחה נכשלה';
    default:
      return status;
  }
}
