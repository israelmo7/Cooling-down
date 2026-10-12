import 'worker_session.dart';

/// How the tablet decides to ask who is working.
enum WorkerRefreshMode {
  off,
  idle,
  periodic;

  static WorkerRefreshMode parse(String raw) {
    for (final mode in values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    return WorkerRefreshMode.idle;
  }
}

/// הקפצה opens the screen when the time comes. המתנה waits for the next tap.
enum WorkerPromptStyle {
  popup,
  wait;

  static WorkerPromptStyle parse(String raw) {
    for (final style in values) {
      if (style.name == raw) {
        return style;
      }
    }
    return WorkerPromptStyle.wait;
  }
}

/// Tablet-local rule for asking who is working.
class WorkerRefresh {
  const WorkerRefresh({
    this.mode = WorkerRefreshMode.idle,
    this.style = WorkerPromptStyle.wait,
    this.idleSeconds = 600,
    this.startMinute = 8 * 60,
    this.intervalHours = 8,
    this.endMinute = 20 * 60,
  });

  final WorkerRefreshMode mode;
  final WorkerPromptStyle style;
  final int idleSeconds;
  final int startMinute;
  final int intervalHours;
  final int endMinute;

  Duration get idle => Duration(seconds: idleSeconds < 1 ? 600 : idleSeconds);

  bool promptsOnTap(DateTime now, WorkerSession? session) {
    return style == WorkerPromptStyle.wait && isDue(now, session);
  }

  bool promptsImmediately(DateTime now, WorkerSession? session) {
    return style == WorkerPromptStyle.popup && isDue(now, session);
  }

  /// True when check-in and check-out may use the signed-in worker.
  bool allowsAction(WorkerSession? session, DateTime now) {
    if (!_hasWorker(session)) {
      return false;
    }
    return !isDue(now, session);
  }

  /// True when the worker screen should appear for the current rule.
  bool isDue(DateTime now, WorkerSession? session) {
    switch (mode) {
      case WorkerRefreshMode.off:
        return false;
      case WorkerRefreshMode.idle:
        return !(session?.isActive(now, idle: idle) ?? false);
      case WorkerRefreshMode.periodic:
        final slot = latestSlot(now);
        if (slot == null) {
          return false;
        }
        final at = session?.activeAt;
        if (!_hasWorker(session) || at == null) {
          return true;
        }
        return at.toUtc().isBefore(slot.toUtc());
    }
  }

  /// Stable id for one prompt, so a dismissed הקפצה does not reopen itself.
  String? promptKey(DateTime now, WorkerSession? session) {
    if (!isDue(now, session)) {
      return null;
    }
    if (mode == WorkerRefreshMode.periodic) {
      return latestSlot(now)?.toUtc().toIso8601String();
    }
    final at = session?.activeAt;
    if (at == null) {
      return 'idle-missing';
    }
    return 'idle-${at.toUtc().toIso8601String()}';
  }

  /// When the screen should look again: the next slot, the window edge, or idle expiry.
  DateTime? nextChange(DateTime now, WorkerSession? session) {
    switch (mode) {
      case WorkerRefreshMode.off:
        return null;
      case WorkerRefreshMode.idle:
        final at = session?.activeAt;
        if (!_hasWorker(session) || at == null) {
          return null;
        }
        final expiry = at.toUtc().add(idle);
        if (!expiry.isAfter(now.toUtc())) {
          return null;
        }
        return expiry;
      case WorkerRefreshMode.periodic:
        return _nextBoundary(now);
    }
  }

  /// Latest scheduled instant at or before [now], inside today's window.
  DateTime? latestSlot(DateTime now) {
    final window = _window(now.toLocal());
    if (window == null) {
      return null;
    }
    final local = now.toLocal();
    if (local.isBefore(window.start) || local.isAfter(window.end)) {
      return null;
    }
    DateTime? latest;
    var cursor = window.start;
    while (!cursor.isAfter(window.end) && !cursor.isAfter(local)) {
      latest = cursor;
      cursor = cursor.add(Duration(hours: intervalHours));
    }
    return latest;
  }

  DateTime? _nextBoundary(DateTime now) {
    final local = now.toLocal();
    final window = _window(local);
    if (window == null) {
      return null;
    }
    if (local.isBefore(window.start)) {
      return window.start;
    }
    if (!local.isBefore(window.end) && !local.isAfter(window.end)) {
      return local.add(const Duration(seconds: 1));
    }
    if (local.isAfter(window.end)) {
      final tomorrow = local.add(const Duration(days: 1));
      return _onDay(tomorrow, startMinute);
    }
    var cursor = window.start;
    while (!cursor.isAfter(window.end)) {
      if (cursor.isAfter(local)) {
        return cursor;
      }
      cursor = cursor.add(Duration(hours: intervalHours));
    }
    if (local.isBefore(window.end)) {
      return window.end;
    }
    return _onDay(local.add(const Duration(days: 1)), startMinute);
  }

  _Window? _window(DateTime local) {
    if (intervalHours < 1) {
      return null;
    }
    final start = _onDay(local, startMinute);
    final end = _onDay(local, endMinute);
    if (!end.isAfter(start)) {
      return null;
    }
    return _Window(start, end);
  }

  bool _hasWorker(WorkerSession? session) {
    final id = session?.workerId;
    final name = session?.workerName.trim() ?? '';
    return id != null && id.isNotEmpty && name.isNotEmpty;
  }
}

/// A check-in or check-out needs someone signed in under the refresh rule.
bool workerAllowsAction({
  required WorkerSession? session,
  required DateTime now,
  WorkerRefresh refresh = const WorkerRefresh(),
}) {
  return refresh.allowsAction(session, now);
}

class _Window {
  const _Window(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

DateTime _onDay(DateTime day, int minuteOfDay) {
  final clamped = minuteOfDay.clamp(0, 23 * 60 + 59);
  return DateTime(day.year, day.month, day.day).add(Duration(minutes: clamped));
}

int? parseClockMinutes(String raw) {
  final trimmed = raw.trim();
  final clock = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(trimmed);
  if (clock != null) {
    return _clock(int.parse(clock.group(1)!), int.parse(clock.group(2)!));
  }
  final digits = RegExp(r'^\d{3,4}$').firstMatch(trimmed);
  if (digits == null) {
    return null;
  }
  final value = trimmed.padLeft(4, '0');
  return _clock(
    int.parse(value.substring(0, 2)),
    int.parse(value.substring(2)),
  );
}

int? _clock(int hour, int minute) {
  if (hour > 23 || minute > 59) {
    return null;
  }
  return hour * 60 + minute;
}

String formatClockMinutes(int minuteOfDay) {
  final clamped = minuteOfDay.clamp(0, 23 * 60 + 59);
  final hour = clamped ~/ 60;
  final minute = clamped % 60;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

int normalizeIntervalHours(String raw) {
  final parsed = int.tryParse(raw.trim());
  if (parsed == null || parsed < 1) {
    return 8;
  }
  if (parsed > 24) {
    return 24;
  }
  return parsed;
}
