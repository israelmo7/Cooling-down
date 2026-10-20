import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/sync/server_url.dart';
import '../../domain/reports/daily_report.dart';
import '../../domain/settings/device_settings.dart';
import '../../domain/workers/worker_refresh.dart';
import '../../platform/kiosk.dart';
import '../providers.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/station_widgets.dart';
import '../widgets/transient_notice.dart';
import 'product_catalog.dart';
import 'worker_catalog.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _environment = TextEditingController();
  final _serverUrl = TextEditingController();
  final _token = TextEditingController();
  final _idleSeconds = TextEditingController();
  final _refreshStart = TextEditingController();
  final _refreshHours = TextEditingController();
  final _refreshEnd = TextEditingController();
  final _settingsPassword = TextEditingController();
  var _loaded = false;
  var _unlocked = false;
  var _busy = false;
  var _confirmAction = false;
  var _refreshMode = WorkerRefreshMode.idle;
  var _promptStyle = WorkerPromptStyle.wait;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _environment.dispose();
    _serverUrl.dispose();
    _token.dispose();
    _idleSeconds.dispose();
    _refreshStart.dispose();
    _refreshHours.dispose();
    _refreshEnd.dispose();
    _settingsPassword.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await ref.read(settingsRepositoryProvider).ensure();
    if (!mounted) {
      return;
    }
    setState(() {
      _environment.text = clipEnvironmentName(settings.environmentName);
      _serverUrl.text = settings.serverUrl;
      _token.text = settings.serverToken;
      _idleSeconds.text = '${settings.workerIdleSeconds}';
      _refreshStart.text = formatClockMinutes(
        settings.workerRefreshStartMinute,
      );
      _refreshHours.text = '${settings.workerRefreshIntervalHours}';
      _refreshEnd.text = formatClockMinutes(settings.workerRefreshEndMinute);
      _refreshMode = settings.workerRefreshMode;
      _promptStyle = settings.workerPromptStyle;
      _confirmAction = settings.confirmAction;
      _settingsPassword.text = settings.settingsPassword;
      _loaded = true;
    });
  }

  Future<DeviceSettings?> _save() async {
    final current = await ref.read(settingsRepositoryProvider).ensure();
    final idleSeconds = normalizeWorkerIdleSeconds(_idleSeconds.text);
    final intervalHours = normalizeIntervalHours(_refreshHours.text);
    final startMinute = parseClockMinutes(_refreshStart.text) ?? 8 * 60;
    final endMinute = parseClockMinutes(_refreshEnd.text) ?? 20 * 60;
    _idleSeconds.text = '$idleSeconds';
    _refreshHours.text = '$intervalHours';
    _refreshStart.text = formatClockMinutes(startMinute);
    _refreshEnd.text = formatClockMinutes(endMinute);
    final settingsPassword = _settingsPassword.text.trim();
    final next = current.copyWith(
      environmentName: clipEnvironmentName(_environment.text),
      serverUrl: _serverUrl.text,
      serverToken: _token.text.trim(),
      dailyReportEnabled: true,
      reportHour: 0,
      reportMinute: 0,
      confirmAction: _confirmAction,
      workerIdleSeconds: idleSeconds,
      workerRefreshMode: _refreshMode,
      workerPromptStyle: _promptStyle,
      workerRefreshStartMinute: startMinute,
      workerRefreshIntervalHours: intervalHours,
      workerRefreshEndMinute: endMinute,
      settingsPassword: settingsPassword,
    );
    await ref.read(settingsRepositoryProvider).save(next);
    return ref.read(settingsRepositoryProvider).ensure();
  }

  Future<void> _askConfirmAction(bool next) async {
    if (_busy || next == _confirmAction) {
      return;
    }
    final accepted = await confirmRecordedAction(
      context,
      enabled: true,
      action: next ? 'הפעלת אימות פעולה' : 'כיבוי אימות פעולה',
    );
    if (!accepted || !mounted) {
      return;
    }
    setState(() => _confirmAction = next);
    try {
      final current = await ref.read(settingsRepositoryProvider).ensure();
      await ref
          .read(settingsRepositoryProvider)
          .save(current.copyWith(confirmAction: next));
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _confirmAction = !next);
      _show('לא ניתן לשמור את אימות הפעולה.');
    }
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
      _show('סונכרן. נשלחו ${attempt.synced} למחשב.');
    });
  }

  Future<void> _promptUnlock() async {
    final settings = await ref.read(settingsRepositoryProvider).ensure();
    if (!mounted) {
      return;
    }
    final saved = settings.settingsPassword.trim();
    if (saved.isEmpty) {
      setState(() => _unlocked = true);
      return;
    }
    final unlocked = await showDialog<bool>(
      context: context,
      builder: (context) => _PasswordDialog(password: saved),
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

  Future<void> _openAdmin(DeviceSettings? settings) async {
    final base = normalizeServerUrl(settings?.serverUrl ?? '');
    if (base.isEmpty) {
      _show('יש להזין כתובת מחשב תחילה.');
      return;
    }
    final saved = settings?.settingsPassword.trim() ?? '';
    if (saved.isNotEmpty && !_unlocked) {
      final unlocked = await showDialog<bool>(
        context: context,
        builder: (context) =>
            _PasswordDialog(password: saved, title: 'לוח ניהול'),
      );
      if (unlocked != true || !mounted) {
        return;
      }
    }
    await Kiosk.openOutside();
    final opened = await launchUrl(
      Uri.parse('$base/admin'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      await Kiosk.pin();
      _show('לא ניתן לפתוח את לוח הניהול.');
    }
  }

  void _show(String message) {
    showTransientNotice(context, message);
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
      const _SectionRule('settings-section-place'),
      _field(
        controller: _environment,
        label: 'שם הסביבה',
        helper: 'השם שמופיע בראש הטאבלט. עד 20 תווים.',
        inputFormatters: [LengthLimitingTextInputFormatter(20)],
      ),
      const _SectionRule('settings-section-catalog'),
      ProductCatalogEditor(
        key: const ValueKey('product-catalog'),
        unlocked: _canEdit,
      ),
      const SizedBox(height: 8),
      WorkerCatalogEditor(
        key: const ValueKey('worker-catalog'),
        unlocked: _canEdit,
      ),
      const _SectionRule('settings-section-secure'),
      if (_unlocked) ...[
        _workerRefreshControl(),
        _field(
          controller: _serverUrl,
          label: 'כתובת המחשב',
          helper: 'למשל http://192.168.1.20:8080. בלי רשת הנתונים נשארים בטאבלט ומסתנכרנים אחר כך.',
        ),
        _field(
          controller: _token,
          label: 'אסימון גישה',
          helper: 'האסימון נשאר בטאבלט. המחשב נשאר ברשת של החנות.',
        ),
        _field(
          controller: _settingsPassword,
          label: 'סיסמה',
          hint: 'ללא סיסמה',
          obscure: true,
          keyboard: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
        ),
        if (Kiosk.supported) _releaseKioskButton(),
      ] else
        _confirmActionControl(),
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
      const _SectionRule('settings-section-status'),
      Text('סנכרון אחרון: ${_lastSync(settings)}'),
      const SizedBox(height: 8),
      Text('דוח אחרון: ${_lastReport(report)}'),
      const SizedBox(height: 8),
      Text(
        'מזהה: ${_environment.text}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      _computerNote(settings),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('הגדרות')),
      body: _loaded
          ? Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 900;
                      if (!wide) {
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
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
                            SizedBox(
                              width: 280,
                              child: ListView(children: actions),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(
                  key: Key('settings-section-admin'),
                  height: 1,
                  thickness: 1,
                  color: stationLine,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      key: const Key('open-admin'),
                      onPressed: _busy ? null : () => _openAdmin(settings),
                      child: const Text('לוח ניהול'),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String helper = '',
    String hint = '',
    bool obscure = false,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        key: Key('settings-field-$label'),
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        readOnly: !_unlocked,
        enabled: !_busy,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint.isEmpty ? null : hint,
          helperText: helper.isEmpty ? null : helper,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _pickRefreshMode() async {
    final picked = await showDialog<WorkerRefreshMode>(
      context: context,
      builder: (context) => const _WorkerRefreshMenu(),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _refreshMode = picked);
  }

  Widget _workerRefreshControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('worker-refresh'),
            onPressed: _busy ? null : _pickRefreshMode,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 56),
              foregroundColor: const Color(0xFF122428),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text(
              'רענון עובד',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_refreshMode == WorkerRefreshMode.idle)
          _field(
            controller: _idleSeconds,
            label: 'שניות',
            keyboard: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
          ),
        if (_refreshMode == WorkerRefreshMode.periodic) ...[
          _field(
            controller: _refreshStart,
            label: 'משעה',
            helper: '08:00 עד 08:00 הוא יום שלם. השאלה חוזרת בכל מספר השעות, מהשעה הראשונה.',
          ),
          _field(
            controller: _refreshHours,
            label: 'שעות',
            keyboard: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
          ),
          _field(controller: _refreshEnd, label: 'עד'),
        ],
        if (_refreshMode != WorkerRefreshMode.off) ...[
          const SizedBox(height: 4),
          SegmentedButton<WorkerPromptStyle>(
            key: const Key('worker-prompt-style'),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              visualDensity: VisualDensity.compact,
            ),
            segments: const [
              ButtonSegment(
                value: WorkerPromptStyle.popup,
                label: Text('הקפצה'),
              ),
              ButtonSegment(
                value: WorkerPromptStyle.wait,
                label: Text('המתנה'),
              ),
            ],
            selected: {_promptStyle},
            onSelectionChanged: _busy
                ? null
                : (selected) => setState(() => _promptStyle = selected.first),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _confirmActionControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('אימות פעולה', style: Theme.of(context).textTheme.titleLarge),
        Switch(
          key: const Key('confirm-action'),
          value: _confirmAction,
          onChanged: _busy ? null : _askConfirmAction,
        ),
      ],
    );
  }

  bool get _canEdit => _unlocked && !_busy;

  Widget _releaseKioskButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          key: const Key('release-kiosk'),
          onPressed: _busy ? null : () => Kiosk.unpin(),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 56),
            foregroundColor: const Color(0xFF122428),
          ),
          child: const Text('שחרור המסך'),
        ),
      ),
    );
  }

  Widget _computerNote(DeviceSettings? settings) {
    if (settings == null) {
      return const SizedBox.shrink();
    }
    final missing =
        settings.serverUrl.trim().isEmpty ||
        settings.serverToken.trim().isEmpty;
    if (missing) {
      return Text(
        'חסרים פרטי המחשב.',
        key: const Key('computer-details-missing'),
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final failed = settings.lastSyncError?.trim().isNotEmpty ?? false;
    if (!failed) {
      return const SizedBox.shrink();
    }
    return const Text(
      'אין חיבור למחשב',
      key: Key('computer-unreachable'),
      style: TextStyle(color: Color(0xFFB91C1C), fontSize: 14),
    );
  }

  String _lastSync(DeviceSettings? settings) {
    if (settings == null || settings.lastSyncAt == null) {
      return 'עדיין לא סונכרן';
    }
    return formatReportClock(settings.lastSyncAt!);
  }

  String _lastReport(StoredDailyReport? report) {
    if (report == null) {
      return 'עדיין אין';
    }
    return '${report.reportDate} · ${_reportStatus(report.status)}';
  }
}

class _SectionRule extends StatelessWidget {
  const _SectionRule(this.ruleKey);

  final String ruleKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Divider(
        key: Key(ruleKey),
        height: 1,
        thickness: 1,
        color: stationLine,
      ),
    );
  }
}

class _WorkerRefreshMenu extends StatelessWidget {
  const _WorkerRefreshMenu();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('worker-refresh-menu'),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: SizedBox(
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in WorkerRefreshMode.values)
              ListTile(
                title: Text(
                  _refreshModeLabel(mode),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onTap: () => Navigator.of(context).pop(mode),
              ),
          ],
        ),
      ),
    );
  }
}

String _refreshModeLabel(WorkerRefreshMode mode) {
  switch (mode) {
    case WorkerRefreshMode.off:
      return 'ללא';
    case WorkerRefreshMode.idle:
      return 'לא בשימוש';
    case WorkerRefreshMode.periodic:
      return 'מחזוריות';
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.password, this.title = 'שינוי הגדרות'});

  final String password;
  final String title;

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
    if (_controller.text.trim() == widget.password) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _wrong = true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
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
