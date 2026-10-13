import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;
  final bool isAdmin;
  const TicketDetailScreen({super.key, required this.ticketId, this.isAdmin = false});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _ticket;
  bool _loading = true;
  bool _sending = false;
  bool _closing = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final result = await ApiService.getTicketMessages(widget.ticketId);
      if (!mounted) return;
      final msgs = (result['messages'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      final scrollPrev = _messages.length;
      setState(() {
        _ticket = result['ticket'] as Map<String, dynamic>?;
        _messages = msgs;
        _loading = false;
      });
      if (scrollPrev > 0 && msgs.length > scrollPrev) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _sendMessage() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    _messageController.clear();
    try {
      await ApiService.sendMessage(widget.ticketId, msg);
      await _loadMessages();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isClosed = _ticket?['status'] == 'closed';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_ticket?['subject'] ?? loc.tr('support.ticket_detail')),
        backgroundColor: widget.isAdmin ? const Color(0xFF1A237E) : const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isClosed)
            TextButton(
              onPressed: _closing ? null : () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(loc.tr('support.close_ticket')),
                    content: Text(loc.tr('support.close_confirm')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.tr('common.cancel'))),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.tr('common.confirm'))),
                    ],
                  ),
                );
                if (ok == true) {
                  setState(() => _closing = true);
                  try {
                    await ApiService.closeTicket(widget.ticketId);
                    _loadMessages();
                  } finally { if (mounted) setState(() => _closing = false); }
                }
              },
              child: _closing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                  : Text(loc.tr('support.close_ticket'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (widget.isAdmin && _ticket != null)
                  _buildUserInfoCard(),
                if (isClosed)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    color: Colors.orange[50],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 6),
                        Text(loc.tr('support.ticket_closed'), style: TextStyle(color: Colors.orange[700], fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(child: Text(loc.tr('support.no_messages'), style: TextStyle(color: Colors.grey[500])))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i], loc),
                        ),
                ),
                if (!isClosed)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -2))],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: loc.tr('support.message_hint'),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                filled: true,
                                fillColor: const Color(0xFFF5F7FA),
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: const Color(0xFF1565C0),
                            child: IconButton(
                              icon: _sending
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send, color: Colors.white, size: 20),
                              onPressed: _sending ? null : _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildUserInfoCard() {
    final name = _ticket!['user_name'] ?? '';
    final email = _ticket!['user_email'] ?? '';
    final phone = _ticket!['user_phone'] ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF1A237E).withAlpha(10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF1A237E),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                if (phone.isNotEmpty)
                  Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, AppLocalizations loc) {
    final isAdmin = msg['sender_role'] == 'admin';
    final message = msg['message'] ?? '';
    const adminColor = Color(0xFF1A237E);
    const userColor = Color(0xFF1565C0);

    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAdmin ? Colors.white : const Color(0xFF1565C0).withAlpha(30),
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: isAdmin ? const Radius.circular(4) : const Radius.circular(18),
            bottomRight: isAdmin ? const Radius.circular(18) : const Radius.circular(4),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAdmin ? (msg['sender_name'] ?? 'Admin') : 'You',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isAdmin ? adminColor : userColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(
              _formatDate(msg['created_at'] ?? ''),
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('MMM dd, HH:mm').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }
}
