# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based management application (mgt_app) built for multi-role business operations. The app uses Firebase for backend services and follows Clean Architecture principles with feature-based organization.

## Tech Stack

- **Framework**: Flutter 3.9.2+
- **State Management**: Riverpod (flutter_riverpod ^2.6.1)
- **Navigation**: GoRouter ^16.2.4
- **Backend**: Firebase (Auth, Firestore, Cloud Functions)
- **Architecture**: Clean Architecture with Domain-Driven Design

## Common Development Commands

### Running the App
```bash
flutter run
```

### Building
```bash
# Web build
flutter build web

# Android build
flutter build apk

# iOS build
flutter build ios
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/
```

### Dependency Management
```bash
# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Clean build artifacts
flutter clean
```

## Architecture

The codebase follows **Clean Architecture** with clear separation of concerns:

### Layer Structure

1. **Domain Layer** (`lib/features/*/domain/`)
   - `entities/`: Pure Dart business objects (e.g., `UserEntity`, `LeadEntity`, `ProjectEntity`)
   - `repositories/`: Abstract repository interfaces
   - `usecases/`: Business logic operations (e.g., `LoginUseCase`, `GetLeadUseCase`)

2. **Data Layer** (`lib/features/*/data/`)
   - `models/`: Data models with JSON serialization
   - `repositories/`: Repository implementations (Firebase/Firestore)
   - `datasources/`: Remote and local data sources
   - `mappers/`: Convert between entities and models

3. **Presentation Layer** (`lib/features/*/presentation/`)
   - `screens/`: Full-page UI components
   - `widgets/`: Reusable UI components
   - `providers/`: Riverpod state management (StateNotifier pattern)

### Feature Modules

The app is organized by features:
- **auth**: Authentication and user management
- **dashboard**: Role-based dashboard with real-time stats
- **leads**: Lead management and tracking
- **projects**: Project lifecycle management
- **tasks**: Task management with subtasks
- **admin**: Admin panel and user management
- **notifications**: System notifications

### Core Components

- **Router** (`lib/core/router/app_router.dart`): Centralized GoRouter configuration with auth guards and role-based redirects
- **Constants** (`lib/core/constants/`): App-wide constants (colors, theme)
- **Shared** (`lib/shared/`): Reusable widgets, services, and utilities

## State Management Pattern

The app uses **Riverpod** with the following patterns:

### Provider Hierarchy
```dart
// Repository Provider (singleton)
final xxxRepositoryProvider = Provider<XxxRepository>((ref) => ...);

// UseCase Providers
final xxxUseCaseProvider = Provider<XxxUseCase>((ref) => ...);

// State Notifier Provider (for mutable state)
final xxxProvider = StateNotifierProvider<XxxNotifier, XxxState>((ref) => ...);

// Stream/Future Providers (for async data)
final xxxStreamProvider = StreamProvider<Xxx>((ref) => ...);
```

### Key Providers

- `authProvider`: Manages authentication state
- `currentUserProvider`: Exposes current user entity
- `filteredCountsProvider`: Real-time Firestore collection counts (role-filtered)
- `recentActivityProvider`: Combined activity stream from multiple collections

## Firebase Integration

### Authentication
- Uses Firebase Auth with email/password
- Admin-created user accounts (stored in Firestore `users` collection)
- Role-based access control enforced at repository level

### Firestore Collections
- `users`: User profiles with roles and permissions
- `leads`: Sales leads
- `projects`: Project records
- `tasks`: Task management (supports parent-child for subtasks)

### Role-Based Data Filtering
Non-admin users see only their created records via `createdBy` field filtering. This is implemented in:
- `lib/features/dashboard/presentation/screens/unified_dashboard_screen.dart:13-25` (filteredCountsProvider)
- Repository implementations (e.g., `leads_repository_firesotre.dart`, `project_repository_firestore.dart`)

## Navigation & Routing

### Route Structure
- `/login` - Login screen (public)
- `/forgot-password` - Password reset (public)
- `/dashboard` - Unified role-based dashboard (protected)
- `/leads` - Lead list (protected)
- `/projects` - Project list (protected)
- `/tasks` - Task list (protected)
- `/admin` - Admin panel (admin only)
- `/user-management` - User management (protected)

### Auth Guards
The router automatically redirects:
- Unauthenticated users → `/login`
- Authenticated users on `/login` → `/dashboard`
- Non-admin users trying to access `/admin` → `/dashboard`

## User Roles & Permissions

The app supports multiple roles defined in `UserEntity`:
- **admin**: Full system access (CRUD all resources)
- **sales**: Create/read/update leads and projects (no delete)
- **estimation**: Enquiries and quotations (planned)
- **accounts**: Invoices and payments (planned)
- **store**: Material management (planned)
- **production**: Production tasks (planned)
- **delivery**: Delivery management (planned)
- **marketing**: Campaigns and creative (planned)

Permissions are enforced through:
1. `UserPermissions` class in `lib/features/auth/domain/entities/user_entity.dart:58-114`
2. Repository-level filtering (Firestore rules and queries)
3. Route-level guards in `app_router.dart`

## Real-Time Data

The dashboard uses StreamProviders to display real-time data:
- **filteredCountsProvider**: Live count of leads/projects/tasks
- **recentActivityProvider**: Combines last 10 activities from leads, projects, and tasks collections

This is implemented using Firestore snapshots and manual stream combination in `unified_dashboard_screen.dart:54-223`.

## Important Implementation Notes

### Data Type Handling
When working with Firestore data, dates can come in multiple formats (Timestamp, DateTime, String). Use the helper function pattern:
```dart
DateTime? _toDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
```

### Role-Based Query Pattern
```dart
Query query = FirebaseFirestore.instance.collection('xxx');
if (role != 'admin') {
  query = query.where('createdBy', isEqualTo: uid);
}
```

### Clean Architecture Flow
When adding new features:
1. Define entities in `domain/entities/`
2. Create repository interface in `domain/repositories/`
3. Implement use cases in `domain/usecases/`
4. Create models and repository implementation in `data/`
5. Build UI and providers in `presentation/`

## Responsive Design

The app uses `ResponsiveBuilder` widget (in `lib/shared/widgets/responsive/responsive_builder.dart`) to provide different layouts for:
- **Mobile**: Single-column, stacked layout
- **Tablet**: 2-column grid, side-by-side panels
- **Desktop**: Multi-column, expanded layouts

## Firebase Configuration

Firebase is initialized in `main.dart:26` with platform-specific options from `firebase_options.dart` (generated by FlutterFire CLI).

To reconfigure Firebase:
```bash
flutterfire configure
```

## Web-Specific Configuration

The app uses `url_strategy` package to remove the `#` from web URLs:
```dart
setPathUrlStrategy(); // in main.dart:27
```
