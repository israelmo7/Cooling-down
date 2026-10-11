import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/open_holding.dart';
import '../../domain/failures.dart';
import '../format.dart';
import '../providers.dart';
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

  Future<void> _confirm(List<OpenHolding> holdings) async {
    final movementId = _selectedMovementId;
    if (movementId == null || _saving) {
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
            'Checked out ${log.productNameSnapshot} at ${formatCelsius(log.temperatureCelsius)} · ${formatClock(log.occurredAt)}',
          ),
        ),
      );
    } on NoOpenHoldingException {
      if (!mounted) {
        return;
      }
      setState(() => _selectedMovementId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That item is no longer in a fridge.')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final holdings = ref.watch(openHoldingsProvider);
    return StationPanel(
      title: 'Check out',
      child: holdings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('Could not load open items: $error'),
        data: (items) {
          final filtered = _filter(items);
          final selectedStillOpen = items.any(
            (item) => item.movementId == _selectedMovementId,
          );
          final canConfirm =
              _selectedMovementId != null && selectedStillOpen && !_saving;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: 'Find an open item',
                  hintText: 'Filter by product or fridge',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? const Text('Nothing open matches this filter.')
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final holding = filtered[index];
                          final selected =
                              holding.movementId == _selectedMovementId;
                          final label =
                              '${holding.productName}\n${holding.fridgeName} · in at ${formatCelsius(holding.checkInTemperatureCelsius)}';
                          return SizedBox(
                            height: 72,
                            child: selected
                                ? FilledButton(
                                    onPressed: () => _select(holding),
                                    child: Text(label),
                                  )
                                : FilledButton.tonal(
                                    onPressed: () => _select(holding),
                                    child: Text(label),
                                  ),
                          );
                        },
                      ),
              ),
              TemperatureStepper(
                temperature: _temperature,
                onChanged: (value) => setState(() => _temperature = value),
              ),
              const SizedBox(height: 8),
              Text(
                'Time is captured when you confirm',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('confirm-check-out'),
                onPressed: canConfirm ? () => _confirm(items) : null,
                child: Text(_saving ? 'Saving…' : 'Confirm check-out'),
              ),
            ],
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

  void _select(OpenHolding holding) {
    setState(() => _selectedMovementId = holding.movementId);
  }
}
