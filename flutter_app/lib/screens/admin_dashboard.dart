import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'notification_screen.dart';
import 'admin_settings_screen.dart';
import 'support_screen.dart';
import 'ticket_detail_screen.dart';
import '../l10n/app_localizations.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _allUsers = [];
  List<LoanModel> _pendingLoans = [];
  List<Map<String, dynamic>> _pendingWithdrawals = [];
  List<Map<String, dynamic>> _pendingDeposits = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _withdrawalPaymentMethods = [];
  List<Map<String, dynamic>> _openTickets = [];
  bool _loading = true;
  bool _refreshing = false;
  bool _processing = false;
  int _unreadCount = 0;
  String _userSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadData();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!_loading) setState(() => _refreshing = true);
    try {
      final results = await Future.wait([
        ApiService.getAllUsers().catchError((_) => <String, dynamic>{}),
        ApiService.getAdminLoans('pending').catchError((_) => <String, dynamic>{}),
        ApiService.getAdminWithdrawals('pending').catchError((_) => <String, dynamic>{}),
        ApiService.getAdminDeposits('pending').catchError((_) => <String, dynamic>{}),
        ApiService.managePaymentMethods(method: 'GET').catchError((_) => <String, dynamic>{}),
        ApiService.getTickets('open').catchError((_) => <String, dynamic>{}),
        ApiService.manageWithdrawalPaymentMethods(method: 'GET').catchError((_) => <String, dynamic>{}),
      ]);
      final users = results[0];
      final loans = results[1];
      final withdrawals = results[2];
      final deposits = results[3];
      final methods = results[4];
      final tickets = results[5];
      final wMethods = results[6];
      if (!mounted) return;
      setState(() {
        _allUsers = (users['users'] as List?)?.map((e) => UserModel.fromJson(e)).toList() ?? [];
        _pendingLoans = (loans['loans'] as List?)?.map((e) => LoanModel.fromJson(e)).toList() ?? [];
        _pendingWithdrawals = (withdrawals['withdrawals'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        _pendingDeposits = (deposits['deposits'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        _paymentMethods = (methods['methods'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        _withdrawalPaymentMethods = (wMethods['methods'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        _openTickets = (tickets['tickets'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final result = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() => _unreadCount = result['unread_count'] ?? 0);
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
    _loadUnreadCount();
  }

  Future<void> _handleUser(int userId, String action) async {
    final loc = AppLocalizations.of(context);
    if (_processing) return;
    setState(() => _processing = true);
    try {
      if (action == 'reject') {
        final reason = await _showRejectReasonDialog();
        if (reason == null) { setState(() => _processing = false); return; }
        final result = await ApiService.approveUser(userId, 'reject', reason: reason);
        if (result['success'] == true) { _loadData(); _showSnack(result['message'] ?? loc.tr('common.done')); }
        else { _showSnack(result['error'] ?? loc.tr('common.failed')); }
        return;
      }
      final result = await ApiService.approveUser(userId, action);
      if (result['success'] == true) { _loadData(); _showSnack(result['message'] ?? loc.tr('common.done')); }
      else { _showSnack(result['error'] ?? loc.tr('common.failed')); }
    } finally { if (mounted) setState(() => _processing = false); }
  }

  Future<void> _handleVerifyEmail(int userId) async {
    final loc = AppLocalizations.of(context);
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final result = await ApiService.verifyEmail(userId, true);
      if (result['success'] == true) { _loadData(); _showSnack(loc.tr('admin.email_verified')); }
      else { _showSnack(result['error'] ?? loc.tr('common.failed')); }
    } finally { if (mounted) setState(() => _processing = false); }
  }

  Future<void> _handleResetPin(int userId) async {
    final loc = AppLocalizations.of(context);
    if (_processing) return;
    final pinController = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('admin.reset_pin_title')),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: InputDecoration(
            hintText: loc.tr('admin.reset_pin_hint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: Text(loc.tr('common.cancel'))),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(pinController.text), child: Text(loc.tr('common.confirm'))),
        ],
      ),
    );
    if (pin == null || pin.length != 4) return;
    setState(() => _processing = true);
    try {
      final result = await ApiService.adminResetPin(userId, pin);
      if (result['success'] == true) { _loadData(); _showSnack(loc.tr('admin.reset_pin_done')); }
      else { _showSnack(result['error'] ?? loc.tr('common.failed')); }
    } finally { if (mounted) setState(() => _processing = false); }
  }

  Future<void> _handleLoan(int loanId, String action) async {
    final loc = AppLocalizations.of(context);
    if (_processing) return;
    setState(() => _processing = true);
    try {
      if (action == 'reject') {
        final reason = await _showRejectReasonDialog();
        if (reason == null) { setState(() => _processing = false); return; }
        final result = await ApiService.approveLoan(loanId, 'reject', reason: reason);
        if (result['success'] == true) { _loadData(); _showSnack(result['message'] ?? loc.tr('common.done')); }
        return;
      }
      final result = await ApiService.approveLoan(loanId, action);
      if (result['success'] == true) { _loadData(); _showSnack(result['message'] ?? loc.tr('common.done')); }
      else { _showSnack(result['error'] ?? loc.tr('common.failed')); }
    } finally { if (mounted) setState(() => _processing = false); }
  }

  Future<void> _handleWithdrawal(int txId, String action) async {
    final loc = AppLocalizations.of(context);
    if (_processing) return;
    setState(() => _processing = true);
    try {
      if (action == 'reject') {
        final reason = await _showRejectReasonDialog();
        if (reason == null) { setState(() => _processing = false); return; }
        final result = await ApiService.approveWithdrawal(txId, 'reject', reason: reason);
        if (result['success'] == true) { _loadData(); _showSnack(result['message'] ?? loc.tr('common.done')); }
        return;
      }
      final result = await ApiService.approveWithdrawal(txId, action);
      if (result['success'] == true) { _loadData(); _showSnack(result['message'] ?? loc.tr('common.done')); }
      else { _showSnack(result['error'] ?? loc.tr('common.failed')); }
    } finally { if (mounted) setState(() => _processing = false); }
  }

  Future<void> _handleDeposit(int txId, String action) async {
    final loc = AppLocalizations.of(context);
    if (_processing) return;
    setState(() => _processing = true);
    try {
      if (action == 'reject') {
        final reason = await _showRejectReasonDialog();
        if (reason == null) { setState(() => _processing = false); return; }
        final result = await ApiService.approveDeposit(txId, 'reject', reason: reason);
        if (result['success'] == true) { _loadData(); _showSnack(result['message'] ?? loc.tr('common.done')); }
        return;
      }
      final result = await ApiService.approveDeposit(txId, action);
      if (result['success'] == true) { _loadData(); _showSnack(result['message'] ?? loc.tr('common.done')); }
      else { _showSnack(result['error'] ?? loc.tr('common.failed')); }
    } finally { if (mounted) setState(() => _processing = false); }
  }

  void _showSnack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _showRejectReasonDialog() {
    final loc = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('admin.reason_title')),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: loc.tr('admin.reason_hint'),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.tr('common.cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.tr('common.reject')),
          ),
        ],
      ),
    );
  }

  void _showFundsDialog(UserModel user) {
    final loc = AppLocalizations.of(context);
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final isAdd = ValueNotifier<bool>(true);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${isAdd.value ? loc.tr('admin.add') : loc.tr('admin.deduct')} ${loc.tr('admin.funds')} — ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: isAdd,
              builder: (_, val, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(loc.tr('admin.deduct'), style: TextStyle(color: val ? Colors.grey : Colors.red)),
                  Switch(value: val, onChanged: (v) => isAdd.value = v, activeColor: Colors.green),
                  Text(loc.tr('admin.add'), style: TextStyle(color: val ? Colors.green : Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
            ),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.tr('common.cancel'))),
          ValueListenableBuilder<bool>(
            valueListenable: isAdd,
            builder: (_, val, __) => FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) return;
                Navigator.pop(ctx);
                setState(() => _loading = true);
                try {
                  Map<String, dynamic> result;
                  if (val) {
                    result = await ApiService.adminAddFunds(user.id, amount, descCtrl.text);
                  } else {
                    result = await ApiService.adminDeductFunds(user.id, amount, descCtrl.text);
                  }
                  if (!mounted) return;
                  if (result['success'] == true) {
                    _loadData();
                    _showSnack(result['message'] ?? loc.tr('common.done'));
                  } else {
                    setState(() => _loading = false);
                    _showSnack(result['error'] ?? loc.tr('common.failed'));
                  }
                } catch (e) {
                  setState(() => _loading = false);
                  _showSnack('Error: $e');
                }
              },
              child: Text(val ? loc.tr('admin.add_funds') : loc.tr('admin.deduct_funds')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    final loc = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('admin.add_payment_method')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: loc.tr('admin.name'), border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: detailsCtrl, decoration: InputDecoration(labelText: loc.tr('admin.details'), border: const OutlineInputBorder()), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.tr('common.cancel'))),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || detailsCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _processing = true);
              try {
                await ApiService.managePaymentMethods(method: 'POST', name: nameCtrl.text.trim(), details: detailsCtrl.text.trim());
                _loadData();
              } finally { if (mounted) setState(() => _processing = false); }
            },
            child: Text(loc.tr('admin.add')),
          ),
        ],
      ),
    );
  }

  void _showEditPaymentMethodDialog(Map<String, dynamic> method) {
    final loc = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: method['name'] ?? '');
    final detailsCtrl = TextEditingController(text: method['details'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('admin.edit_payment_method')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: loc.tr('admin.name'), border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: detailsCtrl, decoration: InputDecoration(labelText: loc.tr('admin.details'), border: const OutlineInputBorder()), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.tr('common.cancel'))),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || detailsCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _processing = true);
              try {
                await ApiService.managePaymentMethods(
                  method: 'PUT',
                  id: method['id'] is int ? method['id'] : int.parse(method['id'].toString()),
                  name: nameCtrl.text.trim(),
                  details: detailsCtrl.text.trim(),
                  isActive: method['is_active'],
                );
                _loadData();
              } finally { if (mounted) setState(() => _processing = false); }
            },
            child: Text(loc.tr('common.save')),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    if (_processing) return;
    setState(() => _processing = true);
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(loc.tr('admin.title'), style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Stack(
            children: [
              IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: _openNotifications),
              if (_unreadCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: _refreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSettingsScreen())).then((_) => _loadUnreadCount())),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
          tabs: [
            _tabItem(Icons.people, loc.tr('admin.tab_users'), _allUsers.length, Colors.orange),
            _tabItem(Icons.add_circle, loc.tr('admin.tab_deposits'), _pendingDeposits.length, Colors.green),
            _tabItem(Icons.remove_circle, loc.tr('admin.tab_withdrawals'), _pendingWithdrawals.length, Colors.red),
            _tabItem(Icons.account_balance, loc.tr('admin.tab_loans'), _pendingLoans.length, Colors.purple),
            _tabItem(Icons.payment, loc.tr('admin.tab_methods'), _paymentMethods.length, Colors.teal),
            _tabItem(Icons.account_balance_wallet, loc.tr('admin.tab_w_methods'), _withdrawalPaymentMethods.length, Colors.brown),
            _tabItem(Icons.support_agent, loc.tr('admin.tab_support'), _openTickets.length, Colors.blue),
          ],
        ),
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUsersList(loc),
                    _buildPendingDeposits(loc),
                    _buildPendingWithdrawals(loc),
                    _buildPendingLoans(loc),
                    _buildPaymentMethods(loc),
                    _buildWithdrawalPaymentMethods(loc),
                    _buildSupportTickets(loc),
                  ],
                ),
          if (_processing)
            Container(
              color: Colors.black26,
              child: const Center(child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing...'),
                    ],
                  ),
                ),
              )),
            ),
        ],
      ),
    );
  }

  Tab _tabItem(IconData icon, String label, int count, Color color) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: color.withAlpha(80), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, AppLocalizations loc) {
    Color c;
    String label;
    switch (status) {
      case 'approved': c = Colors.green; label = loc.tr('status.approved'); break;
      case 'pending': c = Colors.orange; label = loc.tr('status.pending'); break;
      case 'banned': c = Colors.red; label = loc.tr('status.banned'); break;
      case 'rejected': c = Colors.grey; label = loc.tr('status.rejected'); break;
      default: c = Colors.grey; label = status; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withAlpha(20), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ── Users ──
  Widget _buildUsersList(AppLocalizations loc) {
    final q = _userSearch.toLowerCase();
    final queryFiltered = q.isEmpty
        ? _allUsers
        : _allUsers.where((u) {
            final nameMatch = u.name.toLowerCase().contains(q);
            final emailMatch = u.email.toLowerCase().contains(q);
            final phoneMatch = u.phone != null && u.phone!.toLowerCase().contains(q);
            return nameMatch || emailMatch || phoneMatch;
          }).toList();

    final pending = queryFiltered.where((u) => u.status == 'pending').toList();
    final approved = queryFiltered.where((u) => u.status == 'approved').toList();
    final banned = queryFiltered.where((u) => u.status == 'banned').toList();
    final rejected = queryFiltered.where((u) => u.status == 'rejected').toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: (v) => setState(() => _userSearch = v),
            decoration: InputDecoration(
              hintText: loc.tr('admin.search_users'),
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _userSearch.isNotEmpty
                  ? IconButton(
                      onPressed: () => setState(() => _userSearch = ''),
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        Expanded(
          child: (pending.isEmpty && approved.isEmpty && banned.isEmpty && rejected.isEmpty)
              ? Center(child: Text(queryFiltered.isEmpty && _userSearch.isNotEmpty ? loc.tr('admin.no_users_match') : loc.tr('admin.no_users')))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    if (pending.isNotEmpty) ...[
                      _sectionHeader('${loc.tr('status.pending').toUpperCase()} (${pending.length})', Colors.orange),
                      ...pending.map((u) => _buildUserCard(u, loc)),
                      const SizedBox(height: 16),
                    ],
                    if (approved.isNotEmpty) ...[
                      _sectionHeader('${loc.tr('status.approved').toUpperCase()} (${approved.length})', Colors.green),
                      ...approved.map((u) => _buildUserCard(u, loc)),
                      const SizedBox(height: 16),
                    ],
                    if (banned.isNotEmpty) ...[
                      _sectionHeader('${loc.tr('status.banned').toUpperCase()} (${banned.length})', Colors.red),
                      ...banned.map((u) => _buildUserCard(u, loc)),
                      const SizedBox(height: 16),
                    ],
                    if (rejected.isNotEmpty) ...[
                      _sectionHeader('${loc.tr('status.rejected').toUpperCase()} (${rejected.length})', Colors.grey),
                      ...rejected.map((u) => _buildUserCard(u, loc)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user, AppLocalizations loc) {
    Color statusColor;
    IconData statusIcon;
    switch (user.status) {
      case 'approved': statusColor = Colors.green; statusIcon = Icons.check_circle; break;
      case 'pending': statusColor = Colors.orange; statusIcon = Icons.hourglass_empty; break;
      case 'banned': statusColor = Colors.red; statusIcon = Icons.block; break;
      case 'rejected': statusColor = Colors.grey; statusIcon = Icons.cancel; break;
      default: statusColor = Colors.grey; statusIcon = Icons.help;
    }

    final profileUrl = (user.profileImage != null && user.profileImage!.isNotEmpty)
        ? (user.profileImage!.startsWith('http')
            ? user.profileImage!
            : '${ApiService.baseUrl}/${user.profileImage}')
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: profileUrl != null ? () => _showProfileImage(profileUrl, user.name) : null,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withAlpha(25),
                  backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
                  onBackgroundImageError: profileUrl != null ? (_, __) {} : null,
                  child: profileUrl == null
                      ? Icon(statusIcon, color: statusColor, size: 22)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis, maxLines: 1),
                        ),
                        const SizedBox(width: 6),
                        _statusBadge(user.status, loc),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(user.email, style: TextStyle(color: Colors.grey[500], fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: user.emailVerified == 1 ? Colors.green[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(user.emailVerified == 1 ? Icons.verified : Icons.unpublished, size: 13, color: user.emailVerified == 1 ? Colors.green : Colors.grey),
                        const SizedBox(width: 3),
                        Text(user.emailVerified == 1 ? loc.tr('status.verified') : loc.tr('status.unverified'), style: TextStyle(fontSize: 10, color: user.emailVerified == 1 ? Colors.green[700] : Colors.grey[600])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${ApiService.currencySymbolFor(user.currency)}${user.balance.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey[800], fontSize: 14)),
                ],
              ),
            ],
          ),
          if (user.status == 'rejected' && user.rejectionReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                child: Text('${loc.tr('common.reason')} ${user.rejectionReason}', style: TextStyle(color: Colors.red[700], fontSize: 12)),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              if (user.status == 'pending') ...[
                _actionChip(loc.tr('common.approve'), Colors.green, Icons.check, () => _handleUser(user.id, 'approve')),
                _actionChip(loc.tr('common.reject'), Colors.red, Icons.close, () => _handleUser(user.id, 'reject')),
              ],
              if (user.status == 'approved' || user.status == 'rejected') ...[
                _actionChip(loc.tr('admin.ban'), Colors.red, Icons.block, () => _handleUser(user.id, 'ban')),
                if (user.status == 'approved' && user.emailVerified == 0)
                  _actionChip(loc.tr('admin.verify_email'), Colors.blue, Icons.verified, () => _handleVerifyEmail(user.id)),
              ],
              if (user.status == 'banned')
                _actionChip(loc.tr('admin.unban'), Colors.green, Icons.check_circle, () => _handleUser(user.id, 'unban')),
              if (user.status != 'pending')
                _actionChip(loc.tr('admin.funds'), Colors.indigo, Icons.account_balance_wallet, () => _showFundsDialog(user)),
              if (user.status == 'approved')
                _actionChip(loc.tr('admin.reset_pin'), Colors.orange, Icons.pin, () => _handleResetPin(user.id)),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfileImage(String url, String name) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionChip(String label, Color color, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pending Deposits ──
  Widget _buildPendingDeposits(AppLocalizations loc) {
    if (_pendingDeposits.isEmpty) return _emptyState(loc.tr('admin.no_deposits'), Icons.add_circle);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingDeposits.length,
      itemBuilder: (ctx, i) => _buildDepositCard(_pendingDeposits[i], loc),
    );
  }

  Widget _buildDepositCard(Map<String, dynamic> d, AppLocalizations loc) {
    final amount = double.tryParse(d['amount']?.toString() ?? '0') ?? 0;
    final proofPath = d['proof_of_payment'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green.withAlpha(25),
                child: const Icon(Icons.add_circle, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(d['email'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Text('\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.green)),
            ],
          ),
          if (d['payment_method_name'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.payment, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text('Method: ${d['payment_method_name']}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
          if (d['description'] != null && (d['description'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(d['description'], style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ),
          if (proofPath != null && proofPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showProofImage(proofPath),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 6),
                    Text(loc.tr('admin.view_proof'), style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w500, fontSize: 13)),
                    const Spacer(),
                    Icon(Icons.open_in_new, size: 14, color: Colors.blue[400]),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _actionChip(loc.tr('common.approve'), Colors.green, Icons.check, () => _handleDeposit(d['id'], 'approve')),
              const SizedBox(width: 8),
              _actionChip(loc.tr('common.reject'), Colors.red, Icons.close, () => _handleDeposit(d['id'], 'reject')),
            ],
          ),
        ],
      ),
    );
  }

  void _showProofImage(String path) {
    final loc = AppLocalizations.of(context);
    final uri = '${ApiService.baseUrl}/$path';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(uri, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Center(child: Text(loc.tr('admin.image_error')))),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.tr('common.close'))),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pending Withdrawals ──
  Widget _buildPendingWithdrawals(AppLocalizations loc) {
    if (_pendingWithdrawals.isEmpty) return _emptyState(loc.tr('admin.no_withdrawals'), Icons.remove_circle);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingWithdrawals.length,
      itemBuilder: (ctx, i) => _buildWithdrawalCard(_pendingWithdrawals[i], loc),
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> w, AppLocalizations loc) {
    final amount = double.tryParse(w['amount']?.toString() ?? '0') ?? 0;
    final rawDetails = w['payment_details']?.toString() ?? '';
    String accountDetails = rawDetails;
    String maxitCode = '';
    if (rawDetails.contains('|maxit:')) {
      final parts = rawDetails.split('|maxit:');
      accountDetails = parts[0];
      maxitCode = parts[1];
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.red.withAlpha(25),
                child: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(w['email'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Text('-\$${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.red)),
            ],
          ),
          if (w['payment_method'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.payment, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${w['payment_method']}: $accountDetails',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (maxitCode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6D00).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF6D00).withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.vpn_key, size: 14, color: Color(0xFFFF6D00)),
                    const SizedBox(width: 6),
                    Text('Maxit Code: $maxitCode', style: const TextStyle(color: Color(0xFFE65100), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          if (w['description'] != null && (w['description'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(w['description'], style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ),
          if (w['withdrawal_pin'] != null && (w['withdrawal_pin'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pin, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 6),
                    Text('PIN: ${w['withdrawal_pin']}', style: TextStyle(color: Colors.orange[800], fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _actionChip(loc.tr('common.approve'), Colors.green, Icons.check, () => _handleWithdrawal(w['id'], 'approve')),
              const SizedBox(width: 8),
              _actionChip(loc.tr('common.reject'), Colors.red, Icons.close, () => _handleWithdrawal(w['id'], 'reject')),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pending Loans ──
  Widget _buildPendingLoans(AppLocalizations loc) {
    if (_pendingLoans.isEmpty) return _emptyState(loc.tr('admin.no_loans'), Icons.account_balance);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingLoans.length,
      itemBuilder: (ctx, i) => _buildLoanCard(_pendingLoans[i], loc),
    );
  }

  Widget _buildLoanCard(LoanModel loan, AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.purple.withAlpha(25),
                child: const Icon(Icons.account_balance, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loan.userName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(loan.userEmail ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Text('\$${loan.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.purple)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _infoChip(Icons.percent, '${loan.interest}%', Colors.purple),
              const SizedBox(width: 8),
              _infoChip(Icons.category_outlined, loan.loanType, Colors.indigo),
              const SizedBox(width: 8),
              _infoChip(Icons.calendar_today, '${loan.loanTerm}mo', Colors.teal),
            ],
          ),
          if (loan.reason != null && loan.reason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(loan.reason!, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _actionChip(loc.tr('common.approve'), Colors.green, Icons.check, () => _handleLoan(loan.id, 'approve')),
              const SizedBox(width: 8),
              _actionChip(loc.tr('common.reject'), Colors.red, Icons.close, () => _handleLoan(loan.id, 'reject')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ],
      ),
    );
  }

  // ── Support Tickets ──
  Widget _buildSupportTickets(AppLocalizations loc) {
    if (_openTickets.isEmpty) return _emptyState(loc.tr('admin.no_tickets'), Icons.support_agent);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _openTickets.length,
      itemBuilder: (ctx, i) => _buildTicketCard(_openTickets[i], loc),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, AppLocalizations loc) {
    final id = ticket['id'];
    final subject = ticket['subject'] ?? '';
    final lastMsg = ticket['last_message'] ?? '';
    final unread = int.tryParse(ticket['unread']?.toString() ?? '0') ?? 0;
    final userName = ticket['user_name'] ?? 'Unknown';
    final userEmail = ticket['user_email'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TicketDetailScreen(ticketId: id is int ? id : int.parse(id.toString()), isAdmin: true),
              ),
            );
            _loadData();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                              child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('$userName ($userEmail)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ),
                      if (lastMsg.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(lastMsg, style: TextStyle(color: Colors.grey[400], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Payment Methods ──
  Widget _buildPaymentMethods(AppLocalizations loc) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
                boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: FilledButton.icon(
                onPressed: _showAddPaymentMethodDialog,
                icon: const Icon(Icons.add),
                label: Text(loc.tr('admin.add_payment_method')),
                style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _paymentMethods.isEmpty
              ? _emptyState(loc.tr('admin.no_methods'), Icons.payment)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _paymentMethods.length,
                  itemBuilder: (ctx, i) {
                    final m = _paymentMethods[i];
                    final id = m['id'] is int ? m['id'] : int.parse(m['id'].toString());
                    final active = m['is_active'] == 1 || m['is_active'] == '1';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: active ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
                            child: Icon(active ? Icons.check_circle : Icons.cancel, color: active ? Colors.green : Colors.red, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                if (m['details'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      (m['details'] as String).replaceAll('\\n', '\n'),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 19),
                            color: Colors.indigo,
                            onPressed: () => _showEditPaymentMethodDialog(m),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 19),
                            color: Colors.red[400],
                            onPressed: _processing ? null : () async {
                              setState(() => _processing = true);
                              try {
                                await ApiService.managePaymentMethods(method: 'DELETE', id: id);
                                _loadData();
                              } finally { if (mounted) setState(() => _processing = false); }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Withdrawal Payment Methods ──
  Widget _buildWithdrawalPaymentMethods(AppLocalizations loc) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
                boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: FilledButton.icon(
                onPressed: _showAddWithdrawalMethodDialog,
                icon: const Icon(Icons.add),
                label: Text(loc.tr('admin.add_w_method')),
                style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFF6D00).withAlpha(80), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFFF6D00).withAlpha(20),
                      child: const Icon(Icons.phone_android, color: Color(0xFFFF6D00), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Orange Money', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFFFF6D00))),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Mobile money transfer',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Default', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 19),
                      color: Colors.indigo,
                      onPressed: () => _showEditWithdrawalMethodDialog({'id': 0, 'name': 'Orange Money', 'details': 'Mobile money transfer', 'is_active': 1}),
                    ),
                  ],
                ),
              ),
              ..._withdrawalPaymentMethods.map((m) {
                final id = m['id'] is int ? m['id'] : int.parse(m['id'].toString());
                final active = m['is_active'] == 1 || m['is_active'] == '1';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: active ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
                        child: Icon(active ? Icons.check_circle : Icons.cancel, color: active ? Colors.green : Colors.red, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            if (m['details'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  (m['details'] as String).replaceAll('\\n', '\n'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 19),
                        color: Colors.indigo,
                        onPressed: () => _showEditWithdrawalMethodDialog(m),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 19),
                        color: Colors.red[400],
                        onPressed: _processing ? null : () async {
                          setState(() => _processing = true);
                          try {
                            await ApiService.manageWithdrawalPaymentMethods(method: 'DELETE', id: id);
                            _loadData();
                          } finally { if (mounted) setState(() => _processing = false); }
                        },
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddWithdrawalMethodDialog() {
    final loc = AppLocalizations.of(context);
    final nameCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('admin.add_w_method')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: loc.tr('admin.name'), border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: detailsCtrl, decoration: InputDecoration(labelText: '${loc.tr('admin.details')} (${loc.tr('common.optional')})', border: const OutlineInputBorder()), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.tr('common.cancel'))),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() => _processing = true);
              try {
                final result = await ApiService.manageWithdrawalPaymentMethods(method: 'POST', name: nameCtrl.text.trim(), details: detailsCtrl.text.trim());
                if (!mounted) return;
                Navigator.pop(ctx);
                if (result['success'] == true) {
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? 'Failed'), backgroundColor: Colors.red.shade700));
                }
              } catch (_) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('common.connection_error')), backgroundColor: Colors.red.shade700));
                }
              } finally { if (mounted) setState(() => _processing = false); }
            },
            child: Text(loc.tr('admin.add')),
          ),
        ],
      ),
    );
  }

  void _showEditWithdrawalMethodDialog(Map<String, dynamic> method) {
    final loc = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: method['name'] ?? '');
    final detailsCtrl = TextEditingController(text: method['details'] ?? '');
    final isEdit = method['id'] != 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.tr('admin.edit_w_method')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: loc.tr('admin.name'), border: const OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: detailsCtrl, decoration: InputDecoration(labelText: '${loc.tr('admin.details')} (${loc.tr('common.optional')})', border: const OutlineInputBorder()), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.tr('common.cancel'))),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() => _processing = true);
              try {
                Map<String, dynamic> result;
                if (isEdit) {
                  result = await ApiService.manageWithdrawalPaymentMethods(
                    method: 'PUT',
                    id: method['id'] is int ? method['id'] : int.parse(method['id'].toString()),
                    name: nameCtrl.text.trim(),
                    details: detailsCtrl.text.trim(),
                    isActive: method['is_active'],
                  );
                } else {
                  result = await ApiService.manageWithdrawalPaymentMethods(
                    method: 'POST',
                    name: nameCtrl.text.trim(),
                    details: detailsCtrl.text.trim(),
                    isActive: 1,
                  );
                }
                if (!mounted) return;
                Navigator.pop(ctx);
                if (result['success'] == true) {
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? 'Failed'), backgroundColor: Colors.red.shade700));
                }
              } catch (_) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.tr('common.connection_error')), backgroundColor: Colors.red.shade700));
                }
              } finally { if (mounted) setState(() => _processing = false); }
            },
            child: Text(loc.tr('common.save')),
          ),
        ],
      ),
    );
  }
}
