import 'package:flutter/material.dart';

import '../../domain/entities/worker.dart';
import '../widgets/station_widgets.dart';

var _workerPromptOpen = false;

/// Types a worker name when the list is still empty. Returns the trimmed name.
Future<String?> askWorkerName(BuildContext context) {
  return _showPrompt(
    () => showDialog<String>(
      context: context,
      builder: (context) => const _NameWorkerDialog(),
    ),
  );
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
          width: 520,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final worker in workers)
                  SizedBox(
                    key: Key('worker-square-${worker.id}'),
                    width: 156,
                    height: 156,
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: stationLine),
                      ),
                      child: InkWell(
                        customBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        onTap: () => Navigator.of(context).pop(worker.id),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              worker.name,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF122428),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
