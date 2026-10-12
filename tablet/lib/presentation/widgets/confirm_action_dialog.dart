import 'package:flutter/material.dart';

/// Asks before a check-in or check-out when אימות פעולה is on.
Future<bool> confirmRecordedAction(
  BuildContext context, {
  required bool enabled,
  required String action,
}) async {
  if (!enabled) {
    return true;
  }
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('האם אתה בטוח?'),
        content: Text(action, style: const TextStyle(fontSize: 22)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            key: const Key('confirm-recorded-action'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('אישור'),
          ),
        ],
      );
    },
  );
  return accepted == true;
}
