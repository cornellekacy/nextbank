import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../l10n/app_localizations.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionModel> _transactions = [];
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getTransactions(page: _page);
      if (!mounted) return;
      setState(() {
        _transactions = (result['transactions'] as List?)?.map((e) => TransactionModel.fromJson(e)).toList() ?? [];
        _totalPages = result['pages'] ?? 1;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'deposit': return Icons.arrow_downward;
      case 'withdraw': return Icons.arrow_upward;
      case 'transfer': return Icons.swap_horiz;
      default: return Icons.receipt;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'deposit': return Colors.green;
      case 'withdraw': return Colors.red;
      case 'transfer': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _methodLabel(String method) {
    final loc = AppLocalizations.of(context);
    return loc.tr('withdraw.method_$method');
  }

  String _typeLabel(String type, AppLocalizations loc) {
    switch (type) {
      case 'deposit': return loc.tr('tx.type_deposit');
      case 'withdraw': return loc.tr('tx.type_withdraw');
      case 'transfer': return loc.tr('tx.type_transfer');
      default: return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currency = NumberFormat.currency(symbol: ApiService.currencySymbol);

    return Scaffold(
      appBar: AppBar(title: Text(loc.tr('tx.title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(child: Text(loc.tr('tx.empty')))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _transactions.length,
                          itemBuilder: (ctx, i) {
                            final t = _transactions[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getColor(t.type).withAlpha(30),
                                  child: Icon(_getIcon(t.type), color: _getColor(t.type)),
                                ),
                                title: Text(_typeLabel(t.type, loc), style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(DateFormat('MMM dd, yyyy HH:mm').format(t.createdAt)),
                                    if (t.type == 'transfer' && t.recipientAccount != null)
                                      Text(
                                        '${t.recipientName ?? ''} - ${t.recipientAccount}',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    if (t.paymentMethod != null)
                                      Text('${_methodLabel(t.paymentMethod!)}: ${t.paymentDetails ?? ''}'),
                                    if (t.status != 'approved')
                                      Text(
                                        '${t.status.toUpperCase()}${t.rejectionReason != null ? ' - ${t.rejectionReason}' : ''}',
                                        style: TextStyle(
                                          color: t.status == 'rejected' ? Colors.red : Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  '${t.type == 'deposit' ? '+' : '-'}${currency.format(t.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getColor(t.type),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (_totalPages > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _page > 1 ? () { _page--; _loadTransactions(); } : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(loc.tr('tx.page', {'page': '$_page', 'total': '$_totalPages'})),
                      IconButton(
                        onPressed: _page < _totalPages ? () { _page++; _loadTransactions(); } : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}
