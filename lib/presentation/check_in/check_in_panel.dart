import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/failures.dart';
import '../../domain/entities/fridge.dart';
import '../../domain/entities/product.dart';
import '../format.dart';
import '../providers.dart';
import '../widgets/station_widgets.dart';

class CheckInPanel extends ConsumerStatefulWidget {
  const CheckInPanel({super.key});

  @override
  ConsumerState<CheckInPanel> createState() => _CheckInPanelState();
}

class _CheckInPanelState extends ConsumerState<CheckInPanel> {
  final _searchController = TextEditingController();
  String _query = '';
  Product? _selectedProduct;
  Fridge? _selectedFridge;
  double _temperature = 4;
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final product = _selectedProduct;
    final fridge = _selectedFridge;
    if (product == null || fridge == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final log = await ref
          .read(logRepositoryProvider)
          .insertCheckIn(
            productId: product.id,
            fridgeId: fridge.id,
            temperatureCelsius: _temperature,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedProduct = null;
        _query = '';
        _searchController.clear();
        _temperature = (fridge.minCelsius + fridge.maxCelsius) / 2;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Checked in ${log.productNameSnapshot} at ${formatCelsius(log.temperatureCelsius)} · ${formatClock(log.occurredAt)}',
          ),
        ),
      );
    } on CatalogEntryNotFound catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productSearchProvider(_query));
    final fridges = ref.watch(fridgesProvider);
    final canConfirm =
        _selectedProduct != null && _selectedFridge != null && !_saving;

    return StationPanel(
      title: 'Check in',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 20),
            decoration: const InputDecoration(
              labelText: 'Product',
              hintText: 'Search name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Could not load products: $error'),
              data: (items) {
                if (items.isEmpty) {
                  return const Text('No matching products.');
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = items[index];
                    final selected = product.id == _selectedProduct?.id;
                    return SizedBox(
                      height: 64,
                      child: selected
                          ? FilledButton(
                              onPressed: () =>
                                  setState(() => _selectedProduct = product),
                              child: Text(
                                product.name,
                                style: const TextStyle(fontSize: 18),
                              ),
                            )
                          : FilledButton.tonal(
                              onPressed: () =>
                                  setState(() => _selectedProduct = product),
                              child: Text(
                                product.name,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          fridges.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Could not load fridges: $error'),
            data: (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final fridge in items) ...[
                  SizedBox(
                    height: 56,
                    child: fridge.id == _selectedFridge?.id
                        ? FilledButton(
                            onPressed: () => _selectFridge(fridge),
                            child: Text(fridge.name),
                          )
                        : FilledButton.tonal(
                            onPressed: () => _selectFridge(fridge),
                            child: Text(fridge.name),
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
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
            key: const Key('confirm-check-in'),
            onPressed: canConfirm ? _confirm : null,
            child: Text(_saving ? 'Saving…' : 'Confirm check-in'),
          ),
        ],
      ),
    );
  }

  void _selectFridge(Fridge fridge) {
    setState(() {
      _selectedFridge = fridge;
      _temperature = (fridge.minCelsius + fridge.maxCelsius) / 2;
    });
  }
}
