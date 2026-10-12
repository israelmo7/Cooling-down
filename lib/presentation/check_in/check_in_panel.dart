import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/fridge.dart';
import '../../domain/entities/product.dart';
import '../../domain/failures.dart';
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
            'נקלט ${log.productNameSnapshot} ב-${formatCelsius(log.temperatureCelsius)} · ${formatClock(log.occurredAt)}',
          ),
        ),
      );
      unawaited(_syncSoon());
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

  Future<void> _syncSoon() async {
    try {
      await ref.read(syncRepositoryProvider).trySync();
    } on Object {
      // The row stays on this tablet until the shop computer is reachable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productSearchProvider(_query));
    final fridges = ref.watch(fridgesProvider);
    final canConfirm =
        _selectedProduct != null && _selectedFridge != null && !_saving;

    return ScreenBody(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          final catalog = _CatalogPane(
            controller: _searchController,
            products: products,
            selectedProductId: _selectedProduct?.id,
            onQueryChanged: (value) => setState(() => _query = value),
            onProductSelected: (product) =>
                setState(() => _selectedProduct = product),
          );
          final controls = _CheckInControls(
            fridges: fridges,
            selectedFridgeId: _selectedFridge?.id,
            temperature: _temperature,
            canConfirm: canConfirm,
            saving: _saving,
            expandChoices: wide,
            onFridgeSelected: _selectFridge,
            onTemperatureChanged: (value) =>
                setState(() => _temperature = value),
            onConfirm: _confirm,
          );
          if (!wide) {
            return Column(
              children: [
                Expanded(flex: 3, child: catalog),
                const SizedBox(height: 24),
                controls,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: catalog),
              const SizedBox(width: 32),
              Expanded(flex: 2, child: controls),
            ],
          );
        },
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

class _CatalogPane extends StatelessWidget {
  const _CatalogPane({
    required this.controller,
    required this.products,
    required this.selectedProductId,
    required this.onQueryChanged,
    required this.onProductSelected,
  });

  final TextEditingController controller;
  final AsyncValue<List<Product>> products;
  final String? selectedProductId;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Product> onProductSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('מוצר', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 22),
          decoration: const InputDecoration(
            hintText: 'חיפוש לפי שם',
            prefixIcon: Icon(Icons.search, size: 32),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          ),
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: products.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('לא ניתן לטעון מוצרים: $error'),
            data: (items) {
              if (items.isEmpty) {
                return const Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    'אין מוצרים תואמים.',
                    style: TextStyle(fontSize: 20),
                  ),
                );
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 96,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final product = items[index];
                  final selected = product.id == selectedProductId;
                  final button = selected
                      ? FilledButton(
                          onPressed: () => onProductSelected(product),
                          child: Text(product.name),
                        )
                      : FilledButton.tonal(
                          onPressed: () => onProductSelected(product),
                          child: Text(product.name),
                        );
                  return button;
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CheckInControls extends StatelessWidget {
  const _CheckInControls({
    required this.fridges,
    required this.selectedFridgeId,
    required this.temperature,
    required this.canConfirm,
    required this.saving,
    required this.expandChoices,
    required this.onFridgeSelected,
    required this.onTemperatureChanged,
    required this.onConfirm,
  });

  final AsyncValue<List<Fridge>> fridges;
  final String? selectedFridgeId;
  final double temperature;
  final bool canConfirm;
  final bool saving;
  final bool expandChoices;
  final ValueChanged<Fridge> onFridgeSelected;
  final ValueChanged<double> onTemperatureChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('מקרר', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        fridges.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('לא ניתן לטעון מקררים: $error'),
          data: (items) {
            final choices = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0) const SizedBox(height: 16),
                  if (expandChoices)
                    Expanded(child: _fridgeButton(items[index]))
                  else
                    SizedBox(height: 80, child: _fridgeButton(items[index])),
                ],
              ],
            );
            if (!expandChoices) {
              return choices;
            }
            return Expanded(child: choices);
          },
        ),
        const SizedBox(height: 28),
        TemperatureStepper(
          temperature: temperature,
          onChanged: onTemperatureChanged,
        ),
        const SizedBox(height: 12),
        Text(
          'השעה נרשמת ברגע האישור',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        ConfirmBar(
          buttonKey: const Key('confirm-check-in'),
          label: saving ? 'שומר…' : 'אישור קליטה',
          onPressed: canConfirm ? onConfirm : null,
        ),
      ],
    );
  }

  Widget _fridgeButton(Fridge fridge) {
    final selected = fridge.id == selectedFridgeId;
    final child = Text(fridge.name, textAlign: TextAlign.center);
    if (selected) {
      return FilledButton(
        onPressed: () => onFridgeSelected(fridge),
        child: child,
      );
    }
    return FilledButton.tonal(
      onPressed: () => onFridgeSelected(fridge),
      child: child,
    );
  }
}
