import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../check_in/check_in_panel.dart';
import '../check_out/check_out_panel.dart';
import '../live_log/live_log_feed.dart';
import '../providers.dart';

class TabletShell extends ConsumerStatefulWidget {
  const TabletShell({super.key});

  @override
  ConsumerState<TabletShell> createState() => _TabletShellState();
}

class _TabletShellState extends ConsumerState<TabletShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final alerts =
        ref.watch(unacknowledgedAlertsProvider).asData?.value ?? const [];
    final pendingCount = ref.watch(pendingSyncCountProvider).asData?.value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooling down'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Center(
              child: Text(
                pendingCount == 0
                    ? 'Saved on this tablet'
                    : 'Saved on this tablet · $pendingCount waiting to sync',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (alerts.isNotEmpty)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        alerts.first.message,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
          NavigationDestination(icon: Icon(Icons.login), label: 'Check in'),
          NavigationDestination(icon: Icon(Icons.logout), label: 'Check out'),
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen),
            label: 'In the fridge',
          ),
        ],
      ),
    );
  }
}
