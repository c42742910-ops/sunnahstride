// main.dart — HalalCalorie v1.0
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme.dart';
import 'core/providers.dart';
import 'core/revenuecat_service.dart';
import 'core/notifications.dart';
import 'core/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Init SQLite with timeout
  try {
    await AppDatabase.db.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw Exception('DB timeout'),
    );
  } catch (e) {
    debugPrint('DB init failed: $e');
  }

  // Init notifications with timeout
  try {
    await NotificationService.init().timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw Exception('Notifications timeout'),
    );
  } catch (e) {
    debugPrint('Notifications init failed: $e');
  }

  // Init RevenueCat with timeout
  try {
    await RCConfig.configure().timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw Exception('RevenueCat timeout'),
    );
  } catch (e) {
    debugPrint('RevenueCat init failed: $e');
  }

  runApp(const ProviderScope(child: HalalCalorieApp()));
}

class HalalCalorieApp extends ConsumerWidget {
  const HalalCalorieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final lang   = ref.watch(languageProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'HalalCalorie | HalalCalorie',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.lightTheme,
      darkTheme:  AppTheme.darkTheme,
      themeMode:  isDark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(lang),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
