import 'dart:async';

import 'package:flutter/material.dart';

Timer? _noticeTimer;

/// Shows one short notice, then removes it even if the snack bar timer stalls.
void showTransientNotice(
  BuildContext context,
  String message, {
  VoidCallback? onUndo,
}) {
  final messenger = ScaffoldMessenger.of(context);
  _noticeTimer?.cancel();
  messenger.clearSnackBars();
  final duration = onUndo == null
      ? const Duration(seconds: 2)
      : const Duration(seconds: 6);
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
      action: onUndo == null
          ? null
          : SnackBarAction(label: 'ביטול', onPressed: onUndo),
    ),
  );
  _noticeTimer = Timer(duration, () {
    messenger.removeCurrentSnackBar();
  });
}
