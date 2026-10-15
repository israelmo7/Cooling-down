# Cooling-down

Field install is in `guide.txt`.

Version 0.1. A Hebrew tablet logs refrigerator check-in and check-out. The shop computer keeps the archive and sends the daily report. Each confirm writes to SQLite on the tablet first. If the shop Wi-Fi is down, the row stays on the tablet and syncs when the shop computer is reachable again. The computer keeps the shared database and emails the owner at the report hour, midnight unless that hour was changed, with a report of the day that just ended.

Check-in and check-out stay separate rows. A log is never edited. If two tablets check the same item out, both temperatures are kept, an alert is recorded, and the earliest check-out is the one that closes the item.

Check-in, check-out, and the fridge list are three full-screen Hebrew tabs. The settings button on the top bar holds the computer address and token. The owner email, the mail server, and the report hour are set on the shop computer. The default report hour is midnight.

## Run

From `tablets/`:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Test

From `tablets/`:

```bash
flutter analyze
flutter test
```

## Shop computer

The shop computer is the local server. Tablets upload to it over the shop Wi-Fi, at `http://<computer>:8080`. They do not use SSH, and they do not share through another tablet.

To try it on a machine that already has Dart, from `server-ssh/`:

```bash
cp .env.example .env
dart pub get
dart run bin/server.dart
```

Field steps are in `guide.txt`. Settings for the shop computer are `server-ssh/shop.json`.

## Layout

- `tablets/` — one Flutter app for Android and iOS. `android/` and `ios/` are the install shells for each store.
- `server-ssh/` — the shop program, its image, the SSH deploy, and the Windows pack
- `server-usb/` — offline installers. Linux packages are in the folder root. Windows Docker and WSL are in `windows/`
