import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'daily_mail.dart';
import 'env_file.dart';
import 'mailer.dart';
import 'report_layout.dart';
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
      '/admin/save',
      (Request request) => _save(
        request,
        store,
        gate,
        mail,
        clock,
        envFile,
        shopFile,
        onScheduleChanged,
      ),
    )
    ..post(
      '/admin/test-report',
      (Request request) =>
          _sendTest(request, store, gate, mail, clock, reportFile),
    )
    ..post(
      '/admin/report',
      (Request request) =>
          _saveReport(request, gate, clock, envFile, shopFile, reportFile),
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
  final tab = _tab(request);
  final notice = _notice(request.url.queryParameters['notice']);
  final body = switch (tab) {
    'places' => _places(store),
    'report' => _reportBuilder(schedule, reportFile),
    _ => _settings(gate, mail, schedule),
  };
  return _html(
    _shell('', '''
${_bar(tab: tab)}
$notice
$body
'''),
  );
}

String _tab(Request request) {
  return switch (request.url.queryParameters['tab']) {
    'places' => 'places',
    'report' => 'report',
    _ => 'settings',
  };
}

String _notice(String? code) {
  final text = switch (code) {
    'saved' => 'ההגדרות נשמרו.',
    'mail' => 'בדקו את כתובת האימייל.',
    'access' => 'מלאו שם משתמש וסיסמה.',
    'time' => 'שעת הדוח צריכה להיות בשעה כמו 18:30.',
    'zone' => 'אזור הזמן לא תקין.',
    'test-ok' => 'נשלח דוח הבדיקה של היום.',
    'test-stored' => 'דוח הבדיקה נשמר. הדואר כבוי, אז הוא לא יצא.',
    'test-mail' => 'הגדירו אימייל בעלים לפני שליחת הדוח.',
    'test-empty' => 'אין סביבה לשלוח לה דוח.',
    'test-already' => 'דוח הבדיקה של היום כבר נשלח.',
    'test-failed' => 'שליחת הדוח נכשלה.',
    _ => '',
  };
  if (text.isEmpty) {
    return '';
  }
  final kind = code == 'saved' || code == 'test-ok' || code == 'test-stored'
      ? 'ok'
      : 'error';
  return '<p class="notice $kind">$text</p>';
}

