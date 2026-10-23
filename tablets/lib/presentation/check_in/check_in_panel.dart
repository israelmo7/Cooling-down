import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/seed_ids.dart';
import '../../domain/entities/fridge.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/refrigeration_log.dart';
import '../../domain/failures.dart';
import '../../domain/hold_for.dart';
import '../../domain/quantity.dart';
import '../../domain/workers/worker_refresh.dart';
import '../format.dart';
import '../providers.dart';
import '../widgets/confirm_action_dialog.dart';
import '../widgets/station_widgets.dart';
import '../widgets/transient_notice.dart';

class CheckInPanel extends ConsumerStatefulWidget {
  const CheckInPanel({super.key});

  @override
  ConsumerState<CheckInPanel> createState() => _CheckInPanelState();
}

class _CheckInPanelState extends ConsumerState<CheckInPanel> {
  final _searchController = TextEditingController();
  final _holdHours = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  String _query = '';
  Product? _selectedProduct;
  double? _chosenTemperature;
  var _averageToken = 0;
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    _holdHours.dispose();
    _quantity.dispose();
    super.dispose();
  }

  Future<void> _useAverage(String productId) async {
    final token = ++_averageToken;
    final average = await ref
        .read(logRepositoryProvider)
        .averageCheckInCelsius(productId);
    if (!mounted ||
        token != _averageToken ||
        _selectedProduct?.id != productId) {
      return;
    }
    setState(() => _chosenTemperature = average);
  }

  double _reading(Fridge? fridge) {
    return _chosenTemperature ?? fridge?.midpoint ?? 2.5;
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
    final session = ref.read(workerSessionProvider).asData?.value;
    final workerName = session?.workerName.trim() ?? '';
    final refresh =
        ref.read(settingsProvider).asData?.value?.workerRefresh ??
        const WorkerRefresh();
    final quantity = tryParseQuantity(_quantity.text);
    if (product == null ||
        fridge == null ||
        quantity == null ||
        !isValidHoldHoursInput(_holdHours.text) ||
        _saving ||
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
          'קליטה: ${product.name} ב-${formatCelsius(_reading(fridge))} · כמות $quantity$who',
    );
    if (!accepted || !mounted) {
      return;
    }
    setState(() => _saving = true);
    try {
      final hours = parseHoldHours(_holdHours.text);
      final log = await ref
          .read(logRepositoryProvider)
          .insertCheckIn(
            productId: product.id,
            fridgeId: fridge.id,
            temperatureCelsius: _reading(fridge),
            workerName: workerName,
            dueAt: hours == null ? null : dueAfter(DateTime.now(), hours),
            quantity: quantity,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedProduct = null;
        _query = '';
        _searchController.clear();
        _holdHours.clear();
        _quantity.text = '1';
        _chosenTemperature = null;
      });
      showTransientNotice(
        context,
        'נקלט ${log.productNameSnapshot} ב-${formatCelsius(log.temperatureCelsius)} · ${formatClock(log.occurredAt)}',
        onUndo: () => unawaited(_undoCheckIn(log, workerName)),
      );
      unawaited(_syncSoon());
    } on CatalogEntryNotFound catch (error) {
      if (!mounted) {
        return;
      }
      showTransientNotice(context, error.message);
    } on InvalidQuantityException catch (error) {
      if (!mounted) {
        return;
      }
      showTransientNotice(context, error.message);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _addNewProduct() async {
    final typed = _query.trim();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _NewProductDialog(initialName: typed),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) {
      return;
    }
    final product = await ref
        .read(productRepositoryProvider)
        .addOneOffProduct(trimmed);
    if (!mounted || product == null) {
      return;
    }
    setState(() {
      _selectedProduct = product;
      _query = '';
      _searchController.clear();
      _chosenTemperature = null;
    });
    unawaited(_useAverage(product.id));
  }

  Future<void> _undoCheckIn(RefrigerationLog log, String workerName) async {
    try {
      await ref
          .read(logRepositoryProvider)
          .insertCheckOut(
            movementId: log.movementId,
            temperatureCelsius: log.temperatureCelsius,
            workerName: '$workerName · ביטול',
            quantity: log.quantity,
          );
      if (!mounted) {
        return;
      }
      showTransientNotice(context, 'הקליטה בוטלה ונשמרה כביטול.');
      unawaited(_syncSoon());
    } on Object {
      if (!mounted) {
        return;
      }
      showTransientNotice(context, 'לא ניתן לבטל את הקליטה.');
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
    final quantityValid = tryParseQuantity(_quantity.text) != null;
    final holdValid = isValidHoldHoursInput(_holdHours.text);
    final canConfirm =
        _selectedProduct != null &&
        fridge != null &&
        quantityValid &&
        holdValid &&
        !_saving &&
        workerAllowsAction(
          session: ref.watch(workerSessionProvider).asData?.value,
          now: DateTime.now(),
          refresh:
              ref.watch(settingsProvider).asData?.value?.workerRefresh ??
              const WorkerRefresh(),
        );
    final visible =
        products.asData?.value.any((item) => item.id == _selectedProduct?.id) ??
        false;
    final selectedName = _selectedProduct != null && !visible
        ? _selectedProduct!.name
        : null;

    return ScreenBody(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          final catalog = _CatalogPane(
            controller: _searchController,
            products: products,
            selectedProductId: _selectedProduct?.id,
            onQueryChanged: (value) => setState(() => _query = value),
            onProductSelected: (product) {
              setState(() {
                _selectedProduct = product;
                _chosenTemperature = null;
              });
              unawaited(_useAverage(product.id));
            },
            onAddNew: _addNewProduct,
          );
          final controls = _CheckInControls(
            fridges: fridges,
            selectedName: selectedName,
            temperature: _reading(fridge),
            holdHours: _holdHours,
            quantity: _quantity,
            quantityError: quantityValid
                ? null
                : 'מספר שלם בין 1 ל-$maxQuantity',
            holdError: holdValid ? null : 'מספר שעות עד 72, או להשאיר ריק',
            onInputChanged: () => setState(() {}),
            canConfirm: canConfirm,
            saving: _saving,
            onTemperatureChanged: (value) {
              _averageToken += 1;
              setState(() => _chosenTemperature = value);
            },
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
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Align(alignment: Alignment.topCenter, child: controls),
              ),
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
    required this.onAddNew,
  });

  final TextEditingController controller;
  final AsyncValue<List<Product>> products;
  final String? selectedProductId;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Product> onProductSelected;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SectionTitle('מוצר'),
            const Spacer(),
            OutlinedButton(
              key: const Key('check-in-new-product'),
              onPressed: onAddNew,
              child: const Text('מוצר חדש'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 18),
          decoration: const InputDecoration(
            hintText: 'חיפוש לפי שם',
            prefixIcon: Icon(Icons.search, size: 22),
          ),
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 14),
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
                    style: TextStyle(fontSize: 16, color: Color(0xFF5C6B70)),
                  ),
                );
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final product = items[index];
                  return ChoiceTile(
                    selected: product.id == selectedProductId,
                    onPressed: () => onProductSelected(product),
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NewProductDialog extends StatefulWidget {
  const _NewProductDialog({required this.initialName});

  final String initialName;

  @override
  State<_NewProductDialog> createState() => _NewProductDialogState();
}

class _NewProductDialogState extends State<_NewProductDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _name.text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('מוצר חדש'),
      content: TextField(
        key: const Key('check-in-new-product-name'),
        controller: _name,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'שם המוצר'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ביטול'),
        ),
        FilledButton(
          key: const Key('confirm-new-check-in-product'),
          onPressed: _submit,
          child: const Text('אישור'),
        ),
      ],
    );
  }
}

