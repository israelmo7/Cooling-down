import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

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

/// Settings the shop file is allowed to write. Anything else in the JSON is kept
/// for the reader and is not copied into `.env`.
const shopSettingKeys = <String>[
  'SYNC_TOKEN',
  'ADMIN_USER',
  'ADMIN_PASSWORD',
  'OWNER_EMAIL',
  'SMTP_HOST',
  'SMTP_PORT',
  'SMTP_USER',
  'SMTP_PASSWORD',
  'SMTP_FROM',
  'TZ',
];

/// Copies [shopFile] into [envFile].
///
/// An empty `SYNC_TOKEN` keeps a token already stored in `.env`, or creates one
/// and writes it back into [shopFile]. Any other empty value is written as
/// empty, so clearing a field in the JSON clears it in `.env`.
void applyShopJson({required File shopFile, required File envFile}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(shopFile.readAsStringSync());
  } on FormatException {
    throw const FormatException('shop.json is not valid JSON.');
  }
  if (decoded is! Map) {
    throw const FormatException('shop.json must be a JSON object.');
  }

  final existing = loadEnvFile(envFile);
  final updates = <String, String>{};
  String? tokenToRemember;
  for (final key in shopSettingKeys) {
    if (!decoded.containsKey(key)) {
      continue;
    }
    final raw = decoded[key];
    if (raw != null && raw is! String && raw is! num) {
      throw FormatException('$key in shop.json must be text.');
    }
    var value = raw == null ? '' : '$raw';
    if (key == 'SMTP_PORT' && value.trim().isEmpty) {
      value = '587';
    }
    if (key == 'TZ' && value.trim().isEmpty) {
      value = 'Asia/Jerusalem';
    }
    if (key == 'SYNC_TOKEN' && value.trim().isEmpty) {
      final kept = existing['SYNC_TOKEN']?.trim() ?? '';
      if (kept.isNotEmpty) {
        tokenToRemember = kept;
        continue;
      }
      final created = const Uuid().v4();
      tokenToRemember = created;
      value = created;
    }
    updates[key] = value;
  }

  if (!envFile.existsSync()) {
    envFile.parent.createSync(recursive: true);
    envFile.writeAsStringSync('# Written from shop.json.\n');
  }
  writeEnvKeys(envFile, updates);
  if (tokenToRemember != null) {
    rememberShopToken(shopFile, tokenToRemember);
  }
}

/// Fills an empty `SYNC_TOKEN` in [shopFile] so the edited file shows the token.
void rememberShopToken(File shopFile, String token) {
  final trimmed = token.trim();
  if (!shopFile.existsSync() || trimmed.isEmpty) {
    return;
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(shopFile.readAsStringSync());
  } on FormatException {
    return;
  }
  if (decoded is! Map) {
    return;
  }
  final current = decoded['SYNC_TOKEN'];
  final text = current == null ? '' : current.toString().trim();
  if (text.isNotEmpty) {
    return;
  }
  decoded['SYNC_TOKEN'] = trimmed;
  shopFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(decoded)}\n',
  );
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
