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
              SectionTitle(
                items.isEmpty ? 'המקרר ריק' : '${items.length} במקרר',
              ),
              const SizedBox(height: 16),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'אין כרגע פריטים במקרר.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF5C6B70),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 420,
                              mainAxisExtent: 132,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final holding = items[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    holding.productName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'נקלט ב-${formatCelsius(holding.checkInTemperatureCelsius)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF5C6B70),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatInside(holding.checkedInAt, now),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
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
