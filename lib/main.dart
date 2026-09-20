import 'package:dynamic_color/dynamic_color.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = AppThemeController();

  runApp(MyApp(themeController: themeController));
}

class MyApp extends StatelessWidget {
  final AppThemeController themeController;
  const MyApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      controller: themeController,
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              ColorScheme? lightScheme;
              ColorScheme? darkScheme;

              if (themeController.customThemeEnabled) {
                lightScheme = ColorScheme.fromSeed(
                  seedColor: themeController.selectedThemeColor.seed,
                  brightness: Brightness.light,
                );
                darkScheme = ColorScheme.fromSeed(
                  seedColor: themeController.selectedThemeColor.seed,
                  brightness: Brightness.dark,
                );
              } else {
                lightScheme =
                    lightDynamic ??
                    ColorScheme.fromSeed(
                      seedColor: AppTheme.fallbackSeed,
                      brightness: Brightness.light,
                    );
                darkScheme =
                    darkDynamic ??
                    ColorScheme.fromSeed(
                      seedColor: AppTheme.fallbackSeed,
                      brightness: Brightness.dark,
                    );
              }

              return MaterialApp(
                title: 'Expendi Note',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.buildTheme(lightScheme),
                darkTheme: AppTheme.buildTheme(darkScheme),
                themeMode: themeController.themeMode,
                home: const AppInitializationWrapper(),
              );
            },
          );
        },
      ),
    );
  }
}

class AppThemeScope extends InheritedNotifier<AppThemeController> {
  const AppThemeScope({
    super.key,
    required AppThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppThemeController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppThemeScope>()!
        .notifier!;
  }
}

/// A wrapper widget that handles asynchronous database setup smoothly
/// while keeping the UI thread responsive.
class AppInitializationWrapper extends StatefulWidget {
  const AppInitializationWrapper({super.key});

  @override
  State<AppInitializationWrapper> createState() =>
      _AppInitializationWrapperState();
}

class _AppInitializationWrapperState extends State<AppInitializationWrapper> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    // Trigger database init after frame rendering schedule starts
    _initFuture = DatabaseService.instance.database.then((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const HomeScreen();
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
