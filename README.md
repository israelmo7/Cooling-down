# Cooling-down

Tablet app for logging refrigerator check-in and check-out temperatures in commercial kitchens and pharmacies. Each confirm writes to SQLite first. Check-in and check-out are separate rows, and a sync outbox queues them for a later PostgreSQL upload.

The station layout is landscape, about 1024 px wide or wider.

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

## Layout

- `lib/presentation` — check-in, check-out, and the live fridge feed
- `lib/domain` — product, log, and alert models plus repository interfaces
- `lib/data` — Drift database, repositories, and the sync outbox
- `backend/postgres/schema.sql` — PostgreSQL shape for a later Supabase project
