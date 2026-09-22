import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'services/serial_service.dart';
import 'services/api_service.dart';
import 'services/database_helper.dart';
import 'providers/settings_provider.dart';
import 'providers/sampling_provider.dart';
import 'providers/history_provider.dart';
import 'views/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop
  await windowManager.ensureInitialized();

  // Configure window to be fullscreen and locked
  WindowOptions windowOptions = const WindowOptions(
    fullScreen: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setFullScreen(true);
    await windowManager.setPreventClose(false);
    // Prevent minimize and resize
    await windowManager.setResizable(false);
    await windowManager.setMinimizable(false);
  });

  // Initialize database
  final dbHelper = DatabaseHelper();
  await dbHelper.initDatabase();

  // Initialize services
  final serialService = SerialService();
  final apiService = ApiService();

  // Create providers
  final historyProvider = HistoryProvider();
  final samplingProvider = SamplingProvider(serialService, apiService);
  samplingProvider.setHistoryProvider(historyProvider);

  runApp(
    MultiProvider(
      providers: [
        Provider<SerialService>.value(value: serialService),
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (context) => SettingsProvider(serialService, apiService),
        ),
        ChangeNotifierProvider.value(value: samplingProvider),
        ChangeNotifierProvider.value(value: historyProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'T-NOSE V2',
      debugShowCheckedModeBanner: false,
      // Premium Light Mode Theme with T-Nose Red Palette
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFB81D24), // T-Nose Crimson Red
          secondary: Color(0xFF475569), // Slate 600
          surface: Color(0xFFFFFFFF), // White surface card background
          error: Color(0xFFEF4444), // Red 500
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold), // Slate 900
          bodyMedium: TextStyle(color: Color(0xFF334155)), // Slate 700
        ),
      ),
      home: const DashboardView(),
    );
  }
}
