import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'sync_store.dart';

/// Login for the shop-computer page. The username and password come from
/// ADMIN_USER and ADMIN_PASSWORD when the server process starts.
class AdminGate {
  AdminGate({required this.user, required this.password});

  final String user;
  final String password;
  final Set<String> _sessions = {};
  final Random _random = Random.secure();

  bool get configured => user.isNotEmpty && password.isNotEmpty;

  bool allows(Request request) {
    final header = request.headers['cookie'] ?? '';
    for (final part in header.split(';')) {
      final piece = part.trim();
      if (!piece.startsWith('admin_session=')) {
        continue;
      }
      return _sessions.contains(piece.substring('admin_session='.length));
    }
    return false;
  }

  String? open(String submittedUser, String submittedPassword) {
    if (!configured || submittedUser != user || submittedPassword != password) {
      return null;
    }
    final token = List.generate(
      32,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join();
    _sessions.add(token);
    return token;
  }

  void close(Request request) {
    final header = request.headers['cookie'] ?? '';
    for (final part in header.split(';')) {
      final piece = part.trim();
      if (piece.startsWith('admin_session=')) {
        _sessions.remove(piece.substring('admin_session='.length));
      }
    }
  }
}

void mountAdmin(Router router, {required SyncStore store, required AdminGate gate}) {
  router
    ..get('/admin', (Request request) => _page(request, store, gate))
    ..post('/admin/login', (Request request) => _login(request, gate))
    ..post('/admin/logout', (Request request) => _logout(request, gate))
    ..post('/admin/email', (Request request) => _saveEmail(request, store, gate));
}

Response _page(Request request, SyncStore store, AdminGate gate) {
  if (!gate.configured) {
    return _html(
      _shell(
        'לוח ניהול',
        '<p>הגדירו ADMIN_USER ו-ADMIN_PASSWORD כשמפעילים את המחשב.</p>',
      ),
    );
  }
  if (!gate.allows(request)) {
    return _html(_loginForm(failed: request.url.queryParameters['error'] == '1'));
  }
  final sections = StringBuffer();
  final environments = store.environmentSummaries();
  if (environments.isEmpty) {
    sections.writeln('<p>עדיין אין סביבות. טאבלט מעלה נתונים אחרי הסנכרון הראשון.</p>');
  }
  for (final environment in environments) {
    final name = environment['name'] as String;
    final email = environment['owner_email'] as String? ?? '';
    final logs = store.logsFor(name);
    final rows = StringBuffer();
    if (logs.isEmpty) {
      rows.writeln('<p>אין תנועות בסביבה הזו.</p>');
    } else {
      rows.writeln('<ul>');
      for (final log in logs.reversed.take(20)) {
        final word = log.eventType == 'check_in' ? 'קליטה' : 'הוצאה';
        final temperature = log.temperature == null
            ? ''
            : ' ${log.temperature!.toStringAsFixed(1)}°C';
        rows.writeln(
          '<li>${_escape(_clock(log.occurredAt))} ${_escape(log.productName)} $word$temperature ${_escape(log.fridgeName)}</li>',
        );
      }
      rows.writeln('</ul>');
    }
    sections.writeln('''
<section>
  <h2>${_escape(name)}</h2>
  <p>${environment['logs']} תנועות שמורות במחשב. סביבה אחרת לא מוצגת כאן.</p>
  <form method="post" action="/admin/email">
    <input type="hidden" name="environment" value="${_escape(name)}">
    <label>אימייל הבעלים
      <input name="owner_email" type="email" value="${_escape(email)}" required>
    </label>
    <button type="submit">שמירת אימייל</button>
  </form>
  $rows
</section>
''');
  }
  return _html(
    _shell(
      'לוח ניהול',
      '''
<form method="post" action="/admin/logout"><button type="submit">יציאה</button></form>
$sections
''',
    ),
  );
}

Future<Response> _login(Request request, AdminGate gate) async {
  final form = await _form(request);
  final token = gate.open(form['user'] ?? '', form['password'] ?? '');
  if (token == null) {
    return _redirect('/admin?error=1');
  }
  return _redirect(
    '/admin',
    headers: {
      'set-cookie':
          'admin_session=$token; HttpOnly; Path=/admin; SameSite=Lax',
    },
  );
}

Response _logout(Request request, AdminGate gate) {
  gate.close(request);
  return _redirect(
    '/admin',
    headers: {'set-cookie': 'admin_session=; HttpOnly; Path=/admin; Max-Age=0'},
  );
}

Future<Response> _saveEmail(
  Request request,
  SyncStore store,
  AdminGate gate,
) async {
  if (!gate.allows(request)) {
    return _redirect('/admin');
  }
  final form = await _form(request);
  store.setOwnerEmail(form['environment'] ?? '', form['owner_email'] ?? '');
  return _redirect('/admin');
}

String _loginForm({required bool failed}) {
  final error = failed ? '<p class="error">שם המשתמש או הסיסמה שגויים.</p>' : '';
  return _shell(
    'כניסה ללוח הניהול',
    '''
$error
<form method="post" action="/admin/login">
  <label>שם משתמש <input name="user" autocomplete="username" required></label>
  <label>סיסמה <input name="password" type="password" autocomplete="current-password" required></label>
  <button type="submit">כניסה</button>
</form>
''',
  );
}

String _shell(String title, String body) {
  return '''
<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${_escape(title)}</title>
  <style>
    body { font-family: sans-serif; margin: 32px auto; max-width: 760px; line-height: 1.5; }
    section { border-top: 1px solid #ccc; margin-top: 24px; padding-top: 16px; }
    label { display: block; margin: 12px 0; }
    input { font-size: 18px; padding: 8px; width: 100%; max-width: 420px; }
    button { font-size: 18px; padding: 8px 16px; }
    .error { color: #8a1f1f; }
  </style>
</head>
<body>
  <h1>${_escape(title)}</h1>
  $body
</body>
</html>
''';
}

Future<Map<String, String>> _form(Request request) async {
  final raw = await request.readAsString();
  final parsed = Uri.splitQueryString(raw);
  return parsed.map((key, value) => MapEntry(key, value));
}

Response _html(String body) {
  return Response.ok(
    body,
    headers: {'content-type': 'text/html; charset=utf-8'},
  );
}

Response _redirect(String location, {Map<String, String> headers = const {}}) {
  return Response.found(location, headers: headers);
}

String _escape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

String _clock(DateTime instant) {
  final local = instant.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
