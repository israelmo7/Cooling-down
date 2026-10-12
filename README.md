# Cooling-down

Version 0.1. A Hebrew tablet logs refrigerator check-in and check-out. The shop computer keeps the archive and sends the midnight report. Each confirm writes to SQLite on the tablet first. If the shop Wi-Fi is down, the row stays on the tablet and syncs when the shop computer is reachable again. The computer keeps the shared database and emails the owner at 00:00 with a report of the day that just ended.

Check-in and check-out stay separate rows. A log is never edited. If two tablets check the same item out, both temperatures are kept, an alert is recorded, and the earliest check-out is the one that closes the item.

Check-in, check-out, and the fridge list are three full-screen Hebrew tabs. The settings button on the top bar holds the computer address and token. The owner email and the mail server are set on the shop computer. The daily report is fixed at midnight.

## Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Test

```bash
flutter analyze
flutter test
```

## Shop computer

The shop computer is the local server. Tablets upload to it. They do not share through another tablet.

From `server/`:

```bash
cp .env.example .env
dart pub get
dart run bin/server.dart
```

Fill `.env` before the first real run. `SYNC_TOKEN` is the tablet access token. `ADMIN_USER` and `ADMIN_PASSWORD` open `/admin`. If `SYNC_TOKEN` is empty, the process writes one into `.env` and prints it once. Put that token, and `http://<computer>:8080`, into Settings on each tablet. Use the same environment name on every tablet that should share one kitchen or pharmacy. Keep `.env` and `cooling_down_server.sqlite` on that computer. Do not commit them.

`PORT` defaults to 8080. `DATA_PATH` defaults to `cooling_down_server.sqlite`. A process variable with the same name overrides the file.

The mail fields in `.env` are `OWNER_EMAIL`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, and `SMTP_FROM`. `/admin` can change those and writes them back to `.env`, so a restart keeps the change. `OWNER_EMAIL` is the default owner address. Each environment on that page can have its own address. A place that already has a different address is left as it is. Without the mail server fields, the report is stored on the computer.

On each tablet, enter that address, the token, and that tablet's own environment name. Tablets do not copy each other's logs. The computer keeps each environment separately. The app bar shows that environment name. Settings stay locked until שינוי הגדרות is pressed. A blank סיסמה means no password, and saving it blank clears one. Any password saved there is required the next time. Until then the computer address and access token stay hidden. The product list in Settings is what check-in search uses. לוח ניהול at the bottom of Settings opens `http://<server>:8080/admin`.

At 00:00 the computer emails that environment's owner a Hebrew report of the previous day. If a tablet was offline, its rows stay on that tablet and upload on the next successful sync. The first successful email for a day wins.

## Layout

- `lib/presentation` — check-in, check-out, the fridge list, and settings
- `lib/domain` — product, log, alert, and report models
- `lib/data` — Drift database, repositories, and sync
- `server/` — shop computer: sync, admin page, and midnight email
