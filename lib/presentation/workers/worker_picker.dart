import 'package:flutter/material.dart';

import '../../domain/entities/worker.dart';
import '../../domain/repositories/worker_repository.dart';

var _workerPromptOpen = false;

/// Returns the worker name for this operation, asking when nobody is signed in.
Future<String?> ensureWorkerName({
  required BuildContext context,
  required WorkerRepository repository,
}) async {
  final session = await repository.readSession();
  if (session.isActive(DateTime.now())) {
    return session.workerName;
  }
  if (_workerPromptOpen) {
    return null;
  }
  final workers = await repository.listWorkers();
  if (!context.mounted) {
    return null;
  }
  if (workers.isEmpty) {
    final typed = await _showPrompt<String>(
      () => showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _NameWorkerDialog(),
      ),
    );
    final name = typed?.trim() ?? '';
    if (name.isEmpty) {
      return null;
    }
    final created = await repository.addWorker(name);
    if (created == null) {
      return null;
    }
    await repository.selectWorker(created.id);
    return created.name;
  }
  final picked = await pickWorker(context, workers: workers, required: true);
  if (picked == null) {
    return null;
  }
  await repository.selectWorker(picked);
  final next = await repository.readSession();
  if (next.workerName.trim().isEmpty) {
    return null;
  }
  return next.workerName;
}

/// Asks who is working. Returns the chosen worker id.
Future<String?> pickWorker(
  BuildContext context, {
  required List<Worker> workers,
  required bool required,
}) {
  return _showPrompt(
    () => showDialog<String>(
      context: context,
      barrierDismissible: !required,
      builder: (context) =>
          _WorkerPickerDialog(workers: workers, required: required),
    ),
  );
}

Future<T?> _showPrompt<T>(Future<T?> Function() show) async {
  if (_workerPromptOpen) {
    return null;
  }
  _workerPromptOpen = true;
  try {
    return await show();
  } finally {
    _workerPromptOpen = false;
  }
}

class _WorkerPickerDialog extends StatelessWidget {
  const _WorkerPickerDialog({required this.workers, required this.required});

  final List<Worker> workers;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !required,
      child: AlertDialog(
        key: const Key('worker-picker'),
        title: const Text('מי עובד עכשיו?'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final worker in workers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    worker.name,
                    style: const TextStyle(fontSize: 22),
                  ),
                  onTap: () => Navigator.of(context).pop(worker.id),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }
}

class _NameWorkerDialog extends StatefulWidget {
  const _NameWorkerDialog();

  @override
  State<_NameWorkerDialog> createState() => _NameWorkerDialogState();
}

class _NameWorkerDialogState extends State<_NameWorkerDialog> {
  final _name = TextEditingController();

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
    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: const Key('worker-picker'),
        title: const Text('מי עובד עכשיו?'),
        content: TextField(
          key: const Key('worker-name'),
          controller: _name,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'שם העובד'),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          FilledButton(
            key: const Key('confirm-worker-name'),
            onPressed: _submit,
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }
}
