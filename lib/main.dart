// ==============================================================================
// الملف: lib/main.dart
// الوظيفة: نقطة دخول تطبيق "أثر مسلم"، تهيئة اللغة العربية والمنطقة الزمنية
//          والإشعارات والمنبهات الخلفية، وضبط الهوية اللونية الزرقاء السماوية
//          الفاتحة مع شريط التنقل السفلي الأساسي.
// ==============================================================================

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'providers/app_state_provider.dart';
import 'screens/home_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tasbih_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  await AndroidAlarmManager.initialize();
  await NotificationService.instance.init();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider<AppStateProvider>(
      create: (_) => AppStateProvider(prefs),
      child: const AtharMuslimApp(),
    ),
  );
}

class AtharMuslimApp extends StatelessWidget {
  const AtharMuslimApp({super.key});

  static const Color skyBluePrimary = Color(0xFF0288D1);
  static const Color skyBlueLight = Color(0xFFE1F5FE);
  static const Color skyBlueAccent = Color(0xFF29B6F6);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'أثر مسلم',
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[
        Locale('ar'),
      ],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: skyBlueAccent,
          primary: skyBluePrimary,
          secondary: skyBlueAccent,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: skyBlueLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: skyBluePrimary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: skyBlueLight,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
      ),
      home: const MainShellScreen(),
    );
  }
}

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    QuranScreen(),
    TasbihScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final AppStateProvider state = context.watch<AppStateProvider>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: state.navIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: state.navIndex,
          onDestinationSelected: state.setNavIndex,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'القرآن',
            ),
            NavigationDestination(
              icon: Icon(Icons.fingerprint_outlined),
              selectedIcon: Icon(Icons.fingerprint),
              label: 'المسبحة',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}

