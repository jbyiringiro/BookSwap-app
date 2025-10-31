# BookSwap-app
BookSwapp is a flutter based app with a small marketplace where students can list textbooks they wish to exchange and initiate swap offers with other users

## Table of Contents

*   [Overview](#overview)
*   [Features](#features)
*   [Architecture](#architecture)
*   [Prerequisites](#prerequisites)
*   [Installation & Setup](#installation--setup)
*   [Running the App](#running-the-app)
*   [Folder Structure](#folder-structure)
*   [Dependencies](#dependencies)
*   [State Management](#state-management)
*   [Firebase Integration](#firebase-integration)
*   [Android Build Configuration](#android-build-configuration)
*   [Contributing](#contributing)
*   [License](#license)

## Overview

BookSwap is a mobile application built with Flutter designed to facilitate the exchange of books between students. Users can sign up, log in, post books they want to swap, browse available listings from other users, initiate swap requests, manage their own listings and profile, and communicate via chat after a swap is initiated.

## Features

*   **User Authentication:**
    *   Sign up with email and password.
    *   Sign in with email and password.
    *   **Email verification enforcement:** Users cannot sign in until their email is verified.
    *   Log out functionality.
    *   Forgot Password feature.
*   **Book Management (CRUD):**
    *   **Create:** Post new book listings (title, author, condition, swap-for request, cover image).
    *   **Read:** Browse all available book listings in a feed.
    *   **Update:** Edit existing book listings (title, author, condition, swap-for request, image).
    *   **Delete:** Remove book listings.
*   **Swap Functionality:**
    *   Request a swap for another user's book.
    *   Accept or decline incoming swap requests.
    *   View pending and completed swap statuses.
    *   Dedicated "My Offers" section showing books the user has requested.
*   **Communication:**
    *   Basic two-user chat functionality between users involved in a swap.
*   **User Interface:**
    *   Responsive UI with dark theme support.
    *   Bottom navigation bar for easy access to main sections: Browse, My Listings, Chats, Settings.
    *   Profile management within the Settings screen, including email verification status and resend link.
    *   Dark Mode toggle in Settings.
    *   Notification and Email Update toggles in Settings.
*   **Real-time Data:**
    *   All data (books, swaps, chats) updates in real-time using Firestore streams.

## Architecture

The BookSwap app follows a layered architecture pattern, primarily leveraging the **Provider** state management library for simplicity and effectiveness.


*   **Presentation Layer (`lib/screens`, `lib/widgets`):** Contains the UI elements (Screens and Widgets). These components use `Consumer` or `Provider.of` to access state from the Provider layer and `StreamBuilder` to listen to data streams from the Data layer.
*   **State Management Layer (`lib/providers`):** Manages the application's state using the Provider pattern. Classes like `AuthProvider` hold user data and authentication status, `ThemeProvider` manages the app's theme, etc. They listen to changes from the Data layer (via Services) and notify the Presentation layer when state changes.
*   **Data Layer (`lib/services`, `lib/models`):** Handles data fetching, storage, and manipulation. `Services` interact with external sources (Firebase) and `Models` define the data structures. This layer provides the data streams consumed by `StreamBuilder` in the UI and methods called by `Providers`.

## Prerequisites

Before you begin, ensure you have the following installed:

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version recommended)
*   [Dart SDK](https://dart.dev/get-dart) (usually bundled with Flutter)
*   [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter/Dart plugins
*   A Firebase project configured (see [Firebase Integration](#firebase-integration))

## Installation & Setup

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/YOUR_USERNAME/bookswap.git
    cd bookswap
    ```

2.  **Install Flutter Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Install Firebase CLI Tools:**
    *   Install [Firebase CLI](https://firebase.google.com/docs/cli#setup_update_cli) globally.
    *   Install [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup#install-cli-plugins):
        ```bash
        dart pub global activate flutterfire_cli
        ```

4.  **Configure Firebase:**
    *   Log in to Firebase CLI:
        ```bash
        firebase login
        ```
    *   Navigate to your project directory (`bookswap/`).
    *   Run the FlutterFire configure command to link your project to your Firebase project:
        ```bash
        flutterfire configure
        ```
    *   This command will prompt you to select your Firebase project and platforms (Android, iOS, Web). It generates `lib/firebase_options.dart` with your project's configuration.

5.  **Add Firebase Dependencies:**
    Ensure the necessary Firebase plugins are listed in your `pubspec.yaml` (they likely already are if you followed the initial setup guide, but verify):
    ```yaml
    # pubspec.yaml
    dependencies:
      # ... other dependencies
      firebase_core: ^2.x.x # Use the latest stable version
      firebase_auth: ^4.x.x # Use the latest stable version
      cloud_firestore: ^4.x.x # Use the latest stable version
      firebase_storage: ^11.x.x # Use the latest stable version
      # Add other Firebase plugins as needed (e.g., firebase_messaging)
    ```
    Run `flutter pub get` again after adding any new dependencies.

6.  **Set Up Android Keystore (Optional but Recommended for Release Builds):**
    *   Follow the steps in the [Flutter documentation](https://flutter.dev/to/review-gradle-config#sign-the-app) to create a keystore and configure signing in `android/app/build.gradle.kts`.

7.  **Verify `.gitignore`:**
    Ensure your `.gitignore` file excludes sensitive files and build artifacts (e.g., `build/`, `.env`, `key.properties`, `*.jks`, `firebase_options.dart` if desired for security reasons, though it's often safe to commit for development). A standard Flutter `.gitignore` should already be present or generated by `flutter create`.

## Running the App

### Development Mode

1.  Ensure an Android emulator is running or a physical device is connected via USB debugging.
2.  Run the app:
    ```bash
    flutter run
    ```
    This command builds and installs the app in debug mode.

### Release Mode (for testing)

1.  Build the app for release (APK or App Bundle):
    *   For an APK:
        ```bash
        flutter build apk --release
        ```
    *   For an App Bundle (recommended for Play Store):
        ```bash
        flutter build appbundle --release
        ```
2.  Install the generated APK (`build/app/outputs/flutter-apk/app-release.apk`) onto your device or emulator manually, or upload the App Bundle (`build/app/outputs/bundle/release/app.aab`) to the Play Console.

## Folder Structure

bookswap/
├── android/ # Android native project files
│ ├── app/
│ │ ├── build.gradle.kts # Android app build configuration
│ │ └── src/
│ │ └── main/
│ │ ├── AndroidManifest.xml # App manifest
│ │ ├── java/ (or kotlin/)
│ │ └── res/ # Resources (drawables, layouts, values)
│ ├── build.gradle.kts # Root project build configuration
│ ├── gradle/
│ │ └── wrapper/
│ │ └── gradle-wrapper.properties
│ ├── gradle.properties
│ └── settings.gradle.kts
├── assets/ # Static assets (images, fonts, etc.) - if any
├── build/ # Generated build outputs (ignored by git)
├── ios/ # iOS native project files
├── lib/ # Main Flutter source code
│ ├── main.dart # Entry point of the application
│ ├── models/ # Data models (e.g., BookListing, BookSwapUser)
│ │ ├── auth_result.dart # Result class for auth operations
│ │ ├── book_model.dart # Book data model
│ │ ├── chat_model.dart # Chat data models
│ │ └── user_model.dart # User data model
│ ├── providers/ # State management providers (e.g., AuthProvider)
│ │ ├── auth_provider.dart
│ │ ├── notification_provider.dart
│ │ └── theme_provider.dart
│ ├── screens/ # UI screens (e.g., HomeScreen, MyListingsScreen)
│ │ ├── auth/ # Authentication screens (Login, Signup, Forgot Password)
│ │ ├── book_detail_screen.dart
│ │ ├── chat_screen.dart
│ │ ├── home_screen.dart
│ │ ├── my_listings_screen.dart
│ │ ├── post_book_screen.dart
│ │ └── settings_screen.dart
│ ├── services/ # Business logic and external API calls (e.g., Firebase)
│ │ ├── auth_service.dart
│ │ ├── book_service.dart
│ │ └── chat_service.dart
│ └── widgets/ # Reusable UI components (e.g., BookCard, ChatBubble)
│ ├── book_card.dart
│ ├── bottom_nav_bar.dart
│ └── chat_bubble.dart
├── test/ # Unit and widget tests (ignored by git)
├── pubspec.lock # Lock file for dependencies (ignored by git)
├── pubspec.yaml # Project configuration and dependencies
└── README.md # This file


## Dependencies

Key dependencies used in the project are defined in `pubspec.yaml`. Notable ones include:

*   `flutter`: The core Flutter SDK.
*   `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`: Core Firebase plugins for authentication, data storage, and file storage.
*   `provider`: State management library.
*   `image_picker`: For selecting images from the device gallery.
*   `flutter_local_notifications`: For local notifications (if implemented).
*   `shared_preferences`: For persisting simple data like toggle states.

## State Management

The application uses the **Provider** package for state management. This involves:

*   `ChangeNotifierProvider`: Wraps parts of the widget tree to provide `ChangeNotifier` instances (like `AuthProvider`, `ThemeProvider`).
*   `Consumer`: Widgets that rebuild automatically when the specific `ChangeNotifier` they depend on calls `notifyListeners()`.
*   `Provider.of`: Used to access the provider instance for performing actions (e.g., calling sign-in methods) without necessarily rebuilding the current widget.

This pattern keeps the UI reactive to changes in application state (like user authentication status, theme preference, or book listings) without requiring global `setState` calls in the presentation layer.

## Firebase Integration

The app integrates with Firebase for backend services:

*   **Authentication:** `firebase_auth` handles user sign-up, sign-in, email verification enforcement, and sign-out.
*   **Database:** `cloud_firestore` stores user profiles, book listings, swap requests, and chat messages using Firestore collections and documents.
*   **Storage:** `firebase_storage` handles the uploading and hosting of book cover images.
*   **Configuration:** The `flutterfire configure` command generates `firebase_options.dart`, which contains the necessary configuration to connect the app to your Firebase project.

## Android Build Configuration

The Android build process uses Gradle. Key aspects include:

*   **Java 8+ Support:** The `android/app/build.gradle.kts` file is configured with `isCoreLibraryDesugaringEnabled = true` and `coreLibraryDesugaring(...)` to enable Java 8+ API support for older Android versions, which is necessary for some Firebase plugin functionalities and general compatibility.
*   **Signing:** Configuration for release signing (if keystore is set up) is present in `android/app/build.gradle.kts`.
*   **Min/Target SDK:** Defined in `android/app/build.gradle.kts` via `flutter.minSdkVersion`, `flutter.targetSdkVersion`.
*   **Dependencies:** Managed in `android/app/build.gradle.kts` and `android/build.gradle.kts` (e.g., Firebase BoM for consistent versions).

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes. Ensure your code follows the existing style and passes any tests.
