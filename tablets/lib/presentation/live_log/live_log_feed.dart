import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/open_holding.dart';
import '../format.dart';
import '../hold_tone.dart';
import '../providers.dart';
import '../widgets/station_widgets.dart';

/// "במקרר": one card per product. Tapping a card opens the list of the
/// individual check-ins of that product underneath it.
class LiveLogFeed extends ConsumerStatefulWidget {
  const LiveLogFeed({super.key});

  @override
  ConsumerState<LiveLogFeed> createState() => _LiveLogFeedState();
}

class _LiveLogFeedState extends ConsumerState<LiveLogFeed> {
  final _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final holdings = ref.watch(openHoldingsProvider);
    return ScreenBody(
      child: holdings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('לא ניתן לטעון את המקרר: $error'),
        data: (items) {
          final now = DateTime.now();
          final groups = _groupByProduct(items);
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
                    : ListView.separated(
                        itemCount: groups.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          final expanded = _expanded.contains(group.key);
                          return _ProductGroupCard(
                            key: Key('fridge-group-${group.key}'),
                            group: group,
                            expanded: expanded,
                            now: now,
                            onTap: () => setState(() {
                              if (expanded) {
                                _expanded.remove(group.key);
                              } else {
                                _expanded.add(group.key);
                              }
                            }),
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

class _ProductGroup {
  const _ProductGroup({required this.key, required this.items});

  final String key;
  final List<OpenHolding> items;

  String get productName => items.first.productName;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}

List<_ProductGroup> _groupByProduct(List<OpenHolding> items) {
  final byProduct = <String, List<OpenHolding>>{};
  for (final item in items) {
    byProduct.putIfAbsent(item.productId, () => []).add(item);
  }
  return [
    for (final entry in byProduct.entries)
      _ProductGroup(key: entry.key, items: entry.value),
  ];
}

class _ProductGroupCard extends StatelessWidget {
  const _ProductGroupCard({
    super.key,
    required this.group,
    required this.expanded,
    required this.now,
    required this.onTap,
  });

  final _ProductGroup group;
  final bool expanded;
  final DateTime now;
  final VoidCallback onTap;

  Color? get _nameColor {
    Color? color;
    for (final item in group.items) {
      final itemColor = holdNameColor(item.dueAt, now, markSoon: false);
      if (itemColor == holdOverdue) {
        return holdOverdue;
      }
      color ??= itemColor;
    }
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final count = group.items.length;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.productName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _nameColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          count == 1
                              ? 'פריט אחד · כמות ${group.totalQuantity}'
                              : '$count פריטים · כמות כוללת ${group.totalQuantity}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF5C6B70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1),
                  for (final holding in group.items)
                    _HoldingRow(holding: holding, now: now),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({required this.holding, required this.now});

  final OpenHolding holding;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final nameColor = holdNameColor(holding.dueAt, now, markSoon: false);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'נקלט ${formatClock(holding.checkedInAt)} · ${formatInside(holding.checkedInAt, now)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: nameColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'נקלט ב-${formatCelsius(holding.checkInTemperatureCelsius)} · כמות ${holding.quantity}',
            style: const TextStyle(fontSize: 15, color: Color(0xFF5C6B70)),
          ),
          if (holding.dueAt != null)
            Text(
              'יציאה ${formatClock(holding.dueAt!)}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF5C6B70)),
            ),
        ],
      ),
    );
  }
}
