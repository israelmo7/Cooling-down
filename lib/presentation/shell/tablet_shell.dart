import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/alert.dart';
import '../../domain/settings/device_settings.dart';
import '../check_in/check_in_panel.dart';
import '../check_out/check_out_panel.dart';
import '../live_log/live_log_feed.dart';
import '../providers.dart';
import '../settings/settings_page.dart';

class TabletShell extends ConsumerStatefulWidget {
  const TabletShell({super.key});

  @override
  ConsumerState<TabletShell> createState() => _TabletShellState();
}

class _TabletShellState extends ConsumerState<TabletShell>
    with WidgetsBindingObserver {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final current = ref.read(settingsProvider).asData?.value;
      if (current?.hubEnabled == true) {
        ref.read(tabletHubProvider).apply(current, restart: true);
      }
      _tick();
    }
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
    final hub = settings?.hubEnabled ?? false;
    final environment = settings?.environmentName.trim() ?? '';
    ref.watch(tabletHubProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          environment.isEmpty ? 'קירור' : clipEnvironmentName(environment),
        ),
        actions: [
          Center(
            child: Text(
              _syncLabel(
                pendingCount: pendingCount,
                sharing: sharing,
                hub: hub,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          if (alerts.isNotEmpty) _DismissingAlert(alert: alerts.first),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [CheckInPanel(), CheckOutPanel(), LiveLogFeed()],
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
    );
  }

  String _syncLabel({
    required int pendingCount,
    required bool sharing,
    required bool hub,
  }) {
    if (hub) {
      return 'משתף ברשת המקומית';
    }
    if (!sharing) {
      return pendingCount == 0
          ? 'נשמר בטאבלט'
          : 'נשמר בטאבלט · $pendingCount ממתינים לסנכרון';
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
