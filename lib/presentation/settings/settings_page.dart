import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/sync/tablet_hub.dart';
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
  final _smtpHost = TextEditingController();
  final _smtpPort = TextEditingController(text: '587');
  final _smtpUser = TextEditingController();
  final _smtpPassword = TextEditingController();
  final _smtpFrom = TextEditingController();
  var _loaded = false;
  var _reportEnabled = true;
  var _hubEnabled = false;
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
    _smtpHost.dispose();
    _smtpPort.dispose();
    _smtpUser.dispose();
    _smtpPassword.dispose();
    _smtpFrom.dispose();
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
      _smtpHost.text = settings.smtpHost;
      _smtpPort.text = settings.smtpPort.toString();
      _smtpUser.text = settings.smtpUser;
      _smtpPassword.text = settings.smtpPassword;
      _smtpFrom.text = settings.smtpFrom;
      _reportEnabled = settings.dailyReportEnabled;
      _hubEnabled = settings.hubEnabled;
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
    var token = _token.text.trim();
    if (_hubEnabled && token.isEmpty) {
      token = const Uuid().v4();
      _token.text = token;
    }
    final port = int.tryParse(_smtpPort.text.trim()) ?? 587;
    final next = current.copyWith(
      deviceName: _deviceName.text,
      environmentName: _environment.text,
      serverUrl: _hubEnabled ? '' : _serverUrl.text,
      serverToken: token,
      ownerEmail: email,
      dailyReportEnabled: _reportEnabled,
      reportHour: 0,
      reportMinute: 0,
      hubEnabled: _hubEnabled,
      smtpHost: _smtpHost.text,
      smtpPort: port,
      smtpUser: _smtpUser.text,
      smtpPassword: _smtpPassword.text,
      smtpFrom: _smtpFrom.text,
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
      _field(
        controller: _token,
        label: 'אסימון גישה',
        helper: 'האסימון נשאר בטאבלט. המחשב נשאר ברשת של החנות.',
        obscure: true,
      ),
      _field(
        controller: _email,
        label: 'אימייל הבעלים',
        helper: 'הדוח היומי נשלח לכאן מהמחשב בחצות.',
        keyboard: TextInputType.emailAddress,
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('שליחת דוח בחצות'),
        subtitle: const Text('ב-00:00 נשלח דוח על היום שהסתיים.'),
        value: _reportEnabled,
        onChanged: _busy
            ? null
            : (value) => setState(() => _reportEnabled = value),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('הטאבלט הזה הוא העותק המשותף'),
        subtitle: const Text(
          'השאירו את האפליקציה פתוחה. טאבלטים אחרים משתמשים בכתובת שמופיעה כאן ובאסימון למעלה.',
        ),
        value: _hubEnabled,
        onChanged: _busy
            ? null
            : (value) => setState(() => _hubEnabled = value),
      ),
      if (_hubEnabled)
        ..._hubFields(ref.watch(hubStatusProvider).asData?.value),
    ];
    final actions = <Widget>[
      FilledButton(
        onPressed: _busy
            ? null
            : () => _run(() async {
                final saved = await _save();
                if (saved != null && mounted) {
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
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _busy ? null : _sendReport,
        child: const Text('שליחת הדוח היומי'),
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

  List<Widget> _hubFields(HubStatus? status) {
    final address = status?.listening == true ? status!.address : status?.error;
    return [
      const SizedBox(height: 8),
      Text(
        address == null
            ? 'שמרו כדי להתחיל שיתוף ברשת.'
            : 'טאבלטים אחרים משתמשים ב-$address',
      ),
      const SizedBox(height: 16),
      _field(
        controller: _smtpHost,
        label: 'שרת דואר',
        helper: 'רק אם הטאבלט הזה שולח את המייל בעצמו.',
      ),
      _field(controller: _smtpPort, label: 'יציאת דואר', helper: 'בדרך כלל 587.'),
      _field(controller: _smtpUser, label: 'שם משתמש לדואר', helper: ''),
      _field(
        controller: _smtpPassword,
        label: 'סיסמת דואר',
        helper: 'נשארת בטאבלט.',
        obscure: true,
      ),
      _field(
        controller: _smtpFrom,
        label: 'כתובת השולח',
        helper: 'הכתובת שהבעלים רואה כשולח.',
        keyboard: TextInputType.emailAddress,
      ),
    ];
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
