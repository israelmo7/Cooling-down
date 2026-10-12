import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/worker.dart';
import '../providers.dart';

class WorkerCatalogEditor extends ConsumerStatefulWidget {
  const WorkerCatalogEditor({super.key, required this.unlocked});

  final bool unlocked;

  @override
  ConsumerState<WorkerCatalogEditor> createState() =>
      _WorkerCatalogEditorState();
}

class _WorkerCatalogEditorState extends ConsumerState<WorkerCatalogEditor> {
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
    await ref.read(workerRepositoryProvider).addWorker(name);
    if (mounted) {
      _name.clear();
    }
  }

  Future<void> _rename(Worker worker) async {
    final next = await showDialog<String>(
      context: context,
      builder: (context) => _RenameWorkerDialog(initialName: worker.name),
    );
    final renamed = next?.trim() ?? '';
    if (renamed.isEmpty) {
      return;
    }
    await ref.read(workerRepositoryProvider).renameWorker(worker.id, renamed);
  }

  Future<void> _delete(Worker worker) async {
    await ref.read(workerRepositoryProvider).deleteWorker(worker.id);
  }

  @override
  Widget build(BuildContext context) {
    final workers = ref.watch(workersProvider);
    return ExpansionTile(
      key: const Key('settings-worker-list'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      title: Text('עובדים', style: Theme.of(context).textTheme.headlineSmall),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            'השם נשמר על כל קליטה והוצאה.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.unlocked) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('new-worker-name'),
                  controller: _name,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'עובד חדש',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: const Key('add-worker'),
                onPressed: _add,
                child: const Text('הוספה'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        workers.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('לא ניתן לטעון עובדים: $error'),
          data: (items) {
            if (items.isEmpty) {
              return const Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('אין עובדים עדיין.'),
              );
            }
            return Column(
              children: [
                for (final worker in items) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      worker.name,
                      style: const TextStyle(fontSize: 20),
                    ),
                    trailing: widget.unlocked
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'שינוי שם',
                                onPressed: () => _rename(worker),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip: 'מחיקה',
                                onPressed: () => _delete(worker),
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

class _RenameWorkerDialog extends StatefulWidget {
  const _RenameWorkerDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameWorkerDialog> createState() => _RenameWorkerDialogState();
}

class _RenameWorkerDialogState extends State<_RenameWorkerDialog> {
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
        key: const Key('rename-worker'),
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'שם העובד'),
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
