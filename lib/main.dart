import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_handler.dart';
import 'utils/http_overrides.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Light Theme Colors ---
    const primaryColorLight = Color(0xFF0077B6);
    const accentColorLight = Color(0xFF00B4D8);
    const scaffoldBackgroundColorLight = Color(0xFFEDF2F4);

    // --- New Dark Theme Colors ---
    const primaryColorDark = Color(0xFF4DB6AC); // Teal
    const accentColorDark = Color(0xFFFFB74D); // Amber
    const scaffoldBackgroundColorDark = Color(0xFF121212); // Deep Charcoal
    const cardColorDark = Color(0xFF1E1E1E); // Lighter Charcoal

    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'مذكّر المناسبات',
      // --- الثيم الفاتح --- //
      theme: ThemeData.light().copyWith(
        primaryColor: primaryColorLight,
        scaffoldBackgroundColor: scaffoldBackgroundColorLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1.0,
          iconTheme: IconThemeData(color: primaryColorLight),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColorLight,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: primaryColorLight,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 8,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) return primaryColorLight;
            return Colors.grey;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return primaryColorLight.withOpacity(0.5);
            }
            return Colors.grey.withOpacity(0.5);
          }),
        ),
        colorScheme: const ColorScheme.light(
          primary: primaryColorLight,
          secondary: accentColorLight,
          background: scaffoldBackgroundColorLight,
        ).copyWith(secondary: accentColorLight),
      ),
      // --- الثيم الداكن الجديد والمحسّن --- //
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: primaryColorDark,
        scaffoldBackgroundColor: scaffoldBackgroundColorDark,
        appBarTheme: AppBarTheme(
          backgroundColor: cardColorDark,
          foregroundColor: Colors.white,
          elevation: 1.0,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColorDark,
          foregroundColor: Colors.black,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedItemColor: primaryColorDark,
            unselectedItemColor: Colors.white70,
            backgroundColor: cardColorDark,
            elevation: 8),
        cardTheme: CardThemeData(
          elevation: 2,
          color: cardColorDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) return primaryColorDark;
            return Colors.grey[600];
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return primaryColorDark.withOpacity(0.5);
            }
            return Colors.grey[800];
          }),
        ),
        colorScheme: const ColorScheme.dark(
          primary: primaryColorDark,
          secondary: accentColorDark,
          background: scaffoldBackgroundColorDark,
          surface: cardColorDark,
        ).copyWith(secondary: accentColorDark),
      ),
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'AE'),
      ],
      locale: const Locale('ar', 'AE'),
      home: const AuthHandler(),
    );
  }
}

