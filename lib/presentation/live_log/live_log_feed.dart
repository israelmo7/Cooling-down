import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../format.dart';
import '../providers.dart';
import '../widgets/station_widgets.dart';

class LiveLogFeed extends ConsumerWidget {
  const LiveLogFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(openHoldingsProvider);
    return StationPanel(
      title: 'In the fridge',
      child: holdings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('Could not load the fridge feed: $error'),
        data: (items) {
          if (items.isEmpty) {
            return const Text('Nothing is in a fridge right now.');
          }
          final now = DateTime.now();
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final holding = items[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                title: Text(
                  holding.productName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${holding.fridgeName}\nIn at ${formatCelsius(holding.checkInTemperatureCelsius)} · ${formatInside(holding.checkedInAt, now)}',
                ),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
