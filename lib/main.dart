import 'package:_abm/dbmodels/models.dart';
import 'package:_abm/dbmodels/profile.dart';
import 'package:_abm/responsive/desktop.dart';
import 'package:_abm/responsive/mobile.dart';
import 'package:_abm/responsive/responsive_layout.dart';
import 'package:_abm/responsive/tablet.dart';
import 'package:_abm/services/undo_redo_service.dart';
import 'package:_abm/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shake/shake.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://hhezduzrlkojnerxuvbv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhoZXpkdXpybGtvam5lcnh1dmJ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyODY1NDksImV4cCI6MjA4MDg2MjU0OX0.f0ZslLkPIssqiNVQYcRdXyaTGUg1RutL-gDN37YYbpo',
  );

  // if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProfileAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(StudentAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CollectionAdapter());

  await Hive.openBox<Profile>('profileBox');
  await Hive.openBox<Collection>('collectionsBox');
  await Hive.openBox('myBox');
  // await Hive.openBox('myBox');
  await Hive.openBox('calcHistory');
  await Hive.openBox('settingsBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeManager,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'A B M',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF7F9FC), // Light BG
            primaryColor: const Color(0xFF0A57FF), // Electric Blue
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A57FF),
              secondary: Color(0xFFD7D7D7), // Secondary Button
              surface: Color(0xFFFFFFFF), // Card
              onSurface: Color(0xFF000000), // Primary Text
              onSurfaceVariant: Color(0xFF555555), // Secondary Text
              outline: Color(0xFFCFCFCF), // Borders
              shadow: Color(0xFFE5E5E5),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF7F9FC),
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF000000)),
              titleTextStyle: TextStyle(color: Color(0xFF000000), fontSize: 20),
            ),
            cardColor: const Color(0xFFFFFFFF),
            dividerColor: const Color(0xFFCFCFCF),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF000000), // Pitch Black
            primaryColor: const Color(0xFF2979FF), // Neon Blue
            cardColor: const Color(0xFF1C1C1E), // Dark Gray Surface
            dividerColor: const Color(0xFF2C2C2E),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2979FF), // Neon Blue
              secondary: Color(0xFF00E5FF), // Cyan Accent
              surface: Color(0xFF1C1C1E), // Dark Surface
              onSurface: Color(0xFFFFFFFF), // White Text
              onSurfaceVariant: Color(0xFFA1A1A1), // Light Gray Text
              outline: Color(0xFF2C2C2E), // Subtle Borders
              tertiary: Color(0xFFBB86FC), // Purple Accent
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF000000),
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
              titleTextStyle: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            useMaterial3: true,
            // Add other component themes for consistency
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF2979FF),
              foregroundColor: Colors.white,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF1C1C1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: Color(0xFF2C2C2E),
              contentTextStyle: TextStyle(color: Colors.white),
              behavior: SnackBarBehavior.floating,
            ),
          ),
          home: const ShakeWrapper(
            child: ResponsiveLayout(
              mobileScaffold: MobileScreen(),
              tabletScaffold: TabletScreen(),
              desktopScaffold: DesktopScreen(),
            ),
          ),
        );
      },
    );
  }
}

class ShakeWrapper extends StatefulWidget {
  final Widget child;
  const ShakeWrapper({super.key, required this.child});

  @override
  State<ShakeWrapper> createState() => _ShakeWrapperState();
}

class _ShakeWrapperState extends State<ShakeWrapper> {
  late ShakeDetector detector;

  @override
  void initState() {
    super.initState();
    detector = ShakeDetector.autoStart(
      onPhoneShake: () {
        debugPrint("Shake event detected in Main");
        final manager = UndoRedoManager();
        if (manager.canUndo || manager.canRedo) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Undo / Redo'),
                content:
                    const Text('Do you want to undo or redo the last action?'),
                actions: [
                  if (manager.canRedo)
                    TextButton(
                      onPressed: () {
                        manager.redo();
                        Navigator.pop(context);
                      },
                      child: const Text('Redo'),
                    ),
                  if (manager.canUndo)
                    ElevatedButton(
                      onPressed: () {
                        manager.undo();
                        Navigator.pop(context);
                      },
                      child: const Text('Undo'),
                    ),
                ],
              ),
            );
          }
        } else {
          debugPrint("Shake detected but nothing to undo/redo");
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("No actions to undo!"),
              duration: Duration(seconds: 1),
            ));
          }
        }
      },
      shakeThresholdGravity:
          2.7, // Slightly lower threshold (default 2.7 is standard, but keeping explicit helps)
      minimumShakeCount: 1, // Require 1 shake (default is usually 1)
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
    );
  }

  @override
  void dispose() {
    detector.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
