import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product.dart';
import '../providers.dart';
import '../widgets/transient_notice.dart';

class ProductCatalogEditor extends ConsumerStatefulWidget {
  const ProductCatalogEditor({super.key, required this.unlocked});

  final bool unlocked;

  @override
  ConsumerState<ProductCatalogEditor> createState() =>
      _ProductCatalogEditorState();
}

class _ProductCatalogEditorState extends ConsumerState<ProductCatalogEditor> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      return;
    }
    await ref.read(productRepositoryProvider).addProduct(name);
    if (mounted) {
      _name.clear();
    }
  }

  Future<void> _rename(Product product) async {
    final next = await showDialog<String>(
      context: context,
      builder: (context) => _RenameProductDialog(initialName: product.name),
    );
    final renamed = next?.trim() ?? '';
    if (renamed.isEmpty) {
      return;
    }
    await ref
        .read(productRepositoryProvider)
        .renameProduct(product.id, renamed);
  }

  Future<void> _delete(Product product) async {
    final removed = await ref
        .read(productRepositoryProvider)
        .deleteProduct(product.id);
    if (!mounted || removed) {
      return;
    }
    showTransientNotice(
      context,
      'אי אפשר למחוק מוצר שכבר נרשם. אפשר לשנות את השם.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productCatalogProvider);
    return ExpansionTile(
      key: const Key('settings-product-list'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      title: Text('מוצרים', style: Theme.of(context).textTheme.headlineSmall),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'החיפוש בקליטה משתמש ברשימה הזו.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.unlocked) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('new-product-name'),
                  controller: _name,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'מוצר חדש',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: const Key('add-product'),
                onPressed: _add,
                child: const Text('הוספה'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        products.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('לא ניתן לטעון מוצרים: $error'),
          data: (items) {
            if (items.isEmpty) {
              return const Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('אין מוצרים עדיין.'),
              );
            }
            return Column(
              children: [
                for (final product in items) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      product.name,
                      style: const TextStyle(fontSize: 20),
                    ),
                    trailing: widget.unlocked
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'שינוי שם',
                                onPressed: () => _rename(product),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip: 'מחיקה',
                                onPressed: () => _delete(product),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          )
                        : null,
                  ),
                  const Divider(height: 1),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RenameProductDialog extends StatefulWidget {
  const _RenameProductDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameProductDialog> createState() => _RenameProductDialogState();
}

class _RenameProductDialogState extends State<_RenameProductDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('שינוי שם'),
      content: TextField(
        key: const Key('rename-product'),
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'שם המוצר'),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ביטול'),
        ),
        FilledButton(onPressed: _save, child: const Text('שמירה')),
      ],
    );
  }
}
