import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/open_holding.dart';
import '../../domain/failures.dart';
import '../../domain/workers/worker_refresh.dart';
import '../format.dart';
import '../providers.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/station_widgets.dart';
import '../widgets/transient_notice.dart';

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
    final session = ref.read(workerSessionProvider).asData?.value;
    final workerName = session?.workerName.trim() ?? '';
    final refresh =
        ref.read(settingsProvider).asData?.value?.workerRefresh ??
        const WorkerRefresh();
    if (holding == null ||
        !workerAllowsAction(
          session: session,
          now: DateTime.now(),
          refresh: refresh,
        )) {
      return;
    }
    final who = ' · $workerName';
    final accepted = await confirmRecordedAction(
      context,
      enabled: ref.read(settingsProvider).asData?.value?.confirmAction ?? false,
      action:
          'הוצאה: ${holding.productName} ב-${formatCelsius(_temperature)}$who',
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
            workerName: workerName,
          );
      if (!mounted) {
        return;
      }
      setState(() => _selectedMovementId = null);
      showTransientNotice(
        context,
        'הוצא ${log.productNameSnapshot} ב-${formatCelsius(log.temperatureCelsius)} · ${formatClock(log.occurredAt)}',
      );
      unawaited(_syncSoon());
    } on NoOpenHoldingException {
      if (!mounted) {
        return;
      }
      setState(() => _selectedMovementId = null);
      showTransientNotice(context, 'הפריט כבר לא נמצא במקרר.');
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
              _selectedMovementId != null &&
              selectedStillOpen &&
              !_saving &&
              workerAllowsAction(
                session: ref.watch(workerSessionProvider).asData?.value,
                now: DateTime.now(),
                refresh:
                    ref.watch(settingsProvider).asData?.value?.workerRefresh ??
                    const WorkerRefresh(),
              );
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
              final controls = _CheckOutControls(
                temperature: _temperature,
                saving: _saving,
                canConfirm: canConfirm,
                onTemperatureChanged: (value) =>
                    setState(() => _temperature = value),
                onConfirm: _confirm,
              );
              if (!wide) {
                return Column(
                  children: [
                    Expanded(child: list),
                    const SizedBox(height: 16),
                    controls,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: list),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: controls,
                    ),
                  ),
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

class _CheckOutControls extends StatelessWidget {
  const _CheckOutControls({
    required this.temperature,
    required this.saving,
    required this.canConfirm,
    required this.onTemperatureChanged,
    required this.onConfirm,
  });

  final double temperature;
  final bool saving;
  final bool canConfirm;
  final ValueChanged<double> onTemperatureChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return StationPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TemperatureStepper(
            temperature: temperature,
            onChanged: onTemperatureChanged,
          ),
          const SizedBox(height: 8),
          Text(
            'השעה נרשמת ברגע האישור',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: const Color(0xFF5C6B70)),
          ),
          const SizedBox(height: 16),
          ConfirmBar(
            buttonKey: const Key('confirm-check-out'),
            label: saving ? 'שומר…' : 'אישור הוצאה',
            onPressed: canConfirm ? onConfirm : null,
          ),
        ],
      ),
    );
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
        const SectionTitle('פריטים פתוחים'),
        const SizedBox(height: 14),
        TextField(
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            hintText: 'סינון לפי מוצר',
            prefixIcon: Icon(Icons.search, size: 22),
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
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5C6B70),
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final holding = items[index];
                    final selected = holding.movementId == selectedMovementId;
                    return SizedBox(
                      height: 76,
                      width: double.infinity,
                      child: ChoiceTile(
                        selected: selected,
                        onPressed: () => onSelected(holding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              holding.productName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'נקלט ב-${formatCelsius(holding.checkInTemperatureCelsius)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5C6B70),
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
  }
}
