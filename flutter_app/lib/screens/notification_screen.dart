import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;
  bool _processing = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _load();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await ApiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = (result['notifications'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        _unreadCount = result['unread_count'] ?? 0;
        _loading = false;
      });
      _animController.forward(from: 0);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(dynamic id) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      await ApiService.markNotificationRead(id);
      _load();
    } finally { if (mounted) setState(() => _processing = false); }
  }

  Future<void> _markAllRead() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      await ApiService.markNotificationRead('all');
      _load();
    } finally { if (mounted) setState(() => _processing = false); }
  }

  IconData _iconForType(String type) {
    if (type.contains('approved') || type.contains('approve')) return Icons.check_circle_rounded;
    if (type.contains('rejected') || type.contains('reject')) return Icons.cancel_rounded;
    if (type.contains('pending')) return Icons.schedule_rounded;
    if (type.contains('account')) return Icons.person_rounded;
    if (type.contains('loan')) return Icons.account_balance_rounded;
    if (type.contains('withdrawal')) return Icons.money_off_rounded;
    if (type.contains('deposit')) return Icons.add_circle_rounded;
    if (type.contains('transfer')) return Icons.swap_horiz_rounded;
    if (type.contains('support') || type.contains('ticket')) return Icons.support_agent_rounded;
    return Icons.notifications_rounded;
  }

  Map<String, dynamic> _styleForType(String type) {
    if (type.contains('approved') || type.contains('approve')) {
      return {'color': const Color(0xFF2E7D32), 'bg': const Color(0xFFE8F5E9), 'gradient': const [Color(0xFF43A047), Color(0xFF2E7D32)]};
    }
    if (type.contains('rejected') || type.contains('reject')) {
      return {'color': const Color(0xFFC62828), 'bg': const Color(0xFFFFEBEE), 'gradient': const [Color(0xFFE53935), Color(0xFFC62828)]};
    }
    if (type.contains('pending')) {
      return {'color': const Color(0xFFEF6C00), 'bg': const Color(0xFFFFF3E0), 'gradient': const [Color(0xFFFF9800), Color(0xFFEF6C00)]};
    }
    if (type.contains('loan')) {
      return {'color': const Color(0xFF6A1B9A), 'bg': const Color(0xFFF3E5F5), 'gradient': const [Color(0xFF8E24AA), Color(0xFF6A1B9A)]};
    }
    if (type.contains('deposit')) {
      return {'color': const Color(0xFF1565C0), 'bg': const Color(0xFFE3F2FD), 'gradient': const [Color(0xFF1E88E5), Color(0xFF1565C0)]};
    }
    if (type.contains('transfer')) {
      return {'color': const Color(0xFF00838F), 'bg': const Color(0xFFE0F7FA), 'gradient': const [Color(0xFF00ACC1), Color(0xFF00838F)]};
    }
    if (type.contains('support') || type.contains('ticket')) {
      return {'color': const Color(0xFF4527A0), 'bg': const Color(0xFFEDE7F6), 'gradient': const [Color(0xFF5E35B1), Color(0xFF4527A0)]};
    }
    return {'color': const Color(0xFF1565C0), 'bg': const Color(0xFFE3F2FD), 'gradient': const [Color(0xFF1E88E5), Color(0xFF1565C0)]};
  }

  String _groupTitle(DateTime date, AppLocalizations loc) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return loc.tr('notif.today');
    if (d == yesterday) return loc.tr('notif.yesterday');
    if (now.difference(date).inDays < 7) return loc.tr('notif.this_week');
    return loc.tr('notif.earlier');
  }

  Map<String, List<Map<String, dynamic>>> _groupNotifications(AppLocalizations loc) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final n in _notifications) {
      final date = DateTime.tryParse(n['created_at'] ?? '') ?? DateTime.now();
      final key = _groupTitle(date, loc);
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
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
        title: Row(
          children: [
            Text(loc.tr('notif.title'), style: const TextStyle(fontWeight: FontWeight.w700)),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                child: Text('$_unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            _processing
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)),
                  )
                : IconButton(
                    onPressed: _markAllRead,
                    tooltip: loc.tr('notif.mark_all_read'),
                    icon: const Icon(Icons.done_all_rounded, color: Colors.white70, size: 22),
                  ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : _notifications.isEmpty
              ? _buildEmptyState(loc)
              : RefreshIndicator(
                  color: const Color(0xFF1A237E),
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      if (_unreadCount > 0) _buildSummaryBanner(loc),
                      ..._groupNotifications(loc).entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGroupHeader(entry.key, entry.value.length),
                            const SizedBox(height: 8),
                            ...entry.value.asMap().entries.map((ne) {
                              final idx = ne.key;
                              final n = ne.value;
                              return AnimatedBuilder(
                                animation: _animController,
                                builder: (ctx, child) {
                                  final delay = (idx * 0.05).clamp(0.0, 0.5);
                                  final anim = CurvedAnimation(
                                    parent: _animController,
                                    curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
                                  );
                                  return FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildNotificationCard(n, loc),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
    );
  }

  String _unreadText(AppLocalizations loc) {
    if (loc.locale.languageCode == 'en') {
      return '$_unreadCount unread notification${_unreadCount == 1 ? '' : 's'}';
    }
    return loc.tr('notif.unread_count', {'count': '$_unreadCount', 's': _unreadCount == 1 ? '' : 's'});
  }

  Widget _buildSummaryBanner(AppLocalizations loc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withAlpha(60), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.mark_email_unread_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_unreadText(loc), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(loc.tr('notif.tap_to_read'), style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: const Color(0xFF1A237E).withAlpha(15), borderRadius: BorderRadius.circular(8)),
            child: Text('$count', style: const TextStyle(color: Color(0xFF1A237E), fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n, AppLocalizations loc) {
    final isRead = n['is_read'] == 1 || n['is_read'] == '1';
    final type = (n['type'] ?? '').toString();
    final date = n['created_at'] ?? '';
    final style = _styleForType(type);

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(date);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final timeStr = DateFormat('HH:mm').format(parsedDate);

    return Dismissible(
      key: Key(n['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.green[300]!, Colors.green[600]!]),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 26),
      ),
      onDismissed: (_) => _markRead(n['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isRead ? Colors.black.withAlpha(4) : (style['color'] as Color).withAlpha(18),
              blurRadius: isRead ? 8 : 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _markRead(n['id']),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: style['gradient'] as List<Color>,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: style['bg'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _iconForType(type),
                              color: style['color'] as Color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n['title'] ?? '',
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                          fontSize: 14.5,
                                          color: const Color(0xFF1A237E).withAlpha(isRead ? 120 : 220),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(left: 6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: style['gradient'] as List<Color>),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  n['message'] ?? '',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[400]),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeStr,
                                      style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (style['color'] as Color).withAlpha(15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        type.replaceAll('_', ' ').toUpperCase(),
                                        style: TextStyle(color: style['color'] as Color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (!isRead)
                                      GestureDetector(
                                        onTap: () => _markRead(n['id']),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1A237E).withAlpha(12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(loc.tr('notif.read'), style: const TextStyle(color: Color(0xFF1A237E), fontSize: 11, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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

  Widget _buildEmptyState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 64, color: const Color(0xFF1A237E).withAlpha(60)),
          ),
          const SizedBox(height: 20),
          Text(
            loc.tr('notif.empty'),
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            loc.tr('notif.all_caught_up'),
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
