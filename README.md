# Flutter To-Do App (Hive + Riverpod + Notifications)

A production-style To-Do app built with Flutter using:
- Hive for local persistence
- Riverpod for state management
- flutter_local_notifications for scheduled reminders (works when screen is off)
- Multi-select, select all, edit, delete, alarm per task, undo, strike-through completed

## Features

- Add / Edit / Delete tasks
- Mark task as Done / Undo
- Per-task alarm: schedule date + time (notification fires even if app closed)
- Notification tap marks a task as done (app opens and marks)
- Multi-select with Select All and Delete
- Empty state UI
- Splash & Welcome screens (welcome shown once using Hive)
- Null-safety, minimal try/catch around I/O & notifications

## Setup

1. Clone:
```bash
git clone https://github.com/naveenkvofficialhere/todo.git
```

2. Run:
```bash
cd flutter_todo_app
flutter pub get
flutter run
```

## Testing

The app includes comprehensive test coverage with both unit and widget tests.

### Test Structure
```
test/
├── unit_test/
│   └── task_model_test.dart      # Unit tests for Task model and Hive adapter
└── widget_test/
    └── task_display_test.dart    # Widget tests for HomeScreen UI interactions
```

### Running Tests

**Run all tests:**
```bash
flutter test
```

**Run specific test files:**
```bash
# Unit tests (fast execution ~8 seconds)
flutter test test/unit_test/task_model_test.dart

# Widget tests (slower execution ~5+ minutes due to UI interactions)
flutter test test/widget_test/task_display_test.dart
```

**Run tests with coverage:**
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Test Coverage

#### Unit Tests (`task_model_test.dart`)
- **14 tests** covering:
  - Task creation with required/optional parameters
  - Task property modifications
  - Hive serialization/deserialization
  - Edge cases (long text, special characters, timezone handling)
  - Multiple task storage and retrieval

#### Widget Tests (`task_display_test.dart`)
- **Multiple test suites** covering:
  - Empty state display
  - Task rendering (pending/completed sections)
  - User interactions (tap, long press, selection mode)
  - Form validation in add/edit dialogs
  - Multi-select functionality
  - Scrolling behavior with many tasks
  - Edge cases (empty descriptions, long titles)

### Test Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_test: ^1.0.1  # For Hive testing utilities
```

### Performance Notes
- **Unit tests**: Execute quickly (seconds) as they test isolated components
- **Widget tests**: Take longer (minutes) due to UI rendering, animations, and user interaction simulation using `pumpAndSettle()`

## Build

**Debug APK:**
```bash
flutter build apk --debug
```

**Release APK:**
```bash
flutter build apk --release
```

**App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```

## Architecture

- **Models**: Task data structure with Hive adapter for persistence
- **Providers**: Riverpod StateNotifier for task state management
- **Services**: Notification service with alarm permissions handling
- **Screens**: Home, Splash, Welcome, and Debug screens
- **Widgets**: Reusable TaskTile, EmptyState components

## Dependencies

**Core:**
- `flutter_riverpod` - State management
- `hive_flutter` - Local database
- `flutter_local_notifications` - Scheduled notifications
- `intl` - Date formatting

**Platform-specific:**
- `permission_handler` - Android permissions
- `device_info_plus` - Device information
- `timezone` - Timezone handling for notifications

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `flutter test`
5. Submit a pull request

