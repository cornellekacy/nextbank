import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _pinController = TextEditingController();
  final _detailsController = TextEditingController();
  final _maxitCodeController = TextEditingController();
  bool _loading = false;
  bool _obscurePin = true;
  List<Map<String, dynamic>> _methods = [];
  bool _loadingMethods = true;
  String _selectedMethod = '';

  static const String _orangeMoneyId = 'orange_money_hardcoded';

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _pinController.dispose();
    _detailsController.dispose();
    _maxitCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadMethods() async {
    final result = await ApiService.getWithdrawalPaymentMethods();
    if (!mounted) return;
    setState(() {
      _methods = (result['methods'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _loadingMethods = false;
    });
  }

  bool get _isOrangeMoney => _selectedMethod == _orangeMoneyId;

  Future<void> _withdraw() async {
    final loc = AppLocalizations.of(context);
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('deposit.amount_required'))));
      return;
    }
    if (_selectedMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('withdraw.method_required'))));
      return;
    }
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('withdraw.details_required'))));
      return;
    }
    if (_isOrangeMoney && _maxitCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Maxit Code is required')));
      return;
    }
    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('withdrawal_pin.pin_required'))));
      return;
    }

    setState(() => _loading = true);
    try {
      String paymentMethod;
      String paymentDetails;
      if (_isOrangeMoney) {
        paymentMethod = 'Orange Money';
        paymentDetails = '${_detailsController.text.trim()}|maxit:${_maxitCodeController.text.trim()}';
      } else {
        paymentMethod = _selectedMethod;
        paymentDetails = _detailsController.text.trim();
      }
      final result = await ApiService.withdraw(amount, _descController.text.trim(),
          pin: _pinController.text,
          paymentMethod: paymentMethod,
          paymentDetails: paymentDetails);
      if (!mounted) return;
      if (result['success'] == true) {
        Navigator.of(context).pop(result['balance']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? loc.tr('common.failed'))));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('common.connection_error'))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildMethodOption({
    required String id,
    required String name,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    final selected = _selectedMethod == id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? accentColor : Colors.grey[200]!,
          width: selected ? 2 : 1,
        ),
        color: selected ? accentColor.withAlpha(8) : Colors.white,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() {
          _selectedMethod = id;
          _maxitCodeController.clear();
          _detailsController.clear();
        }),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? accentColor : Colors.grey[400]!,
                    width: 2,
                  ),
                  color: selected ? accentColor : Colors.transparent,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: selected ? accentColor : Colors.grey[800])),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(loc.tr('withdraw.title')),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loadingMethods
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.tr('withdraw.header'),
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.tr('withdraw.subtitle'),
                          style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Transform.translate(
                      offset: const Offset(0, -24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.tr('withdraw.payment_method'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                            const SizedBox(height: 16),
                            _buildMethodOption(
                              id: _orangeMoneyId,
                              name: 'Orange Money',
                              subtitle: 'Mobile money transfer',
                              accentColor: const Color(0xFFFF6D00),
                              icon: Icons.phone_android,
                            ),
                            ..._methods.map((m) {
                              final methodId = m['name']?.toString() ?? '';
                              final details = (m['details'] as String?)?.replaceAll('\\n', '\n') ?? '';
                              return _buildMethodOption(
                                id: methodId,
                                name: methodId,
                                subtitle: details,
                                accentColor: const Color(0xFF1A237E),
                                icon: Icons.payment,
                              );
                            }),
                            const SizedBox(height: 24),
                            Text(loc.tr('withdraw.details'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _amountController,
                              decoration: InputDecoration(
                                labelText: loc.tr('common.amount'),
                                prefixText: '${ApiService.currencySymbol} ',
                                prefixIcon: const Icon(Icons.monetization_on_outlined, color: Color(0xFFD32F2F)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FE),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _descController,
                              decoration: InputDecoration(
                                labelText: loc.tr('common.description'),
                                prefixIcon: const Icon(Icons.notes_outlined, color: Color(0xFFD32F2F)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FE),
                              ),
                            ),
                            if (_selectedMethod.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Text(loc.tr('withdraw.your_details'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _detailsController,
                                decoration: InputDecoration(
                                  hintText: loc.tr('withdraw.details_hint'),
                                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFD32F2F)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FE),
                                ),
                              ),
                            ],
                            if (_isOrangeMoney) ...[
                              const SizedBox(height: 16),
                              TextField(
                                controller: _maxitCodeController,
                                decoration: InputDecoration(
                                  labelText: 'Maxit Code',
                                  hintText: 'Enter Maxit Code',
                                  prefixIcon: const Icon(Icons.vpn_key_outlined, color: Color(0xFFFF6D00)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F9FE),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            TextField(
                              controller: _pinController,
                              obscureText: _obscurePin,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                              decoration: InputDecoration(
                                labelText: loc.tr('withdrawal_pin.pin_label'),
                                prefixIcon: const Icon(Icons.pin_outlined, color: Color(0xFFD32F2F)),
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
                                  borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FE),
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD32F2F).withAlpha(60),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: FilledButton(
                                  onPressed: _loading ? null : _withdraw,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: _loading
                                      ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                      : Text(loc.tr('withdraw.submit'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
