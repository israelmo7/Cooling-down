# Cooling-down

Tablet app for logging refrigerator check-in and check-out temperatures in commercial kitchens and pharmacies. Each confirm writes to SQLite first. The tablet works with no network. A server is optional: several tablets that share an environment name and access token push their logs and pull everyone else's.

Check-in and check-out stay separate rows. A log is never edited. If two tablets check the same item out, both temperatures are kept, an alert is recorded, and the earliest check-out is the one that closes the item.

Check-in, check-out, and the fridge list are three full-screen tabs. The settings button on the top bar holds the server address, token, owner email, and the end-of-day report time.

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

## Optional computer server

From `server/`:

```bash
dart pub get
SYNC_TOKEN=choose-a-long-secret dart run bin/server.dart
```

If `SYNC_TOKEN` is unset, the process writes `sync_token.txt` and prints the token once. Put that token, and `http://<server>:8080`, into Settings on each tablet. Use the same environment name on every tablet that should share one kitchen or pharmacy. Keep the server on a network you trust; the token stays on the tablet.

Email is off until these are set in the server process environment: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, and `SMTP_FROM`. Without them, the report is stored and the tablet says email is not set up. Do not commit those values.

`PORT` defaults to 8080. `DATA_PATH` defaults to `cooling_down_server.sqlite`.

On the tablet, turn on "Email a report at the end of each day" and set the local time. After that time the tablet syncs, writes what happened, and asks the server to email the owner. "Send today's report" does the same immediately. The first successful email for a day wins; a second tablet gets "already emailed".

## Layout

- `lib/presentation` — check-in, check-out, the fridge list, and settings
- `lib/domain` — product, log, alert, and report models
- `lib/data` — Drift database, repositories, and sync
- `server/` — optional shelf server for shared logs and owner email
- `backend/postgres/schema.sql` — PostgreSQL shape for a later Supabase project
