import 'dart:async';

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

/// Enter מצב אספקה: plain are-you-sure first.
Future<bool> confirmEnterSupplyMode(BuildContext context) {
  return confirmRecordedAction(
    context,
    enabled: true,
    action: 'להפעיל מצב אספקה בטאבלט הזה?',
  );
}

/// Leave מצב אספקה: are-you-sure, buttons unlock after [countdownSeconds].
Future<bool> confirmLeaveSupplyMode(
  BuildContext context, {
  int countdownSeconds = 2,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        _SupplyLeaveDialog(countdownSeconds: countdownSeconds),
  );
  return accepted == true;
}

class _SupplyLeaveDialog extends StatefulWidget {
  const _SupplyLeaveDialog({required this.countdownSeconds});

  final int countdownSeconds;

  @override
  State<_SupplyLeaveDialog> createState() => _SupplyLeaveDialogState();
}

class _SupplyLeaveDialogState extends State<_SupplyLeaveDialog> {
  late int _left;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _left = widget.countdownSeconds < 0 ? 0 : widget.countdownSeconds;
    if (_left > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          return;
        }
        if (_left <= 1) {
          timer.cancel();
          setState(() => _left = 0);
          return;
        }
        setState(() => _left -= 1);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _left <= 0;
    return AlertDialog(
      key: const Key('supply-leave-dialog'),
      title: const Text('האם אתה בטוח?'),
      content: Text(
        ready
            ? 'יציאה ממצב אספקה בטאבלט הזה.'
            : 'אפשר לאשר בעוד $_left…',
        style: const TextStyle(fontSize: 20),
      ),
      actions: [
        TextButton(
          key: const Key('supply-leave-no'),
          onPressed: ready ? () => Navigator.of(context).pop(false) : null,
          child: const Text('ביטול'),
        ),
        FilledButton(
          key: const Key('supply-leave-yes'),
          onPressed: ready ? () => Navigator.of(context).pop(true) : null,
          child: const Text('אישור'),
        ),
      ],
    );
  }
}