String _bar({required String tab}) {
  String mark(String name) => tab == name ? ' class="on"' : '';
  return '''
<header class="bar">
  <strong>לוח ניהול</strong>
  <nav>
    <a href="/admin"${mark('settings')}>הגדרות</a>
    <a href="/admin?tab=report"${mark('report')}>דוח</a>
    <a href="/admin?tab=places"${mark('places')}>סביבות</a>
  </nav>
  <form method="post" action="/admin/logout"><button type="submit">יציאה</button></form>
</header>
''';
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

Future<Response> _save(
  Request request,
  SyncStore store,
  AdminGate gate,
  MailSettings mail,
  ShopSchedule schedule,
  File? envFile,
  File? shopFile,
  void Function()? onScheduleChanged,
) async {
  if (!gate.allows(request)) {
    return _redirect('/admin');
  }
  final form = await _form(request);
  final user = (form['admin_user'] ?? '').trim();
  final password = form['admin_password'] ?? '';
  final zone = (form['time_zone'] ?? '').trim();
  final rawTime = (form['report_time'] ?? '').trim();
  final ownerEmail = (form['owner_email'] ?? '').trim();
  final time = _clockField(rawTime);
  if (user.isEmpty || password.isEmpty) {
    return _redirect('/admin?notice=access');
  }
  if (!_zoneIsValid(zone)) {
    return _redirect('/admin?notice=zone');
  }
  if (time == null) {
    return _redirect('/admin?notice=time');
  }
  if (ownerEmail.isNotEmpty && !ownerEmail.contains('@')) {
    return _redirect('/admin?notice=mail');
  }
  final submittedFormat = form['report_format'];
  final format = submittedFormat == null
      ? schedule.reportFormat
      : normalizeReportFormat(submittedFormat);
  gate.replace(user: user, password: password);
  mail.ownerEmail = ownerEmail;
  schedule.replaceClock(timeZone: zone, reportTime: time);
  schedule.replaceFormat(format);
  _writeBoth(envFile, shopFile, {
    'ADMIN_USER': user,
    'ADMIN_PASSWORD': password,
    'TZ': zone,
    'REPORT_TIME': time.text,
    'REPORT_FORMAT': format,
    'OWNER_EMAIL': ownerEmail,
  });
  store.setDefaultOwnerEmail(ownerEmail);
  onScheduleChanged?.call();
  return _redirect('/admin?notice=saved');
}

Future<Response> _sendTest(
  Request request,
  SyncStore store,
  AdminGate gate,
  MailSettings mail,
  ShopSchedule schedule,
  File? reportFile,
) async {
  if (!gate.allows(request)) {
    return _redirect('/admin');
  }
  if (!mail.ownerEmail.contains('@')) {
    return _redirect('/admin?notice=test-mail');
  }
  if (store.environmentSummaries().isEmpty) {
    return _redirect('/admin?notice=test-empty');
  }
  final template = _reportText(reportFile);
  final statuses = await store.sendDay(
    DateTime.now(),
    reportFormat: schedule.reportFormat,
    template: template,
    force: true,
  );
  final notice = _testNotice(statuses);
  return _redirect('/admin?notice=$notice');
}

String _testNotice(List<String> statuses) {
  if (statuses.isEmpty) {
    return 'test-already';
  }
  if (statuses.any((status) => status == 'failed')) {
    return 'test-failed';
  }
  if (statuses.any((status) => status == 'sent')) {
    return 'test-ok';
  }
  return 'test-stored';
}

/// A clock typed as `18:30`. Hour-only and out-of-range values are rejected.
ReportTime? _clockField(String raw) {
  if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(raw)) {
    return null;
  }
  return tryParseReportTime(raw);
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

String _settings(AdminGate gate, MailSettings mail, ShopSchedule schedule) {
  final state = mail.emailEnabled ? 'הדואר פעיל.' : 'הדואר כבוי.';
  final reportName = schedule.reportFormat == 'custom'
      ? 'טבלה שנבחרה'
      : 'הדוח הקבוע';
  return '''
<form method="post" action="/admin/save" class="card">
  <section>
    <h2>כניסה</h2>
    <p class="hint">אפשר לשנות גם מכאן וגם בקובץ shop.json. האסימון נשאר בקובץ.</p>
    <label>שם משתמש
      <input name="admin_user" value="${_escape(gate.user)}" autocomplete="username" required>
    </label>
    <label>סיסמה
      <input name="admin_password" type="password" value="${_escape(gate.password)}" autocomplete="new-password" required>
    </label>
  </section>
  <section>
    <h2>שעון</h2>
    <p class="hint">הדוח יוצא פעם אחת בשעה הזו. אזור הזמן נכנס לתוקף בהפעלה הבאה.</p>
    <label>אזור זמן
      <input name="time_zone" value="${_escape(schedule.timeZone)}" dir="ltr" required>
    </label>
    <label>שעת הדוח
      <input name="report_time" type="text" inputmode="numeric" dir="ltr" value="${schedule.reportTime.text}" placeholder="18:30" pattern="[0-9]{1,2}:[0-9]{2}" required>
    </label>
  </section>
  <section>
    <h2>דוח</h2>
    <p class="hint">עכשיו נשלח $reportName. את העמודות בוחרים בלשונית דוח.</p>
  </section>
  <section>
    <h2>דואר</h2>
    <p class="hint">$state תיבת השליחה נשארת בקובץ shop.json. הדוח נשלח לכתובת הזו.</p>
    <label>אימייל הבעלים
      <input name="owner_email" type="email" dir="ltr" value="${_escape(mail.ownerEmail)}">
    </label>
  </section>
  <button type="submit" class="primary">שמירה</button>
</form>
<form method="post" action="/admin/test-report" class="card test">
  <h2>בדיקת הדוח</h2>
  <p class="hint">שולח שוב את תנועות היום. זה לא סוגר את הדוח הקבוע של אתמול.</p>
  <button type="submit">שליחת דוח לבדיקה</button>
</form>
''';
}

Future<Response> _saveReport(
  Request request,
  AdminGate gate,
  ShopSchedule schedule,
  File? envFile,
  File? shopFile,
  File? reportFile,
) async {
  if (!gate.allows(request)) {
    return _redirect('/admin');
  }
  final form = await _form(request);
  final custom = form['layout'] == 'custom';
  if (custom && reportFile != null) {
    final columns = ReportColumns(
      checkIn: form.containsKey('col_check_in'),
      checkInTime: form.containsKey('col_check_in_time'),
      checkOut: form.containsKey('col_check_out'),
      checkOutTime: form.containsKey('col_check_out_time'),
      notes: form.containsKey('col_notes'),
      conclusion: form.containsKey('col_conclusion'),
    );
    reportFile.parent.createSync(recursive: true);
    reportFile.writeAsStringSync(columns.toTemplate());
  }
  final format = custom ? 'custom' : 'builtin';
  schedule.replaceFormat(format);
  _writeBoth(envFile, shopFile, {'REPORT_FORMAT': format});
  return _redirect('/admin?tab=report&notice=saved');
}

String _reportBuilder(ShopSchedule schedule, File? reportFile) {
  final custom = schedule.reportFormat == 'custom';
  final columns = custom
      ? ReportColumns.fromTemplate(_reportText(reportFile))
      : ReportColumns.fixed;
  final builtin = custom ? '' : ' checked';
  final chosen = custom ? ' checked' : '';
  String box(String name, String label, bool on) {
    final checked = on ? ' checked' : '';
    return '<label class="choice"><input type="checkbox" name="$name" value="1"$checked> $label</label>';
  }

  String cell(String column, String text, {bool head = false}) {
    final tag = head ? 'th' : 'td';
    return '<$tag data-col="$column">$text</$tag>';
  }

  return '''
<form method="post" action="/admin/report" class="card" id="report-layout">
  <h2>מבנה הדוח</h2>
  <p class="hint">בחרו מה הבעלים רואה. שם המוצר תמיד בטבלה. השמירה כותבת את הטבלה, בלי לערוך קובץ.</p>
  <label class="choice"><input type="radio" name="layout" value="builtin"$builtin> הדוח הקבוע</label>
  <label class="choice"><input type="radio" name="layout" value="custom"$chosen> טבלה לפי הסימונים</label>
  <div class="cols">
    ${box('col_check_in', 'איך נקלט', columns.checkIn)}
    ${box('col_check_in_time', 'מתי נקלט', columns.checkInTime)}
    ${box('col_check_out', 'איך הוצא', columns.checkOut)}
    ${box('col_check_out_time', 'מתי הוצא', columns.checkOutTime)}
    ${box('col_notes', 'הערות', columns.notes)}
    ${box('col_conclusion', 'מסקנה', columns.conclusion)}
  </div>
  <h2>תצוגה</h2>
  <table class="preview">
    <thead><tr>
      ${cell('product', 'מוצר', head: true)}
      ${cell('check_in', 'איך נקלט', head: true)}
      ${cell('check_in_time', 'מתי נקלט', head: true)}
      ${cell('check_out', 'איך הוצא', head: true)}
      ${cell('check_out_time', 'מתי הוצא', head: true)}
    </tr></thead>
    <tbody><tr>
      ${cell('product', 'חלב')}
      ${cell('check_in', '4.0°C · דנה · מטבח')}
      ${cell('check_in_time', '15:04')}
      ${cell('check_out', '—')}
      ${cell('check_out_time', '—')}
    </tr></tbody>
  </table>
  <p class="hint" data-col="notes">הערות: אין אזהרות.</p>
  <p class="hint" data-col="conclusion">מסקנה: היום נסגר לפי מה שכבר הגיע למחשב.</p>
  <button type="submit" class="primary">שמירת המבנה</button>
</form>
<script>
(function () {
  var form = document.getElementById('report-layout');
  if (!form) return;
  function shown(name) {
    var custom = form.querySelector('input[name="layout"][value="custom"]').checked;
    if (!custom || name === 'product') return true;
    var box = form.querySelector('input[name="col_' + name + '"]');
    return !box || box.checked;
  }
  function sync() {
    var custom = form.querySelector('input[name="layout"][value="custom"]').checked;
    form.querySelectorAll('input[type="checkbox"]').forEach(function (box) {
      box.disabled = !custom;
    });
    form.querySelectorAll('[data-col]').forEach(function (cell) {
      cell.hidden = !shown(cell.getAttribute('data-col'));
    });
  }
  form.addEventListener('change', sync);
  sync();
})();
</script>
''';
}

String _places(SyncStore store) {
  final environments = store.environmentSummaries();
  if (environments.isEmpty) {
    return '<section class="card"><p>עדיין אין סביבות. טאבלט מעלה נתונים אחרי הסנכרון הראשון.</p></section>';
  }
  final sections = StringBuffer();
  for (final environment in environments) {
    final name = environment['name'] as String;
    final logs = store.logsFor(name);
    final rows = StringBuffer();
    if (logs.isEmpty) {
      rows.writeln('<p class="hint">אין תנועות בסביבה הזו.</p>');
    } else {
      final ordered = [...logs]
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      final shown = ordered.take(recentActionLimit).toList();
      rows.writeln(
        '<p class="hint">מוצגות ${shown.length} התנועות האחרונות מתוך ${ordered.length}. הרשימה נעצרת ב-$recentActionLimit.</p>',
      );
      rows.writeln('<ul>');
      for (final log in shown) {
        final word = log.eventType == 'check_in'
            ? 'קליטה'
            : log.eventType == 'check_out'
            ? 'הוצאה'
            : _escape(log.eventType);
        final temperature = log.temperature == null
            ? ''
            : ' ${_ltr('${log.temperature!.toStringAsFixed(1)}°C')}';
        final worker = log.workerName.trim().isEmpty
            ? ''
            : ' · ${_escape(log.workerName.trim())}';
        rows.writeln(
          '<li>${_escape(_stamp(log.occurredAt))} ${_escape(log.productName)} $word$temperature ${_escape(log.fridgeName)}$worker</li>',
        );
      }
      rows.writeln('</ul>');
    }
    sections.writeln('''
<section class="card">
  <h2>${_escape(name)}</h2>
  <p class="hint">${environment['logs']} תנועות שמורות במחשב.</p>
  $rows
</section>
''');
  }
  return sections.toString();
}

String _reportText(File? reportFile) {
  if (reportFile == null || !reportFile.existsSync()) {
    return '';
  }
  return reportFile.readAsStringSync();
}

String _loginForm({required bool failed}) {
  final error = failed
      ? '<p class="error">שם המשתמש או הסיסמה שגויים.</p>'
      : '';
  return _shell('כניסה ללוח הניהול', '''
<section class="card">
$error
<form method="post" action="/admin/login">
  <label>שם משתמש <input name="user" autocomplete="username" required></label>
  <label>סיסמה <input name="password" type="password" autocomplete="current-password" required></label>
  <button type="submit" class="primary">כניסה</button>
</form>
</section>
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
    body { font-family: sans-serif; margin: 0 auto 48px; max-width: 820px; line-height: 1.5; color: #16343a; background: #f3f6f6; }
    h1 { margin: 28px 20px 8px; }
    .bar { display: flex; align-items: center; gap: 16px; padding: 14px 20px; background: #16343a; color: white; }
    .bar strong { font-size: 20px; }
    .bar nav { display: flex; gap: 8px; margin-inline-start: auto; }
    .bar a { color: white; text-decoration: none; padding: 8px 12px; border-radius: 8px; }
    .bar a.on { background: white; color: #16343a; }
    .bar button { background: transparent; color: white; border: 1px solid rgba(255,255,255,.4); }
    .card { background: white; margin: 16px 20px; padding: 8px 20px 20px; border-radius: 12px; }
    section { border-top: 1px solid #e2e8e8; margin-top: 8px; padding-top: 8px; }
    section:first-child { border-top: 0; }
    label { display: block; margin: 12px 0; }
    label.choice { margin: 8px 0; }
    input { font-size: 18px; padding: 8px 10px; width: 100%; max-width: 420px; box-sizing: border-box; }
    input[dir="ltr"] { text-align: left; }
    button { font-size: 18px; padding: 10px 16px; border-radius: 8px; border: 1px solid #c5d0d0; background: white; }
    button.primary { background: #16343a; color: white; border-color: #16343a; min-width: 160px; }
    .test { display: flex; flex-wrap: wrap; align-items: center; gap: 12px 20px; }
    .test h2, .test p { margin: 0; }
    .hint { color: #4d6468; }
    .notice { margin: 16px 20px; padding: 12px 16px; border-radius: 10px; }
    .notice.ok { background: #e7f6ec; color: #166534; }
    .notice.error, .error { background: #fde8e8; color: #8a1f1f; }
    .error { padding: 12px 16px; border-radius: 10px; }
    pre { white-space: pre-wrap; background: #f7fafa; padding: 12px; border-radius: 8px; }
    .cols { display: grid; grid-template-columns: 1fr 1fr; gap: 4px 16px; margin: 12px 0; }
    table.preview { width: 100%; border-collapse: collapse; margin: 8px 0 16px; }
    table.preview th, table.preview td { border: 1px solid #d7e0e4; padding: 8px 10px; text-align: right; }
    table.preview th { background: #eef3f5; }
    ul { padding-inline-start: 20px; }
  </style>
</head>
<body>
  ${title.isEmpty ? '' : '<h1>${_escape(title)}</h1>'}
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

String _stamp(DateTime instant) {
  final local = instant.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month ${_clock(instant)}';
}
