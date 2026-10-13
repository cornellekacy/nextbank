import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/user_dashboard.dart';
import 'screens/banned_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NextBankApp());
}

class NextBankApp extends StatefulWidget {
  const NextBankApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<NextBankApp> createState() => _NextBankAppState();

  static _NextBankAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_NextBankAppState>();
  }
}

class _NextBankAppState extends State<NextBankApp> {
  bool _initialized = false;
  Map<String, dynamic>? _savedUser;
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _initWithTimeout();
  }

  Future<void> _initWithTimeout() async {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Firebase init error: $e');
    }
    try {
      await FcmService.init().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('FcmService init error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language') ?? 'en';
    _locale = Locale(savedLang);
    if (!mounted) return;
    _savedUser = await ApiService.tryAutoLogin();
    if (mounted) setState(() => _initialized = true);
  }

  Locale get currentLocale => _locale;

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
    setState(() => _locale = Locale(languageCode));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextBank',
      debugShowCheckedModeBanner: false,
      navigatorKey: NextBankApp.navigatorKey,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _initialized
          ? (_savedUser != null
              ? AuthGate(userData: _savedUser!)
              : const LoginScreen())
          : const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(loc.tr('splash.loading')),
          ],
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final Map<String, dynamic> userData;

  const AuthGate({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    if (userData['status'] == 'banned') {
      return const BannedScreen();
    }
    if (userData['role'] == 'admin') {
      return const AdminDashboard();
    }
    return UserDashboard(userData: userData);
  }
}
