# OSA Management Flutter v2.2

Flutter mobile client for OSA Management.

## Current status

- Arabic RTL UI
- OSA red/black/white visual theme
- Authentication and secure token persistence
- Role-aware UI permissions
- Dashboard
- Students
- Teachers
- Courses
- Groups
- Attendance
- Subscriptions & Payments
- Reports
- Notifications
- Settings
- Centralized API client with timeout/error handling

## API

Default API base URL:
`https://admin.muteatalriyadiaat.com/api`

Override at build time:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://admin.muteatalriyadiaat.com/api
```

## Release validation

Before release, run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://admin.muteatalriyadiaat.com/api
```

## QA additions in v2.3
- Added unit tests for role/feature permissions.
- Added unit tests for UserModel parsing and JSON round-trip behavior.
- Added standard Flutter/Dart .gitignore entries.
- Flutter SDK is required to execute the test suite and release build.
