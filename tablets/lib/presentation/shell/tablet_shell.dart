import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/alert.dart';
import '../../domain/entities/open_holding.dart';
import '../../domain/settings/device_settings.dart';
import '../../domain/workers/worker_refresh.dart';
import '../check_in/check_in_panel.dart';
import '../check_out/check_out_panel.dart';
import '../live_log/live_log_feed.dart';
import '../providers.dart';
import '../widgets/transient_notice.dart';
import '../settings/settings_page.dart';
import '../workers/worker_picker.dart';

class TabletShell extends ConsumerStatefulWidget {
  const TabletShell({super.key});

  @override
  ConsumerState<TabletShell> createState() => _TabletShellState();
}

class _TabletShellState extends ConsumerState<TabletShell>
    with WidgetsBindingObserver {
  int _index = 0;
  Timer? _timer;
  Timer? _idleTimer;
  Timer? _popupRetry;
  Timer? _dueTimer;
  final _toldDue = <String>{};
  DateTime? _lastTouch;
  DateTime? _lastPersisted;
  var _askingWorker = false;
  var _popupScheduled = false;
  String? _shownPromptKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tick();
      _armWorkerRefresh();
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _idleTimer?.cancel();
    _popupRetry?.cancel();
    _dueTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick();
      _armWorkerRefresh();
      setState(() {});
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final refresh = _refresh();
      if (refresh.mode != WorkerRefreshMode.idle) {
        return;
      }
      final at = _lastTouch;
      if (at != null) {
        unawaited(ref.read(workerRepositoryProvider).noteActivity(at));
      }
    }
  }

  WorkerRefresh _refresh() {
    return ref.read(settingsProvider).asData?.value?.workerRefresh ??
        const WorkerRefresh();
  }

  Duration _activityGap(Duration idle) {
    final third = Duration(microseconds: idle.inMicroseconds ~/ 3);
    if (third < const Duration(seconds: 1)) {
      return const Duration(seconds: 1);
    }
    if (third > const Duration(seconds: 30)) {
      return const Duration(seconds: 30);
    }
    return third;
  }

  void _noteActivity() {
    final refresh = _refresh();
    if (refresh.mode != WorkerRefreshMode.idle) {
      return;
    }
    final session = ref.read(workerSessionProvider).asData?.value;
    if (session == null ||
        !session.isActive(DateTime.now(), idle: refresh.idle)) {
      return;
    }
    final now = DateTime.now().toUtc();
    _lastTouch = now;
    final previous = _lastPersisted;
    if (previous != null &&
        now.difference(previous) < _activityGap(refresh.idle)) {
      return;
    }
    _lastPersisted = now;
    unawaited(ref.read(workerRepositoryProvider).noteActivity(now));
    _armWorkerRefresh();
  }

  void _armWorkerRefresh() {
    _idleTimer?.cancel();
    if (!mounted) {
      return;
    }
    final session = ref.read(workerSessionProvider).asData?.value;
    final next = _refresh().nextChange(DateTime.now(), session);
    if (next != null) {
      final delay = next.difference(DateTime.now());
      _idleTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
        if (!mounted) {
          return;
        }
        setState(() {});
        _armWorkerRefresh();
      });
    }
    _schedulePopup();
  }

  void _schedulePopup() {
    if (_popupScheduled) {
      return;
    }
    _popupScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _popupScheduled = false;
      if (mounted) {
        _maybePopup();
      }
    });
  }

  void _maybePopup() {
    _popupRetry?.cancel();
    if (!mounted || _askingWorker) {
      return;
    }
    final workers = ref.read(workersProvider).asData?.value;
    final session = ref.read(workerSessionProvider).asData?.value;
    final refresh = _refresh();
    final now = DateTime.now();
    if (workers == null ||
        workers.isEmpty ||
        !refresh.promptsImmediately(now, session)) {
      return;
    }
    if (ModalRoute.of(context)?.isCurrent != true) {
      _popupRetry = Timer(const Duration(milliseconds: 400), _maybePopup);
      return;
    }
    final key = refresh.promptKey(now, session);
    if (key == null || _shownPromptKey == key) {
      return;
    }
    _shownPromptKey = key;
    unawaited(_askForWorker(required: true));
  }

  Future<void> _askForWorker({required bool required}) async {
    if (!mounted || _askingWorker) {
      return;
    }
    final repository = ref.read(workerRepositoryProvider);
    final workers = await repository.listWorkers();
    if (!mounted) {
      return;
    }
    _askingWorker = true;
    String? picked;
    if (workers.isEmpty) {
      final typed = await askWorkerName(context);
      final name = typed?.trim() ?? '';
      if (name.isNotEmpty) {
        final created = await repository.addWorker(name);
        picked = created?.id;
      }
    } else {
      picked = await pickWorker(context, workers: workers, required: required);
    }
    _askingWorker = false;
    if (!mounted || picked == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    _lastTouch = now;
    _lastPersisted = now;
    _shownPromptKey = null;
    await repository.selectWorker(picked, at: now);
    _armWorkerRefresh();
  }

  void _announceDue(List<OpenHolding> items) {
    final now = DateTime.now();
    final ready = <String>[];
    DateTime? nextMark;
    for (final item in items) {
      final due = item.dueAt?.toLocal();
      if (due == null) {
        continue;
      }
      if (!due.isAfter(now)) {
        if (_toldDue.add(item.movementId)) {
          ready.add(item.productName);
        }
        continue;
      }
      final soon = due.subtract(const Duration(hours: 1));
      for (final mark in [soon, due]) {
        if (mark.isAfter(now) &&
            (nextMark == null || mark.isBefore(nextMark))) {
          nextMark = mark;
        }
      }
    }
    if (ready.isNotEmpty && mounted) {
      showTransientNotice(context, 'זמן יציאה: ${ready.join(', ')}');
    }
    _dueTimer?.cancel();
    final mark = nextMark;
    if (mark == null) {
      return;
    }
    _dueTimer = Timer(mark.difference(now) + const Duration(seconds: 1), () {
      if (!mounted) {
        return;
      }
      setState(() {});
      final current = ref.read(openHoldingsProvider).asData?.value;
      if (current != null) {
        _announceDue(current);
      }
    });
  }

  Future<void> _tick() async {
    if (!mounted) {
      return;
    }
    try {
      await ref.read(settingsRepositoryProvider).ensure();
      await ref.read(tabletMaintenanceProvider).run();
    } on Object {
      // Sync and report errors stay on the settings row.
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts =
        ref.watch(unacknowledgedAlertsProvider).asData?.value ?? const [];
    final pendingCount = ref.watch(pendingSyncCountProvider).asData?.value ?? 0;
    final settings = ref.watch(settingsProvider).asData?.value;
    final sharing = settings?.hasServer ?? false;
    final offline =
        !sharing || (settings?.lastSyncError?.trim().isNotEmpty ?? false);
    final environment = settings?.environmentName.trim() ?? '';
    final session = ref.watch(workerSessionProvider).asData?.value;
    final workers = ref.watch(workersProvider).asData?.value;
    ref.listen(workersProvider, (_, _) => _armWorkerRefresh());
    ref.listen(workerSessionProvider, (_, _) => _armWorkerRefresh());
    ref.listen(settingsProvider, (_, _) => _armWorkerRefresh());
    ref.listen(openHoldingsProvider, (_, next) {
      next.whenData(_announceDue);
    });
    final signedIn = session?.workerName.trim().isNotEmpty ?? false;
    final workerLabel = signedIn ? session!.workerName : 'לא עובד';
    final refresh = settings?.workerRefresh ?? const WorkerRefresh();
    final askOnNextTap =
        workers != null &&
        workers.isNotEmpty &&
        refresh.promptsOnTap(DateTime.now(), session);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _noteActivity(),
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              centerTitle: true,
              toolbarHeight: 72,
              leadingWidth: signedIn ? 112 : 156,
              leading: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: const Key('current-worker'),
                  onPressed: () => _askForWorker(required: false),
                  style: TextButton.styleFrom(
                    foregroundColor: signedIn
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : const Color(0xFF9A3412),
                    backgroundColor: signedIn ? null : const Color(0xFFFFEDD5),
                    padding: EdgeInsets.symmetric(
                      horizontal: signedIn ? 8 : 10,
                      vertical: signedIn ? 0 : 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: TextStyle(
                      fontSize: signedIn ? 14 : 18,
                      fontWeight: signedIn ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    workerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: signedIn ? 14 : 18,
                      fontWeight: signedIn ? FontWeight.w400 : FontWeight.w600,
                      color: signedIn
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : const Color(0xFF9A3412),
                    ),
                  ),
                ),
              ),
              titleTextStyle: const TextStyle(
                color: Color(0xFF122428),
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
              title: Text(
                environment.isEmpty
                    ? 'קירור'
                    : clipEnvironmentName(environment),
              ),
              actions: [
                Center(
                  child: Text(
                    key: const Key('sync-status'),
                    _syncLabel(
                      pendingCount: pendingCount,
                      sharing: sharing,
                      offline: offline,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: offline
                          ? const Color(0xFFB91C1C)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('open-settings'),
                  tooltip: 'הגדרות',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                ),
                const SizedBox(width: 12),
              ],
            ),
            body: Column(
              children: [
                if (settings?.isReceivingSupplier ?? false)
                  const Material(
                    color: Color(0xFFFEF3C7),
                    child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text(
                          key: Key('receiving-banner'),
                          'מצב אספקה',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (alerts.isNotEmpty) _DismissingAlert(alert: alerts.first),
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: const [
                      CheckInPanel(),
                      CheckOutPanel(),
                      LiveLogFeed(),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.login), label: 'קליטה'),
                NavigationDestination(icon: Icon(Icons.logout), label: 'הוצאה'),
                NavigationDestination(
                  icon: Icon(Icons.kitchen_outlined),
                  selectedIcon: Icon(Icons.kitchen),
                  label: 'במקרר',
                ),
              ],
            ),
          ),
          if (askOnNextTap)
            Positioned.fill(
              child: GestureDetector(
                key: const Key('worker-idle-gate'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _askForWorker(required: true),
              ),
            ),
        ],
      ),
    );
  }

  String _syncLabel({
    required int pendingCount,
    required bool sharing,
    required bool offline,
  }) {
    if (offline || !sharing) {
      return 'לא מסונכרן';
    }
    return pendingCount == 0 ? 'מסונכרן' : '$pendingCount ממתינים לסנכרון';
  }
}

class _DismissingAlert extends ConsumerStatefulWidget {
  const _DismissingAlert({required this.alert});

  final Alert alert;

  @override
  ConsumerState<_DismissingAlert> createState() => _DismissingAlertState();
}

class _DismissingAlertState extends ConsumerState<_DismissingAlert> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(covariant _DismissingAlert oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alert.id != widget.alert.id) {
      _arm();
    }
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), _dismiss);
  }

  Future<void> _dismiss() async {
    await ref.read(alertRepositoryProvider).acknowledge(widget.alert.id);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onErrorContainer;
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.alert.message,
                style: TextStyle(color: color, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
