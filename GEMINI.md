# Project Overview

This is a Flutter application named "mgt_app" that targets multiple platforms: Android, iOS, macOS, and web. It appears to be a management application, likely for a business, given the feature names like "leads", "projects", and "tasks".

The application uses Firebase for its backend, including:
*   **Authentication:** For user login and management.
*   **Firestore:** As the primary database, with security rules defined in `firestore.rules`.
*   **Cloud Functions:** For backend logic, with the source code located in the `functions` directory.

The app is built with the following key technologies:
*   **Flutter:** For the cross-platform UI.
*   **Dart:** The programming language for Flutter.
*   **Riverpod:** For state management.
*   **GoRouter:** For navigation and routing.

The project follows a feature-based architecture, with each feature having its own directory containing the relevant screens, providers, and repositories.

# Building and Running

To build and run this project, you will need to have the Flutter SDK installed.

**1. Install Dependencies:**

```bash
flutter pub get
```

**2. Run the Application:**

To run the application on a connected device or emulator, use the following command:

```bash
flutter run
```

To run the application on a specific platform, use the ` -d ` flag:

```bash
# Run on Chrome
flutter run -d chrome

# Run on an Android device
flutter run -d <device_id>
```

**3. Testing:**

To run the tests for this project, use the following command:

```bash
flutter test
```

# Development Conventions

*   **Code Style:** The project follows the standard Flutter lints, as defined in `analysis_options.yaml`.
*   **State Management:** State management is handled using `flutter_riverpod`. When adding new features, you should use Riverpod providers to manage the state.
*   **Routing:** Navigation is handled by `go_router`. New screens should be added to the router configuration in `lib/core/router/app_router.dart`.
*   **Architecture:** The project follows a feature-based architecture. When adding a new feature, create a new directory in `lib/features` and organize the code within that directory.
*   **Firebase:** The project is tightly integrated with Firebase. When adding new features that require backend functionality, you should use the existing Firebase services.
