# ABM - Student & Collections Manager

ABM is a comprehensive, cross-platform Flutter application designed to manage student collections, balances, and profiles efficiently. The application provides an elegant, responsive interface across mobile, tablet, and desktop layout sizes. It features robust data synchronization using Supabase and Firebase, while maintaining offline-first capabilities through Hive.

## 🚀 Features

- **Responsive Design**: Adapts beautifully across Desktop, Tablet, and Mobile screens.
- **Theme Support**: Includes premium Light and Dark theme modes.
- **Offline-First Architecture**: Utilizes `Hive` for fast, local NoSQL data storage.
- **Student & Collection Management**: Track student records, collection lists, and manage payment methods seamlessly.
- **Undo/Redo System**: Integrated with `shake` – simply shake your device to undo or redo your last action!
- **Data Export**: Export collection and student data easily using the `excel` package integration.
- **Cloud Synchronization**: Backend powered by `Supabase` and `Firebase` to keep your profiles and collections securely backed up and synced.
- **Modern UI Components**: Features liquid pull-to-refresh, curved navigation bars, and avatar glow effects for a lively user experience.
- **Integrated Calculator**: Comes with built-in mathematical expression evaluation with a calculation history.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.5.2)
- **Language**: Dart
- **Local Storage**: [Hive](https://pub.dev/packages/hive) & [Hive Flutter](https://pub.dev/packages/hive_flutter)
- **Backend / Database**:
  - [Supabase](https://supabase.com/) (using `supabase_flutter`)
  - [Firebase](https://firebase.google.com/) (Auth, Firestore, Realtime Database, Storage)
- **UI Libraries**:
  - `flutter_slidable`, `curved_navigation_bar`, `slide_drawer`
  - `hidden_drawer_menu`, `avatar_glow`, `shimmer`

## 📦 Prerequisites

Before running the project, make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.5.2 or above)
- [Dart SDK](https://dart.dev/get-dart)
- An IDE (VS Code, Android Studio, or IntelliJ IDEA)
- A configured emulator/simulator or physical device.

## ⚙️ Getting Started & Installation

1. **Clone the repository** (if not already done):
   ```bash
   git clone <repository-url>
   cd _abm
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Database Setup** (Optional but recommended):
   The repository includes necessary SQL files for setting up Supabase logic:
   - Run `supabase_setup.sql` in your Supabase SQL editor.
   - Run `documents_setup.sql` in your Supabase SQL editor to create needed document structures.

4. **Code Generation** (Hive Adapters):
   If you make changes to the Hive models (like `Student` or `Collection`), rebuild the Hive adapters:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the App**:
   ```bash
   flutter run
   ```

## 📂 Project Structure

```
lib/
 ├── dbmodels/        # Hive Database models (Profile, Student, Collection)
 ├── responsive/      # Desktop, Tablet, and Mobile layout structure
 ├── services/        # Business logic, API calls, and Undo/Redo services
 ├── theme/           # ThemeManager and color palette definitions
 ├── utils/           # Utility functions and shared helpers
 ├── presentation/    # Top-level UI views and components
 └── main.dart        # Entry point of the application
```

## 🔑 Backend Configuration

### Supabase
The application initializes Supabase at the start. You'll find the configuration context in `lib/main.dart`. Ensure you update the `url` and `anonKey` with your own Supabase project details if you are deploying a custom instance.

### Firebase
The project contains basic Firebase configuration via `firebase.json`. To fully utilize Firebase features, setup your project via the Firebase CLI (`flutterfire configure`).

## 👨‍💻 Contributing

1. Fork the project.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a pull request.
