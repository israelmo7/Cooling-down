import 'package:flutter/material.dart';

import '../../domain/entities/worker.dart';

/// Asks who is working. Returns the chosen worker id.
Future<String?> pickWorker(
  BuildContext context, {
  required List<Worker> workers,
  required bool required,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: !required,
    builder: (context) =>
        _WorkerPickerDialog(workers: workers, required: required),
  );
}

class _WorkerPickerDialog extends StatelessWidget {
  const _WorkerPickerDialog({required this.workers, required this.required});

  final List<Worker> workers;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                title: Text(worker.name, style: const TextStyle(fontSize: 22)),
                onTap: () => Navigator.of(context).pop(worker.id),
              ),
          ],
        ),
      ),
      actions: [
        if (!required)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
      ],
    );
  }
}
