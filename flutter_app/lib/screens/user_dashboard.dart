import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import 'deposit_screen.dart';
import 'withdraw_screen.dart';
import 'transfer_screen.dart';
import 'loans_screen.dart';
import 'transactions_screen.dart';
import 'notification_screen.dart';
import 'support_screen.dart';
import 'login_screen.dart';
import 'banned_screen.dart';
import 'set_withdrawal_pin_screen.dart';
import 'profile_screen.dart';
import 'about_screen.dart';

class UserDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserDashboard({super.key, required this.userData});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  late String _name;
  late double _balance;
  late String _cardNumber;
  late String _cardExpiry;
  late String _cardCvv;
  String _currency = 'USD';
  String? _profileImage;
  bool _showCardDetails = false;
  bool _loggingOut = false;
  bool _refreshing = false;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _name = widget.userData['name'] ?? 'User';
    _balance = double.tryParse(widget.userData['balance']?.toString() ?? '0') ?? 0;
    _cardNumber = widget.userData['card_number'] ?? '**** **** **** ****';
    _cardExpiry = widget.userData['card_expiry'] ?? '**/**';
    _cardCvv = widget.userData['card_cvv'] ?? '***';
    _currency = widget.userData['currency'] ?? 'USD';
    _profileImage = widget.userData['profile_image'];
    _loadDashboard();
    _loadUnreadCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.userData['has_withdrawal_pin'] != true) {
        _promptSetPin();
      }
    });
  }

  Future<void> _promptSetPin() async {
    final loc = AppLocalizations.of(context);
    final set = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SetWithdrawalPinScreen()),
    );
    if (set == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.tr('withdrawal_pin.set_success')),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      _loadDashboard();
    }
  }

  Future<void> _loadDashboard() async {
    if (!_refreshing) setState(() => _refreshing = true);
    try {
      final result = await ApiService.getDashboard();
      if (!mounted) return;
      if (result['status'] == 'banned') {
        await ApiService.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BannedScreen()),
          (route) => false,
        );
        return;
      }
      if (result['user'] != null) {
        setState(() {
          _balance = double.tryParse(result['user']['balance']?.toString() ?? '0') ?? 0;
          _cardNumber = result['user']['card_number'] ?? _cardNumber;
          _cardExpiry = result['user']['card_expiry'] ?? _cardExpiry;
          _cardCvv = result['user']['card_cvv'] ?? _cardCvv;
          _currency = ApiService.userCurrency;
          _profileImage = result['user']['profile_image'] ?? _profileImage;
          _recentTransactions = (result['recent_transactions'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ?? [];
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _loadUnreadCount() async {
    try {
      final result = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() => _unreadCount = result['unread_count'] ?? 0);
    } catch (_) {}
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
    _loadUnreadCount();
  }

  Future<void> _openScreen(Widget screen) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (result != null) {
      setState(() => _balance = double.tryParse(result.toString()) ?? _balance);
      _loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(loc),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Column(
                    children: [
                      _buildCard(loc),
                      const SizedBox(height: 24),
                      _buildQuickActions(loc),
                      const SizedBox(height: 24),
                      _buildRecentTransactions(loc),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'support',
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            );
            _loadUnreadCount();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.chat_bubble, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  String _profileImageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${ApiService.baseUrl}/$path';
  }

  Widget _buildHeader(AppLocalizations loc) {
    final profileImage = _profileImage;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  setState(() => _currency = ApiService.userCurrency);
                  _loadDashboard();
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withAlpha(30),
                      backgroundImage: profileImage != null && profileImage.toString().isNotEmpty
                          ? NetworkImage(_profileImageUrl(profileImage))
                          : null,
                      child: profileImage == null || profileImage.toString().isEmpty
                          ? Text(
                              _name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.tr('dashboard.welcome'), style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14)),
                        Text(_name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: _openNotifications,
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: Text(
                              '$_unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: _refreshing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () { _loadDashboard(); _loadUnreadCount(); },
                  ),
                  IconButton(
                    icon: _loggingOut
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.logout, color: Colors.white),
                    onPressed: _logout,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCardNumber(String card) {
    final cleaned = card.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      if (_showCardDetails) {
        buffer.write(cleaned[i]);
      } else {
        buffer.write(i < cleaned.length - 4 ? '*' : cleaned[i]);
      }
    }
    return buffer.toString();
  }

  Widget _buildCard(AppLocalizations loc) {
    final displayCardNumber = _formatCardNumber(_cardNumber);
    final displayCvv = _showCardDetails ? _cardCvv : '***';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.tr('dashboard.brand'), style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                Row(
                  children: [
                    SizedBox(
                      width: 40, height: 24,
                      child: Stack(
                        children: [
                          Positioned(left: 0, child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFFFF5722), shape: BoxShape.circle))),
                          Positioned(left: 12, child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFFFFC107), shape: BoxShape.circle))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _showCardDetails = !_showCardDetails),
                      child: Icon(
                        _showCardDetails ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70, size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.tr('dashboard.balance'), style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 10, letterSpacing: 1)),
                    Text(_showCardDetails ? _currencyFormat().format(_balance) : '****', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(_name.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 16),
            Text(loc.tr('dashboard.card_number'), style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 10, letterSpacing: 1)),
            Text(displayCardNumber, style: const TextStyle(color: Colors.white, fontSize: 17, letterSpacing: 2, fontWeight: FontWeight.w500)),
            const SizedBox(height: 14),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.tr('dashboard.expires'), style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(_cardExpiry, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(width: 36),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.tr('dashboard.cvv'), style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(displayCvv, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.tr('dashboard.quick_actions'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                Icons.add_circle_outline, loc.tr('dashboard.deposit'),
                const Color(0xFF2E7D32), const Color(0xFFE8F5E9),
                () => _openScreen(const DepositScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionCard(
                Icons.remove_circle_outline, loc.tr('dashboard.withdraw'),
                const Color(0xFFD32F2F), const Color(0xFFFFEBEE),
                () => _openScreen(const WithdrawScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                Icons.swap_horiz, loc.tr('dashboard.transfer'),
                const Color(0xFFE65100), const Color(0xFFFFF3E0),
                () => _openScreen(const TransferScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionCard(
                Icons.account_balance, loc.tr('dashboard.loans'),
                const Color(0xFF7B1FA2), const Color(0xFFF3E5F5),
                () => _openScreen(const LoansScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                Icons.info_outline, loc.tr('about.title'),
                const Color(0xFF1A237E), const Color(0xFFE8EAF6),
                () => _openScreen(const AboutScreen()),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, Color color, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.tr('dashboard.recent_tx'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
            TextButton.icon(
              onPressed: () => _openScreen(const TransactionsScreen()),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(loc.tr('dashboard.view_all')),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF1565C0)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
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
              children: [
                Icon(Icons.receipt_long, size: 40, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text(loc.tr('dashboard.no_tx'), style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else
          ...(_recentTransactions.take(5).map((t) {
            final type = t['type'] ?? '';
            final amount = double.tryParse(t['amount']?.toString() ?? '0') ?? 0;
            final date = t['created_at'] ?? '';
            final isDeposit = type == 'deposit';

            IconData icon;
            Color iconColor;
            Color bgColor;
            if (type == 'deposit') {
              icon = Icons.arrow_downward;
              iconColor = const Color(0xFF2E7D32);
              bgColor = const Color(0xFFE8F5E9);
            } else if (type == 'withdraw') {
              icon = Icons.arrow_upward;
              iconColor = const Color(0xFFD32F2F);
              bgColor = const Color(0xFFFFEBEE);
            } else {
              icon = Icons.swap_horiz;
              iconColor = const Color(0xFFE65100);
              bgColor = const Color(0xFFFFF3E0);
            }

            String typeLabel;
            if (type == 'deposit') {
              typeLabel = loc.tr('tx.type_deposit');
            } else if (type == 'withdraw') {
              typeLabel = loc.tr('tx.type_withdraw');
            } else if (type == 'transfer') {
              typeLabel = loc.tr('tx.type_transfer');
            } else {
              typeLabel = type.toUpperCase();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(typeLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(_formatDate(date), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${isDeposit ? '+' : '-'}${_currencyFormat().format(amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDeposit ? iconColor : iconColor,
                        ),
                      ),
                    ],
                  ),
                    if (type == 'withdraw' && t['payment_method'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 52),
                      child: Row(
                        children: [
                          Icon(Icons.payment, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${loc.tr('withdraw.method_${t['payment_method']}')}: ${t['payment_details'] ?? ''}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (type == 'transfer' && t['recipient_account'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 52),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${t['recipient_name'] ?? ''} - ${t['recipient_account']}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          })),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  NumberFormat _currencyFormat() {
    final symbol = ApiService.currencySymbol;
    return NumberFormat.currency(symbol: symbol);
  }
}
