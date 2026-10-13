import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '587');
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _fromEmailCtrl = TextEditingController();
  final _fromNameCtrl = TextEditingController(text: 'NextBank');
  final _testEmailCtrl = TextEditingController();
  final _smsApiKeyCtrl = TextEditingController();
  final _smsSenderNameCtrl = TextEditingController(text: 'NextBank');
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _showPass = false;
  bool _showSmsKey = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _fromEmailCtrl.dispose();
    _fromNameCtrl.dispose();
    _testEmailCtrl.dispose();
    _smsApiKeyCtrl.dispose();
    _smsSenderNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getSettings();
      if (result['success'] == true && result['settings'] != null) {
        final s = result['settings'] as Map<String, dynamic>;
        _hostCtrl.text = s['smtp_host'] ?? '';
        _portCtrl.text = s['smtp_port'] ?? '587';
        _userCtrl.text = s['smtp_user'] ?? '';
        _passCtrl.text = s['smtp_pass'] ?? '';
        _fromEmailCtrl.text = s['smtp_from_email'] ?? '';
        _fromNameCtrl.text = s['smtp_from_name'] ?? 'NextBank';
        _smsApiKeyCtrl.text = s['sendchamp_api_key'] ?? '';
        _smsSenderNameCtrl.text = s['sendchamp_sender_name'] ?? 'NextBank';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      final result = await ApiService.saveSettings({
        'smtp_host': _hostCtrl.text.trim(),
        'smtp_port': _portCtrl.text.trim(),
        'smtp_user': _userCtrl.text.trim(),
        'smtp_pass': _passCtrl.text,
        'smtp_from_email': _fromEmailCtrl.text.trim(),
        'smtp_from_name': _fromNameCtrl.text.trim(),
        'sendchamp_api_key': _smsApiKeyCtrl.text.trim(),
        'sendchamp_sender_name': _smsSenderNameCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? loc.tr('settings.saved'))));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _test() async {
    final loc = AppLocalizations.of(context);
    final to = _testEmailCtrl.text.trim();
    if (to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('settings.test_email_required'))));
      return;
    }
    setState(() => _testing = true);
    try {
      final result = await ApiService.testSmtp({
        'to': to,
        'host': _hostCtrl.text.trim(),
        'port': _portCtrl.text.trim(),
        'user': _userCtrl.text.trim(),
        'pass': _passCtrl.text,
        'from_name': _fromNameCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? result['error'] ?? loc.tr('settings.tested')),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(loc.tr('settings.title')),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(loc.tr('settings.save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.settings, color: Colors.grey[700], size: 20),
                            const SizedBox(width: 8),
                            Text(loc.tr('settings.config'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _hostCtrl,
                          decoration: _input(loc.tr('settings.host'), loc.tr('settings.host_hint'), Icons.dns_outlined),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _portCtrl,
                          decoration: _input(loc.tr('settings.port'), loc.tr('settings.port_hint'), Icons.numbers),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _userCtrl,
                          decoration: _input(loc.tr('settings.username'), loc.tr('settings.username_hint'), Icons.person_outline),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passCtrl,
                          obscureText: !_showPass,
                          decoration: _input(loc.tr('settings.password'), '', Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_showPass ? Icons.visibility : Icons.visibility_off, size: 20),
                              onPressed: () => setState(() => _showPass = !_showPass),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _fromEmailCtrl,
                          decoration: _input(loc.tr('settings.from_email'), loc.tr('settings.from_email_hint'), Icons.email_outlined),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _fromNameCtrl,
                          decoration: _input(loc.tr('settings.from_name'), loc.tr('settings.from_name_hint'), Icons.badge_outlined),
                        ),
                      ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sms, color: Colors.grey[700], size: 20),
                          const SizedBox(width: 8),
                          Text(loc.tr('settings.sms_title'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _smsApiKeyCtrl,
                        obscureText: !_showSmsKey,
                        decoration: _input(loc.tr('settings.sms_api_key'), '', Icons.vpn_key_outlined).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_showSmsKey ? Icons.visibility : Icons.visibility_off, size: 20),
                            onPressed: () => setState(() => _showSmsKey = !_showSmsKey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _smsSenderNameCtrl,
                        decoration: _input(loc.tr('settings.sms_sender_name'), '', Icons.badge_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(loc.tr('settings.section_test'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _testEmailCtrl,
                          decoration: _input(loc.tr('settings.test_email'), loc.tr('settings.test_email_hint'), Icons.send_outlined),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
                            ),
                            child: FilledButton(
                              onPressed: _testing ? null : _test,
                              style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                              child: _testing
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(loc.tr('settings.send_test'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  InputDecoration _input(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1A237E)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FE),
    );
  }
}
