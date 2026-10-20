import 'package:flutter/material.dart';

const holdOverdue = Color(0xFF8F3D3D);
const holdSoon = Color(0xFF8A5A2B);

/// A quiet name color. Red after the time, orange in the hour before it.
Color? holdNameColor(DateTime? dueAt, DateTime now, {required bool markSoon}) {
  if (dueAt == null) {
    return null;
  }
  final due = dueAt.toLocal();
  if (!due.isAfter(now)) {
    return holdOverdue;
  }
  if (markSoon && due.difference(now) <= const Duration(hours: 1)) {
    return holdSoon;
  }
  return null;
}
