import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'daily_mail.dart';
import 'env_file.dart';
import 'mailer.dart';
import 'report_time.dart';
import 'server_config.dart';
import 'sync_store.dart';

/// Login for the shop-computer page. The username and password come from
/// ADMIN_USER and ADMIN_PASSWORD. The page can change them and write them back.
class AdminGate {
  AdminGate({required this.user, required this.password});

  String user;
  String password;
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

  void replace({required String user, required String password}) {
    this.user = user;
    this.password = password;
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

void mountAdmin(
  Router router, {
  required SyncStore store,
  required AdminGate gate,
  required MailSettings mail,
  File? envFile,
  File? shopFile,
  File? reportFile,
  ShopSchedule? schedule,
  void Function()? onScheduleChanged,
}) {
  final clock = schedule ?? ShopSchedule();
  router
    ..get(
      '/admin',
      (Request request) => _page(request, store, gate, mail, clock, reportFile),
    )
    ..post('/admin/login', (Request request) => _login(request, gate))
    ..post('/admin/logout', (Request request) => _logout(request, gate))
    ..post(
      '/admin/mail',
      (Request request) =>
          _saveMail(request, store, gate, mail, envFile, shopFile),
    )
    ..post(
      '/admin/access',
      (Request request) => _saveAccess(request, gate, envFile, shopFile),
    )
    ..post(
      '/admin/clock',
      (Request request) => _saveClock(
        request,
        gate,
        clock,
        envFile,
        shopFile,
        onScheduleChanged,
      ),
    )
    ..post(
      '/admin/report',
      (Request request) => _saveReport(
        request,
        gate,
        clock,
        envFile,
        shopFile,
        onScheduleChanged,
      ),
    );
}

Response _page(
  Request request,
  SyncStore store,
  AdminGate gate,
  MailSettings mail,
  ShopSchedule schedule,
  File? reportFile,
) {
  if (!gate.configured) {
    return _html(
      _shell(
        'לוח ניהול',
        '<p>הגדירו ADMIN_USER ו-ADMIN_PASSWORD בקובץ shop.json.</p>',
      ),
    );
  }
  if (!gate.allows(request)) {
    return _html(
      _loginForm(failed: request.url.queryParameters['error'] == '1'),
    );
  }
  final notice = switch (request.url.queryParameters['notice']) {
    'saved' => '<p>הגדרות הדואר נשמרו.</p>',
    'mail' => '<p class="error">בדקו את כתובת האימייל.</p>',
    'access' => '<p>פרטי הכניסה נשמרו.</p>',
    'clock' => '<p>השעון נשמר.</p>',
    'clock-error' => '<p class="error">בדקו את אזור הזמן ואת שעת הדוח.</p>',
    'report' => '<p>בחירת הדוח נשמרה.</p>',
    _ => '',
  };
  final sections = StringBuffer()
    ..writeln(notice)
    ..writeln(_accessForm(gate))
    ..writeln(_clockForm(schedule))
    ..writeln(_reportForm(schedule, reportFile))
    ..writeln(_mailForm(mail));
  final environments = store.environmentSummaries();
  if (environments.isEmpty) {
    sections.writeln(
      '<p>עדיין אין סביבות. טאבלט מעלה נתונים אחרי הסנכרון הראשון.</p>',
    );
  }
  for (final environment in environments) {
    final name = environment['name'] as String;
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
            : ' ${_ltr('${log.temperature!.toStringAsFixed(1)}°C')}';
        final worker = log.workerName.trim().isEmpty
            ? ''
            : ' · ${_escape(log.workerName.trim())}';
        rows.writeln(
          '<li>${_escape(_clock(log.occurredAt))} ${_escape(log.productName)} $word$temperature ${_escape(log.fridgeName)}$worker</li>',
        );
      }
      rows.writeln('</ul>');
    }
    sections.writeln('''
<section>
  <h2>${_escape(name)}</h2>
  <p>${environment['logs']} תנועות שמורות במחשב. סביבה אחרת לא מוצגת כאן.</p>
  $rows
</section>
''');
  }
  return _html(
    _shell('לוח ניהול', '''
<form method="post" action="/admin/logout"><button type="submit">יציאה</button></form>
$sections
'''),
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
      'set-cookie': 'admin_session=$token; HttpOnly; Path=/admin; SameSite=Lax',
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

Future<Response> _saveMail(
  Request request,
  SyncStore store,
  AdminGate gate,
  MailSettings mail,
  File? envFile,
  File? shopFile,
) async {
  if (!gate.allows(request)) {
    return _redirect('/admin');
  }
  final form = await _form(request);
  final ownerEmail = (form['owner_email'] ?? '').trim();
  if (ownerEmail.isNotEmpty && !ownerEmail.contains('@')) {
    return _redirect('/admin?notice=mail');
  }
  mail.ownerEmail = ownerEmail;
  _writeBoth(envFile, shopFile, {'OWNER_EMAIL': ownerEmail});
  store.setDefaultOwnerEmail(ownerEmail);
  return _redirect('/admin?notice=saved');
}

Future<Response> _saveAccess(
  Request request,
  AdminGate gate,
  File? envFile,
  File? shopFile,
) async {
  if (!gate.allows(request)) {
    return _redirect('/admin');
  }
  final form = await _form(request);
  final user = (form['admin_user'] ?? '').trim();
  final password = form['admin_password'] ?? '';
  gate.replace(user: user, password: password);
  _writeBoth(envFile, shopFile, {
    'ADMIN_USER': user,
    'ADMIN_PASSWORD': password,
  });
  return _redirect('/admin?notice=access');
}

Future<Response> _saveClock(
  Request request,
  AdminGate gate,
  ShopSchedule schedule,
  File? envFile,
  File? shopFile,
  void Function()? onScheduleChanged,
) async {
  if (!gate.allows(request)) {
    return _redirect('/admin');
  }
  final form = await _form(request);
  final zone = (form['time_zone'] ?? '').trim();
  final rawTime = form['report_time'] ?? '';
  final time = tryParseReportTime(rawTime);
  if (!_zoneIsValid(zone) || time == null || !rawTime.contains(':')) {
    return _redirect('/admin?notice=clock-error');
  }
  schedule.replaceClock(timeZone: zone, reportTime: time);
  _writeBoth(envFile, shopFile, {'TZ': zone, 'REPORT_TIME': time.text});
  onScheduleChanged?.call();
  return _redirect('/admin?notice=clock');
}

Future<Response> _saveReport(
  Request request,
  AdminGate gate,
  ShopSchedule schedule,
  File? envFile,
  File? shopFile,
  void Function()? onScheduleChanged,
) async {
  if (!gate.allows(request)) {
    return _redirect('/admin');
  }
  final form = await _form(request);
  final format = normalizeReportFormat(form['report_format'] ?? '');
  schedule.replaceFormat(format);
  _writeBoth(envFile, shopFile, {'REPORT_FORMAT': format});
  onScheduleChanged?.call();
  return _redirect('/admin?notice=report');
}

bool _zoneIsValid(String zone) {
  return RegExp(r'^[A-Za-z0-9_+/-]+$').hasMatch(zone);
}

void _writeBoth(File? envFile, File? shopFile, Map<String, String> updates) {
  if (envFile != null) {
    writeEnvKeys(envFile, updates);
  }
  if (shopFile != null) {
    writeShopKeys(shopFile, updates);
  }
}

String _ltr(String value) => '\u2066$value\u2069';

String _accessForm(AdminGate gate) {
  return '''
<section>
  <h2>כניסה</h2>
  <p>אפשר לשנות גם מכאן וגם בקובץ shop.json. האסימון נשאר בקובץ.</p>
  <form method="post" action="/admin/access">
    <label>שם משתמש
      <input name="admin_user" value="${_escape(gate.user)}" autocomplete="username">
    </label>
    <label>סיסמה
      <input name="admin_password" type="password" value="${_escape(gate.password)}" autocomplete="new-password">
    </label>
    <button type="submit">שמירת הכניסה</button>
  </form>
</section>
''';
}

String _clockForm(ShopSchedule schedule) {
  return '''
<section>
  <h2>שעון</h2>
  <p>הדוח יוצא פעם אחת בשעה הזו. אזור הזמן נכנס לתוקף בהפעלה הבאה.</p>
  <form method="post" action="/admin/clock">
    <label>אזור זמן
      <input name="time_zone" value="${_escape(schedule.timeZone)}">
    </label>
    <label>שעת הדוח
      <input name="report_time" type="text" inputmode="numeric" dir="ltr" value="${schedule.reportTime.text}" placeholder="18:30" pattern="[0-9]{1,2}:[0-9]{2}" required>
    </label>
    <button type="submit">שמירת השעון</button>
  </form>
</section>
''';
}

String _reportForm(ShopSchedule schedule, File? reportFile) {
  final builtin = schedule.reportFormat == 'builtin' ? ' checked' : '';
  final custom = schedule.reportFormat == 'custom' ? ' checked' : '';
  final text = _reportText(reportFile);
  final file = text.isEmpty
      ? '<p>אין קובץ report.txt. בלי הקובץ נשלח הדוח הקבוע.</p>'
      : '<pre>${_escape(text)}</pre>';
  return '''
<section>
  <h2>דוח</h2>
  <form method="post" action="/admin/report">
    <label><input type="radio" name="report_format" value="builtin"$builtin> הדוח הקבוע</label>
    <pre>$builtInReportHeading</pre>
    <label><input type="radio" name="report_format" value="custom"$custom> הקובץ report.txt</label>
    $file
    <p>{{environment}} {{date}} {{rows}} … {{/rows}} {{product}} {{check_in}} {{check_in_time}} {{check_out}} {{check_out_time}} {{notes}} {{conclusion}}</p>
    <button type="submit">שמירת הדוח</button>
  </form>
</section>
''';
}

String _reportText(File? reportFile) {
  if (reportFile == null || !reportFile.existsSync()) {
    return '';
  }
  return reportFile.readAsStringSync();
}

String _mailForm(MailSettings mail) {
  final state = mail.emailEnabled ? 'הדואר פעיל.' : 'הדואר כבוי.';
  return '''
<section>
  <h2>דואר</h2>
  <p>$state תיבת השליחה נשארת בקובץ shop.json. הדוח נשלח לכתובת הזו.</p>
  <form method="post" action="/admin/mail">
    <label>אימייל הבעלים
      <input name="owner_email" type="email" value="${_escape(mail.ownerEmail)}">
    </label>
    <button type="submit">שמירת הדואר</button>
  </form>
</section>
''';
}

String _loginForm({required bool failed}) {
  final error = failed
      ? '<p class="error">שם המשתמש או הסיסמה שגויים.</p>'
      : '';
  return _shell('כניסה ללוח הניהול', '''
$error
<form method="post" action="/admin/login">
  <label>שם משתמש <input name="user" autocomplete="username" required></label>
  <label>סיסמה <input name="password" type="password" autocomplete="current-password" required></label>
  <button type="submit">כניסה</button>
</form>
''');
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
