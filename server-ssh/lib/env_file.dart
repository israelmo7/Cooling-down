import 'dart:io';

final _key = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
final _assignment = RegExp(
  r'^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$',
);
final _plainValue = RegExp(r'^[A-Za-z0-9_./:@+-]*$');

/// `.env` in the working directory, or `server-ssh/.env` when the process is
/// started from the repository root.
File resolveEnvFile() {
  final local = File('.env');
  if (local.existsSync()) {
    return local;
  }
  final nested = File('server-ssh/.env');
  if (nested.existsSync() || Directory('server-ssh').existsSync()) {
    return nested;
  }
  return local;
}

Map<String, String> loadEnvFile(File file) {
  if (!file.existsSync()) {
    return {};
  }
  final values = <String, String>{};
  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final match = _assignment.firstMatch(line);
    if (match == null) {
      continue;
    }
    final key = match.group(1)!;
    if (!_key.hasMatch(key)) {
      continue;
    }
    values[key] = _decode(match.group(2)!.trim());
  }
  return values;
}

/// Replaces [updates] in [file] and keeps every other line.
void writeEnvKeys(File file, Map<String, String> updates) {
  final pending = Map<String, String>.from(updates);
  final next = <String>[];
  if (file.existsSync()) {
    for (final line in file.readAsLinesSync()) {
      final match = _assignment.firstMatch(line.trim());
      final key = match?.group(1);
      if (key == null || !pending.containsKey(key)) {
        next.add(line);
        continue;
      }
      next.add('$key=${_encode(pending.remove(key)!)}');
    }
  }
  for (final entry in pending.entries) {
    next.add('${entry.key}=${_encode(entry.value)}');
  }
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('${next.join('\n')}\n');
}

String _decode(String raw) {
  if (raw.length < 2) {
    return raw;
  }
  final quote = raw[0];
  if ((quote != '"' && quote != "'") || !raw.endsWith(quote)) {
    return raw;
  }
  final inner = raw.substring(1, raw.length - 1);
  if (quote == "'") {
    return inner;
  }
  final out = StringBuffer();
  for (var i = 0; i < inner.length; i++) {
    final char = inner[i];
    if (char == '\\' && i + 1 < inner.length) {
      final next = inner[i + 1];
      out.write(next == 'n' ? '\n' : next);
      i++;
      continue;
    }
    out.write(char);
  }
  return out.toString();
}

String _encode(String value) {
  if (_plainValue.hasMatch(value)) {
    return value;
  }
  final escaped = value
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n');
  return '"$escaped"';
}
