# Cooling-down

Tablet app, in Hebrew, for logging refrigerator check-in and check-out temperatures in commercial kitchens and pharmacies. Each confirm writes to SQLite on the tablet first. If the shop Wi-Fi is down, the row stays on the tablet and syncs when the shop computer is reachable again. The computer keeps the shared database and emails the owner at 00:00 with a report of the day that just ended.

Check-in and check-out stay separate rows. A log is never edited. If two tablets check the same item out, both temperatures are kept, an alert is recorded, and the earliest check-out is the one that closes the item.

Check-in, check-out, and the fridge list are three full-screen Hebrew tabs. The settings button on the top bar holds the computer address, token, and owner email. The daily report is fixed at midnight.

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

## One tablet shares with the others

Pick one tablet and leave Cooling down open on the shop Wi-Fi. In Settings, turn on "This tablet is the shared copy". The page shows an address such as `http://192.168.1.20:8080` and the access token. On every other tablet, iPhone or Android, enter that same environment name, that address, and that token. They push their logs and pull the shared tablet's record. A log is never overwritten.

The shared tablet has to stay on this app. Locking it or leaving the app stops sharing until it is opened again. Mailing the owner from that tablet needs the mail server fields in Settings and a Wi-Fi that can reach the internet. Without those fields, the report stays on the tablet.

## Shop computer

From `server/`:

```bash
dart pub get
SYNC_TOKEN=choose-a-long-secret dart run bin/server.dart
```

If `SYNC_TOKEN` is unset, the process writes `sync_token.txt` and prints the token once. Put that token, and `http://<server>:8080`, into Settings on each tablet. Use the same environment name on every tablet that should share one kitchen or pharmacy. Keep the server on a network you trust; the token stays on the tablet.

Email is off until these are set in the server process environment: `OWNER_EMAIL`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, and `SMTP_FROM`. `OWNER_EMAIL` is the address that receives the midnight report. It is saved on the computer, not on the tablets. Without the mail settings, the report is stored on the computer. Do not commit those values.

`PORT` defaults to 8080. `DATA_PATH` defaults to `cooling_down_server.sqlite`.

On each tablet, enter that address, the token, and that tablet's own environment name. Tablets do not copy each other's logs. The computer keeps each environment separately. The app bar shows that environment name. Settings stay locked until שינוי הגדרות is pressed. With no password saved, that opens editing directly. A password typed into סיסמה and saved is required the next time. Until then the computer address and access token stay hidden. The product list in Settings is what check-in search uses. לוח ניהול at the bottom of Settings opens `http://<server>:8080/admin`.

Set `ADMIN_USER` and `ADMIN_PASSWORD` when starting the computer. That page can change the owner email for one environment without touching another. At 00:00 the computer emails that environment's owner a Hebrew report of the previous day. If a tablet was offline, its rows stay on that tablet and upload on the next successful sync. The first successful email for a day wins.

## Layout

- `lib/presentation` — check-in, check-out, the fridge list, and settings
- `lib/domain` — product, log, alert, and report models
- `lib/data` — Drift database, repositories, and sync
- `server/` — optional shelf server for shared logs and owner email
- `backend/postgres/schema.sql` — PostgreSQL shape for a later Supabase project
