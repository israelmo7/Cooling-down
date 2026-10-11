import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../check_in/check_in_panel.dart';
import '../check_out/check_out_panel.dart';
import '../live_log/live_log_feed.dart';
import '../providers.dart';

class TabletShell extends ConsumerWidget {
  const TabletShell({super.key});

  static const tabletWidth = 1024.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < tabletWidth) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'This station is laid out for a tablet in landscape.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: CheckInPanel()),
                      SizedBox(width: 16),
                      Expanded(child: CheckOutPanel()),
                      SizedBox(width: 16),
                      Expanded(child: LiveLogFeed()),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