class _CheckInControls extends StatelessWidget {
  const _CheckInControls({
    required this.fridges,
    required this.selectedName,
    required this.temperature,
    required this.holdHours,
    required this.quantity,
    required this.quantityError,
    required this.holdError,
    required this.onInputChanged,
    required this.canConfirm,
    required this.saving,
    required this.onTemperatureChanged,
    required this.onConfirm,
  });

  final AsyncValue<List<Fridge>> fridges;
  final String? selectedName;
  final double temperature;
  final TextEditingController holdHours;
  final TextEditingController quantity;
  final String? quantityError;
  final String? holdError;
  final VoidCallback onInputChanged;
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
        StationPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (selectedName != null) ...[
                Text(
                  selectedName!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
              ],
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
              const SizedBox(height: 12),
              TextField(
                key: const Key('check-in-quantity'),
                controller: quantity,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'כמות',
                  hintText: '1',
                  isDense: true,
                  errorText: quantityError,
                ),
                onChanged: (_) => onInputChanged(),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('hold-hours'),
                controller: holdHours,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'יציאה בעוד',
                  hintText: 'שעות, לא חובה',
                  isDense: true,
                  errorText: holdError,
                ),
                onChanged: (_) => onInputChanged(),
              ),
              const SizedBox(height: 16),
              ConfirmBar(
                buttonKey: const Key('confirm-check-in'),
                label: saving ? 'שומר…' : 'אישור קליטה',
                onPressed: canConfirm ? onConfirm : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
