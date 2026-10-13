import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _methods = [];
  int? _selectedMethodId;
  File? _proofFile;
  bool _loadingMethods = true;
  String? _proofFileName;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadMethods() async {
    final result = await ApiService.getPaymentMethods();
    if (!mounted) return;
    setState(() {
      _methods = (result['methods'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _loadingMethods = false;
    });
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _proofFile = File(picked.path);
        _proofFileName = picked.name;
      });
    }
  }

  Future<void> _deposit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).tr('deposit.amount_required'))));
      return;
    }
    if (_selectedMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).tr('deposit.method_required'))));
      return;
    }
    if (_proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).tr('deposit.proof_required'))));
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ApiService.deposit(
        amount, _descController.text.trim(),
        paymentMethodId: _selectedMethodId,
        proofFile: _proofFile,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? AppLocalizations.of(context).tr('deposit.submitted'))));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? AppLocalizations.of(context).tr('common.failed'))));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).tr('common.connection_error'))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(loc.tr('deposit.title')),
        backgroundColor: const Color(0xFF2E7D32),
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
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
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
                          child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.tr('deposit.header'),
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.tr('deposit.subtitle'),
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
                            Text(loc.tr('deposit.payment_method'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                            const SizedBox(height: 16),
                            ..._methods.map((m) {
                              final selected = _selectedMethodId == m['id'];
                              final details = (m['details'] as String?)?.replaceAll('\\n', '\n') ?? '';
                              final methodId = m['id'] is int ? m['id'] : int.parse(m['id'].toString());
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected ? const Color(0xFF2E7D32) : Colors.grey[200]!,
                                    width: selected ? 2 : 1,
                                  ),
                                  color: selected ? const Color(0xFF2E7D32).withAlpha(6) : Colors.white,
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => setState(() => _selectedMethodId = methodId),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 22, height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: selected ? const Color(0xFF2E7D32) : Colors.grey[400]!,
                                              width: 2,
                                            ),
                                            color: selected ? const Color(0xFF2E7D32) : Colors.transparent,
                                          ),
                                          child: selected
                                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                                              : null,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                              if (details.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(details, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                            Text(loc.tr('deposit.details'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _amountController,
                              decoration: InputDecoration(
                                labelText: loc.tr('common.amount'),
                                prefixText: '${ApiService.currencySymbol} ',
                                prefixIcon: const Icon(Icons.monetization_on_outlined, color: Color(0xFF2E7D32)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
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
                                prefixIcon: const Icon(Icons.notes_outlined, color: Color(0xFF2E7D32)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FE),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(loc.tr('deposit.proof'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _pickProof,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!, width: 1.5, strokeAlign: BorderSide.strokeAlignCenter),
                                  borderRadius: BorderRadius.circular(14),
                                  color: const Color(0xFFF8F9FE),
                                ),
                                child: _proofFile != null
                                    ? Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.file(_proofFile!, height: 100, width: 100, fit: BoxFit.cover),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(_proofFileName ?? loc.tr('deposit.proof_uploaded'), style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.w500)),
                                          TextButton.icon(
                                            onPressed: () => setState(() { _proofFile = null; _proofFileName = null; }),
                                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                            label: Text(loc.tr('deposit.remove'), style: TextStyle(color: Colors.red, fontSize: 12)),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey[400]),
                                          const SizedBox(height: 8),
                                          Text(loc.tr('deposit.upload_prompt'), style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                                          Text(loc.tr('deposit.upload_hint'), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                        ],
                                      ),
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
                                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2E7D32).withAlpha(60),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: FilledButton(
                                  onPressed: _loading ? null : _deposit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: _loading
                                      ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                      : Text(loc.tr('deposit.submit'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
