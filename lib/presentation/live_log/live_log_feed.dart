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
    return ScreenBody(
      child: holdings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('לא ניתן לטעון את המקרר: $error'),
        data: (items) {
          final now = DateTime.now();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                items.isEmpty ? 'המקרר ריק' : '${items.length} במקרר',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'פריטים שנמצאים כרגע במקרר',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'אין כרגע פריטים במקרר.',
                          style: TextStyle(fontSize: 28),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 460,
                              mainAxisExtent: 180,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final holding = items[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    holding.productName,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    holding.fridgeName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'נקלט ב-${formatCelsius(holding.checkInTemperatureCelsius)}',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatInside(holding.checkedInAt, now),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
