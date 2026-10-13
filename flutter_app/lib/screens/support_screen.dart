import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import 'ticket_detail_screen.dart';
import 'new_ticket_screen.dart';

class SupportScreen extends StatefulWidget {
  final bool isAdmin;
  const SupportScreen({super.key, this.isAdmin = false});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _openTickets = [];
  List<Map<String, dynamic>> _closedTickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() => _loading = true);
    try {
      final open = await ApiService.getTickets('open');
      final closed = await ApiService.getTickets('closed');
      if (!mounted) return;
      setState(() {
        _openTickets = (open['tickets'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        _closedTickets = (closed['tickets'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(loc.tr('support.title')),
        backgroundColor: widget.isAdmin ? const Color(0xFF1A237E) : const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTickets),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: '${loc.tr('support.open')} (${_openTickets.length})'),
            Tab(text: '${loc.tr('support.closed')} (${_closedTickets.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTicketList(_openTickets, loc, false),
                _buildTicketList(_closedTickets, loc, true),
              ],
            ),
      floatingActionButton: !widget.isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const NewTicketScreen()),
                );
                if (created == true) _loadTickets();
              },
              backgroundColor: const Color(0xFF1565C0),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildTicketList(List<Map<String, dynamic>> tickets, AppLocalizations loc, bool isClosed) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(isClosed ? loc.tr('support.no_closed') : loc.tr('support.no_open'), style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (ctx, i) => _buildTicketCard(tickets[i], loc),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, AppLocalizations loc) {
    final id = ticket['id'];
    final subject = ticket['subject'] ?? '';
    final lastMsg = ticket['last_message'] ?? '';
    final unread = int.tryParse(ticket['unread']?.toString() ?? '0') ?? 0;
    final updated = ticket['updated_at'] ?? '';
    final userName = ticket['user_name'] as String?;

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
                builder: (_) => TicketDetailScreen(ticketId: id, isAdmin: widget.isAdmin),
              ),
            );
            _loadTickets();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1565C0), size: 22),
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
                      if (widget.isAdmin && userName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(userName, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ),
                      if (lastMsg.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(lastMsg, style: TextStyle(color: Colors.grey[400], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_formatDate(updated), style: TextStyle(color: Colors.grey[300], fontSize: 11)),
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

  String _formatDate(String date) {
    try {
      return DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}
