import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../l10n/app_localizations.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _termController = TextEditingController(text: '1');
  String _loanType = 'Personal';
  List<LoanModel> _loans = [];
  bool _loading = true;
  bool _processing = false;

  static const List<String> _loanTypes = [
    'Personal', 'Business', 'Education', 'Home', 'Auto', 'Medical', 'Debt Consolidation', 'Other',
  ];
  static const Map<String, String> _loanTypeKeys = {
    'Personal': 'loans.type_personal',
    'Business': 'loans.type_business',
    'Education': 'loans.type_education',
    'Home': 'loans.type_home',
    'Auto': 'loans.type_auto',
    'Medical': 'loans.type_medical',
    'Debt Consolidation': 'loans.type_debt',
    'Other': 'loans.type_other',
  };

  @override
  void initState() {
    super.initState();
    _loadLoans();
    _amountController.addListener(_onFieldChange);
    _termController.addListener(_onFieldChange);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onFieldChange);
    _termController.removeListener(_onFieldChange);
    _amountController.dispose();
    _reasonController.dispose();
    _termController.dispose();
    super.dispose();
  }

  double? get _loanAmount => double.tryParse(_amountController.text);
  int? get _loanTerm => int.tryParse(_termController.text);
  double? get _totalRepayment => _loanAmount != null && _loanTerm != null && _loanAmount! > 0 && _loanTerm! > 0
      ? _loanAmount! + (_loanAmount! * 0.04)
      : null;

  void _onFieldChange() => setState(() {});

  Future<void> _loadLoans() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getLoans();
      if (!mounted) return;
      setState(() {
        _loans = (result['loans'] as List?)?.map((e) => LoanModel.fromJson(e)).toList() ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyLoan() async {
    final loc = AppLocalizations.of(context);
    final amount = _loanAmount;
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('deposit.amount_required'))));
      return;
    }
    final term = _loanTerm;
    if (term == null || term < 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('loans.term'))));
      return;
    }

    setState(() => _processing = true);
    try {
      final result = await ApiService.applyLoan(amount, loanTerm: term, loanType: _loanType, reason: _reasonController.text.trim());
      if (!mounted) return;
      if (result['success'] == true) {
        _amountController.clear();
        _reasonController.clear();
        _termController.text = '1';
        setState(() => _loanType = 'Personal');
        _loadLoans();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('loans.submitted'))));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? loc.tr('common.failed'))));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('common.connection_error'))));
    } finally { if (mounted) setState(() => _processing = false); }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currency = NumberFormat.currency(symbol: ApiService.currencySymbol);
    final total = _totalRepayment;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(loc.tr('loans.title')),
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
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
                    child: const Icon(Icons.account_balance, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.tr('loans.header'),
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.tr('loans.subtitle'),
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
                      Text(loc.tr('loans.application'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: loc.tr('loans.amount'),
                          prefixText: '${ApiService.currencySymbol} ',
                          prefixIcon: const Icon(Icons.monetization_on_outlined, color: Color(0xFF7B1FA2)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF7B1FA2), width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FE),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _termController,
                              decoration: InputDecoration(
                                labelText: loc.tr('loans.term'),
                                suffixText: loc.tr('loans.months'),
                                prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF7B1FA2), size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF7B1FA2), width: 2),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F9FE),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _loanType,
                        items: _loanTypes.map((t) => DropdownMenuItem(value: t, child: Text(loc.tr(_loanTypeKeys[t]!)))).toList(),
                        onChanged: (v) => setState(() => _loanType = v!),
                        decoration: InputDecoration(
                          labelText: loc.tr('loans.type'),
                          prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF7B1FA2), size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF7B1FA2), width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FE),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _reasonController,
                        decoration: InputDecoration(
                          labelText: loc.tr('loans.reason'),
                          prefixIcon: const Icon(Icons.edit_note, color: Color(0xFF7B1FA2)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF7B1FA2), width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FE),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B1FA2).withAlpha(8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF7B1FA2).withAlpha(30)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(loc.tr('loans.amount'), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                Text(currency.format(_loanAmount ?? 0), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(loc.tr('loans.interest_rate'), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                Text('4.00%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF7B1FA2))),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(loc.tr('loans.total_repayment'), style: TextStyle(color: Colors.grey[800], fontSize: 15, fontWeight: FontWeight.w700)),
                                Text(
                                  total != null && _loanAmount! > 0 ? currency.format(total) : '---',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF7B1FA2)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B1FA2).withAlpha(60),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: FilledButton(
                            onPressed: (_loanAmount ?? 0) <= 0 || (_loanTerm ?? 0) < 1 || _processing ? null : _applyLoan,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _processing
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : Text(loc.tr('loans.apply'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(loc.tr('loans.history'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
              ),
            ),
            const SizedBox(height: 12),
            _loading
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _loans.isEmpty
                    ? SizedBox(
                        height: 120,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_empty, size: 40, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text(loc.tr('loans.empty'), style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _loans.length,
                        itemBuilder: (ctx, i) {
                          final loan = _loans[i];
                          final Color statusColor;
                          final IconData statusIcon;
                          final String statusText;
                          switch (loan.status) {
                            case 'approved':
                              statusColor = Colors.green;
                              statusIcon = Icons.check_circle;
                              statusText = loc.tr('status.approved');
                              break;
                            case 'rejected':
                              statusColor = Colors.red;
                              statusIcon = Icons.cancel;
                              statusText = loc.tr('status.rejected');
                              break;
                            default:
                              statusColor = Colors.orange;
                              statusIcon = Icons.hourglass_empty;
                              statusText = loc.tr('status.pending');
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(6),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: statusColor.withAlpha(20),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(statusIcon, color: statusColor, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(currency.format(loan.amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withAlpha(20),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(DateFormat('MMM dd, yyyy').format(loan.createdAt), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7B1FA2).withAlpha(15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('${loan.interest}%', style: const TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.w700, fontSize: 14)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.category_outlined, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(loan.loanType, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    const SizedBox(width: 16),
                                    Icon(Icons.calendar_today, size: 13, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text('${loan.loanTerm}mo', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  ],
                                ),
                                if (loan.reason != null && loan.reason!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(loan.reason!, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  ),
                                if (loan.rejectionReason != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text('${loc.tr('common.reason')} ${loan.rejectionReason}', style: TextStyle(color: Colors.red[400], fontSize: 12)),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
