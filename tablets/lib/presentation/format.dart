import '../core/temperature.dart';

String formatClock(DateTime utc) {
  final local = utc.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatInside(DateTime checkedInAt, DateTime now) {
  final elapsed = now.toUtc().difference(checkedInAt.toUtc());
  if (elapsed.inMinutes < 1) {
    return 'עכשיו';
  }
  if (elapsed.inHours < 1) {
    return '${elapsed.inMinutes} דק׳ במקרר';
  }
  final minutes = elapsed.inMinutes.remainder(60);
  return '${elapsed.inHours} שע׳ $minutes דק׳ במקרר';
}

String formatCelsius(double temperature) => ltrCelsiusSpaced(temperature);
