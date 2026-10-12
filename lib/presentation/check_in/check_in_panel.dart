import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/seed_ids.dart';
import '../../domain/entities/fridge.dart';
import '../../domain/entities/product.dart';
import '../../domain/failures.dart';
import '../format.dart';
import '../providers.dart';
import '../widgets/confirm_action_dialog.dart';
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
  double _temperature = 4;
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Fridge? _environmentFridge(List<Fridge> items) {
    for (final fridge in items) {
      if (fridge.id == SeedIds.kitchenFridge) {
        return fridge;
      }
    }
    if (items.isEmpty) {
      return null;
    }
    return items.first;
  }

  Future<void> _confirm() async {
    final product = _selectedProduct;
    final fridge = _environmentFridge(
      ref.read(fridgesProvider).asData?.value ?? const [],
    );
    if (product == null || fridge == null || _saving) {
      return;
    }
    final accepted = await confirmRecordedAction(
      context,
      enabled:
          ref.read(settingsProvider).asData?.value?.confirmAction ?? false,
      action: 'קליטה: ${product.name} ב-${formatCelsius(_temperature)}',
    );
    if (!accepted || !mounted) {
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
    final fridge = fridges.asData == null
        ? null
        : _environmentFridge(fridges.asData!.value);
    final canConfirm = _selectedProduct != null && fridge != null && !_saving;

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
            temperature: _temperature,
            canConfirm: canConfirm,
            saving: _saving,
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
    required this.temperature,
    required this.canConfirm,
    required this.saving,
    required this.onTemperatureChanged,
    required this.onConfirm,
  });

  final AsyncValue<List<Fridge>> fridges;
  final double temperature;
  final bool canConfirm;
  final bool saving;
  final ValueChanged<double> onTemperatureChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fridges.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('לא ניתן לטעון את הסביבה: $error'),
          data: (_) => const SizedBox.shrink(),
        ),
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
}
