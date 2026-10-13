import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';
import 'banned_screen.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;
  String _selectedLang = 'en';

  static const List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Español'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'ar', 'name': 'العربية'},
    {'code': 'pt', 'name': 'Português'},
    {'code': 'de', 'name': 'Deutsch'},
    {'code': 'it', 'name': 'Italiano'},
    {'code': 'ru', 'name': 'Русский'},
    {'code': 'zh', 'name': '中文'},
    {'code': 'ja', 'name': '日本語'},
    {'code': 'ko', 'name': '한국어'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final appState = NextBankApp.of(context);
    if (appState != null) {
      setState(() => _selectedLang = appState.currentLocale.languageCode);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final loc = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final result = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;

      if (result['status'] == 'banned') {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => const BannedScreen(),
        ));
        return;
      }

      if (result['success'] == true && result['user'] != null) {
        final user = result['user'];
        FcmService.saveTokenAfterLogin();
        if (user['role'] == 'admin') {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => const AdminDashboard(),
          ));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => UserDashboard(userData: Map<String, dynamic>.from(user)),
          ));
        }
      } else {
        _showError(result['error'] ?? loc.tr('login.failed'));
      }
    } catch (e) {
      _showError(loc.tr('login.connection_error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF01579B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset('assets/logo.png', height: 72, fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 6),
                          Text(loc.tr('login.welcome'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(loc.tr('login.subtitle'),
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedLang,
                                icon: Icon(Icons.language, color: Colors.grey.shade500, size: 20),
                                items: _languages.map((l) => DropdownMenuItem(
                                  value: l['code'],
                                  child: Text(l['name']!, style: const TextStyle(fontSize: 14)),
                                )).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedLang = v);
                                    NextBankApp.of(context)?.setLocale(v);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('login.email_required') : null,
                            decoration: InputDecoration(
                              hintText: loc.tr('login.email_hint'),
                              prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            validator: (v) => (v == null || v.isEmpty) ? loc.tr('login.password_required') : null,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              hintText: loc.tr('login.password_hint'),
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade500),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                              ),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: Text(loc.tr('login.forgot_password'), style: TextStyle(fontSize: 12, color: const Color(0xFF0D47A1).withValues(alpha: 0.8), decoration: TextDecoration.underline)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0D47A1)]),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: FilledButton(
                                onPressed: _loading ? null : _login,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _loading
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : Text(loc.tr('login.sign_in'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          TextSpan(text: loc.tr('login.no_account'), style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                          TextSpan(text: loc.tr('login.register_link'), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, decoration: TextDecoration.underline)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
