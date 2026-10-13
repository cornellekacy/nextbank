import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class SetWithdrawalPinScreen extends StatefulWidget {
  const SetWithdrawalPinScreen({super.key});

  @override
  State<SetWithdrawalPinScreen> createState() => _SetWithdrawalPinScreenState();
}

class _SetWithdrawalPinScreenState extends State<SetWithdrawalPinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    if (!_formKey.currentState!.validate()) return;

    final loc = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final result = await ApiService.setWithdrawalPin(_pinController.text);
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.tr('withdrawal_pin.set_success')),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.of(context).pop(true);
      } else {
        _showError(result['error'] ?? loc.tr('common.failed'));
      }
    } catch (e) {
      _showError(loc.tr('common.connection_error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(loc.tr('withdrawal_pin.title')),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pin, size: 56, color: Color(0xFF1A237E)),
                ),
                const SizedBox(height: 20),
                Text(loc.tr('withdrawal_pin.subtitle'), style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _pinController,
                        obscureText: _obscurePin,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                        validator: (v) => (v == null || v.length != 4) ? loc.tr('withdrawal_pin.pin_invalid') : null,
                        decoration: InputDecoration(
                          labelText: loc.tr('withdrawal_pin.pin_label'),
                          hintText: loc.tr('withdrawal_pin.pin_hint'),
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade500),
                            onPressed: () => setState(() => _obscurePin = !_obscurePin),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FE),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscureConfirm,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                        validator: (v) => (v != _pinController.text) ? loc.tr('withdrawal_pin.confirm_mismatch') : null,
                        decoration: InputDecoration(
                          labelText: loc.tr('withdrawal_pin.confirm_label'),
                          hintText: loc.tr('withdrawal_pin.confirm_hint'),
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade500),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FE),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0D47A1)]),
                            boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: FilledButton(
                            onPressed: _loading ? null : _savePin,
                            style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            child: _loading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : Text(loc.tr('withdrawal_pin.save'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
