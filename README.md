# Cooling-down

Version 0.1. A Hebrew tablet logs refrigerator check-in and check-out. The shop computer keeps the archive and sends the midnight report. Each confirm writes to SQLite on the tablet first. If the shop Wi-Fi is down, the row stays on the tablet and syncs when the shop computer is reachable again. The computer keeps the shared database and emails the owner at 00:00 with a report of the day that just ended.

Check-in and check-out stay separate rows. A log is never edited. If two tablets check the same item out, both temperatures are kept, an alert is recorded, and the earliest check-out is the one that closes the item.

Check-in, check-out, and the fridge list are three full-screen Hebrew tabs. The settings button on the top bar holds the computer address and token. The owner email and the mail server are set on the shop computer. The daily report is fixed at midnight.

## Run

From `tablet/`:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Test

From `tablet/`:

```bash
flutter analyze
flutter test
```

## Shop computer

The shop computer is the local server. Tablets upload to it over the shop Wi-Fi, at `http://<computer>:8080`. They do not use SSH, and they do not share through another tablet.

To try it on a machine that already has Dart, from `server/`:

```bash
cp .env.example .env
dart pub get
dart run bin/server.dart
```

## Field install

From your own machine, with Docker installed and an SSH login to the shop computer:

```bash
tools/deploy.sh user@shop-pc
```

That builds the image in `server/`, copies it over SSH, and starts one container with `tools/docker-compose.yml`. The shop computer needs Docker. It does not need Dart. The database and `.env` stay in `~/cooling-down/data/` on that computer, so a later run of the script keeps them.

`tools/deploy.sh --build-only` builds the image and does not contact the shop computer. Build it on a machine with the same chip as the shop PC.

Fill `data/.env` before tablets connect. `SYNC_TOKEN` is the tablet access token. `ADMIN_USER` and `ADMIN_PASSWORD` open `/admin`. If `SYNC_TOKEN` is empty, the process writes one into `.env` and prints it once. After you edit the file, recreate the container so it reads the new values:

```bash
ssh user@shop-pc 'cd ~/cooling-down && docker compose up -d --force-recreate'
```

The mail fields are `OWNER_EMAIL`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, and `SMTP_FROM`. `/admin` can change those and writes them back to `.env`. `OWNER_EMAIL` is the default owner address. Each environment on that page can have its own address. A place that already has a different address is left as it is. Without the mail server fields, the report is stored on the computer. The container clock is `Asia/Jerusalem`. Change `TZ` in `tools/docker-compose.yml` when the shop is in another zone, then run the deploy script again.

On each tablet, enter that address, the token, and that tablet's own environment name. Tablets do not copy each other's logs. The computer keeps each environment separately. The app bar shows that environment name. Settings stay locked until שינוי הגדרות is pressed. A blank סיסמה means no password, and saving it blank clears one. Any password saved there is required the next time. Until then the computer address and access token stay hidden. The product list in Settings is what check-in search uses. לוח ניהול at the bottom of Settings opens `http://<server>:8080/admin`.

At 00:00 the computer emails that environment's owner a Hebrew report of the previous day. If a tablet was offline, its rows stay on that tablet and upload on the next successful sync. The first successful email for a day wins.

The next SSH visit is opened at the shop computer itself:

```bash
sudo sh ~/cooling-down/ssh-window.sh 30
```

That starts SSH for 30 minutes and then closes it. SSH stays off after a reboot. A login that is already open can finish. New logins wait until someone at the computer runs the script again.

These steps stay on site. The scripts do not do them:

- Install Docker and OpenSSH on the shop computer, and allow your user to run Docker.
- Make the first SSH login work before you close SSH.
- Allow port 8080 from the shop Wi-Fi only.
- Type the real token, admin password, and mail password into `data/.env`.
- Install the tablet app on each device. Build it from `tablet/` and sideload it, or publish it through the stores. Signing keys and the devices are not in this repo.

## Layout

- `tablet/` — the Flutter app. `lib/presentation` is check-in, check-out, the fridge list, and settings. `lib/domain` is the product, log, alert, and report models. `lib/data` is the Drift database, repositories, and sync.
- `server/` — the shop computer: sync, the admin page, and the midnight email
- `tools/` — scripts that install the shop computer over SSH
- `backend/postgres/schema.sql` — a sketch for a later project. The shop install does not use it.
