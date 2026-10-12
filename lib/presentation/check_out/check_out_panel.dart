import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/open_holding.dart';
import '../../domain/failures.dart';
import '../format.dart';
import '../providers.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/station_widgets.dart';

class CheckOutPanel extends ConsumerStatefulWidget {
  const CheckOutPanel({super.key});

  @override
  ConsumerState<CheckOutPanel> createState() => _CheckOutPanelState();
}

class _CheckOutPanelState extends ConsumerState<CheckOutPanel> {
  String _query = '';
  String? _selectedMovementId;
  double _temperature = 4;
  bool _saving = false;

  Future<void> _confirm() async {
    final movementId = _selectedMovementId;
    if (movementId == null || _saving) {
      return;
    }
    final holdings = ref.read(openHoldingsProvider).asData?.value ?? const [];
    OpenHolding? holding;
    for (final item in holdings) {
      if (item.movementId == movementId) {
        holding = item;
        break;
      }
    }
    if (holding == null) {
      return;
    }
    final accepted = await confirmRecordedAction(
      context,
      enabled:
          ref.read(settingsProvider).asData?.value?.confirmAction ?? false,
      action: 'הוצאה: ${holding.productName} ב-${formatCelsius(_temperature)}',
    );
    if (!accepted || !mounted) {
      return;
    }
    setState(() => _saving = true);
    try {
      final log = await ref
          .read(logRepositoryProvider)
          .insertCheckOut(
            movementId: movementId,
            temperatureCelsius: _temperature,
          );
      if (!mounted) {
        return;
      }
      setState(() => _selectedMovementId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'הוצא ${log.productNameSnapshot} ב-${formatCelsius(log.temperatureCelsius)} · ${formatClock(log.occurredAt)}',
          ),
        ),
      );
      unawaited(_syncSoon());
    } on NoOpenHoldingException {
      if (!mounted) {
        return;
      }
      setState(() => _selectedMovementId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('הפריט כבר לא נמצא במקרר.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _syncSoon() async {
    try {
      await ref.read(syncRepositoryProvider).trySync();
    } on Object {
      // The row stays on this tablet until the shop computer is reachable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final holdings = ref.watch(openHoldingsProvider);
    return ScreenBody(
      child: holdings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('לא ניתן לטעון פריטים פתוחים: $error'),
        data: (items) {
          final filtered = _filter(items);
          final selectedStillOpen = items.any(
            (item) => item.movementId == _selectedMovementId,
          );
          final canConfirm =
              _selectedMovementId != null && selectedStillOpen && !_saving;
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 800;
              final list = _OpenItemList(
                items: filtered,
                query: _query,
                hasAnyItems: items.isNotEmpty,
                selectedMovementId: _selectedMovementId,
                onQueryChanged: (value) => setState(() => _query = value),
                onSelected: (holding) =>
                    setState(() => _selectedMovementId = holding.movementId),
              );
              final controls = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  TemperatureStepper(
                    temperature: _temperature,
                    onChanged: (value) => setState(() => _temperature = value),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'השעה נרשמת ברגע האישור',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  ConfirmBar(
                    buttonKey: const Key('confirm-check-out'),
                    label: _saving ? 'שומר…' : 'אישור הוצאה',
                    onPressed: canConfirm ? _confirm : null,
                  ),
                ],
              );
              if (!wide) {
                return Column(
                  children: [
                    Expanded(child: list),
                    const SizedBox(height: 24),
                    TemperatureStepper(
                      temperature: _temperature,
                      onChanged: (value) =>
                          setState(() => _temperature = value),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'השעה נרשמת ברגע האישור',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 20),
                    ConfirmBar(
                      buttonKey: const Key('confirm-check-out'),
                      label: _saving ? 'שומר…' : 'אישור הוצאה',
                      onPressed: canConfirm ? _confirm : null,
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: list),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: controls),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<OpenHolding> _filter(List<OpenHolding> items) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return items;
    }
    return items
        .where(
          (item) =>
              item.productName.toLowerCase().contains(query) ||
              item.fridgeName.toLowerCase().contains(query),
        )
        .toList();
  }
}

class _OpenItemList extends StatelessWidget {
  const _OpenItemList({
    required this.items,
    required this.query,
    required this.hasAnyItems,
    required this.selectedMovementId,
    required this.onQueryChanged,
    required this.onSelected,
  });

  final List<OpenHolding> items;
  final String query;
  final bool hasAnyItems;
  final String? selectedMovementId;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<OpenHolding> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('פריטים פתוחים', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextField(
          style: const TextStyle(fontSize: 22),
          decoration: const InputDecoration(
            hintText: 'סינון לפי מוצר או מקרר',
            prefixIcon: Icon(Icons.search, size: 32),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          ),
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: items.isEmpty
              ? Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    hasAnyItems && query.trim().isNotEmpty
                        ? 'אין פריט פתוח שמתאים לסינון.'
                        : 'אין כרגע פריטים במקרר.',
                    style: const TextStyle(fontSize: 22),
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final holding = items[index];
                    final selected = holding.movementId == selectedMovementId;
                    final label = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          holding.productName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${holding.fridgeName} · נקלט ב-${formatCelsius(holding.checkInTemperatureCelsius)}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    );
                    return SizedBox(
                      height: 112,
                      width: double.infinity,
                      child: selected
                          ? FilledButton(
                              style: FilledButton.styleFrom(
                                alignment: AlignmentDirectional.centerStart,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                              ),
                              onPressed: () => onSelected(holding),
                              child: label,
                            )
                          : FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                alignment: AlignmentDirectional.centerStart,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                              ),
                              onPressed: () => onSelected(holding),
                              child: label,
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
