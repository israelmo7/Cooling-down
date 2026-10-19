import 'dart:async';

import 'package:flutter/material.dart';

Timer? _noticeTimer;

/// Shows one short notice, then removes it even if the snack bar timer stalls.
void showTransientNotice(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  _noticeTimer?.cancel();
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
    ),
  );
  _noticeTimer = Timer(const Duration(seconds: 2), () {
    messenger.removeCurrentSnackBar();
  });
}
