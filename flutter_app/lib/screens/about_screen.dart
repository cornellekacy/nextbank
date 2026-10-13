import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(loc.tr('about.title')),
        backgroundColor: const Color(0xFF1A237E),
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
                  colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.tr('about.welcome'),
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Transform.translate(
                offset: const Offset(0, -16),
                child: Column(
                  children: [
                    _buildCard(_introSection(loc)),
                    const SizedBox(height: 16),
                    _buildCard(_missionSection(loc)),
                    const SizedBox(height: 16),
                    _buildCard(_visionSection(loc)),
                    const SizedBox(height: 16),
                    _buildCard(_offerSection(loc)),
                    const SizedBox(height: 16),
                    _buildCard(_securitySection(loc)),
                    const SizedBox(height: 16),
                    _buildCard(_customerSection(loc)),
                    const SizedBox(height: 16),
                    _buildCard(_innovationSection(loc)),
                    const SizedBox(height: 16),
                    _buildCard(_whyChooseSection(loc)),
                    const SizedBox(height: 16),
                    _buildCard(_valuesSection(loc)),
                    const SizedBox(height: 16),
                    _buildCard(_lookingAheadSection(loc)),
                    const SizedBox(height: 16),
                    _buildCard(_joinSection(loc)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A237E),
        ),
      ),
    );
  }

  Widget _bodyText(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey[700]),
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF1A237E)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  List<Widget> _introSection(AppLocalizations loc) {
    return [
      _bodyText(loc.tr('about.intro_1')),
      const SizedBox(height: 12),
      _bodyText(loc.tr('about.intro_2')),
    ];
  }

  List<Widget> _missionSection(AppLocalizations loc) {
    return [
      _sectionTitle(loc.tr('about.mission_title')),
      _bodyText(loc.tr('about.mission_1')),
      const SizedBox(height: 12),
      _bodyText(loc.tr('about.mission_2')),
    ];
  }

  List<Widget> _visionSection(AppLocalizations loc) {
    return [
      _sectionTitle(loc.tr('about.vision_title')),
      _bodyText(loc.tr('about.vision_1')),
    ];
  }

  List<Widget> _offerSection(AppLocalizations loc) {
    return [
      _sectionTitle(loc.tr('about.offer_title')),
      _bodyText(loc.tr('about.offer_intro')),
      const SizedBox(height: 10),
      _bulletItem(loc.tr('about.offer_1')),
      _bulletItem(loc.tr('about.offer_2')),
      _bulletItem(loc.tr('about.offer_3')),
      _bulletItem(loc.tr('about.offer_4')),
      _bulletItem(loc.tr('about.offer_5')),
      _bulletItem(loc.tr('about.offer_6')),
      _bulletItem(loc.tr('about.offer_7')),
      _bulletItem(loc.tr('about.offer_8')),
      _bulletItem(loc.tr('about.offer_9')),
      _bulletItem(loc.tr('about.offer_10')),
      _bulletItem(loc.tr('about.offer_11')),
      _bulletItem(loc.tr('about.offer_12')),
      _bulletItem(loc.tr('about.offer_13')),
      const SizedBox(height: 12),
      _bodyText(loc.tr('about.offer_outro')),
    ];
  }

  List<Widget> _securitySection(AppLocalizations loc) {
    return [
      _sectionTitle(loc.tr('about.security_title')),
      _bodyText(loc.tr('about.security_1')),
      const SizedBox(height: 12),
      _bodyText(loc.tr('about.security_2')),
    ];
  }

  List<Widget> _customerSection(AppLocalizations loc) {
    return [
      _sectionTitle(loc.tr('about.customer_title')),
      _bodyText(loc.tr('about.customer_1')),
      const SizedBox(height: 12),
      _bodyText(loc.tr('about.customer_2')),
    ];
  }

  List<Widget> _innovationSection(AppLocalizations loc) {
    return [
      _sectionTitle(loc.tr('about.innovation_title')),
      _bodyText(loc.tr('about.innovation_1')),
      const SizedBox(height: 12),
      _bodyText(loc.tr('about.innovation_2')),
    ];
  }

  List<Widget> _whyChooseSection(AppLocalizations loc) {
    return [
      _sectionTitle(loc.tr('about.why_title')),
      _bodyText(loc.tr('about.why_intro')),
      const SizedBox(height: 10),
      _bulletItem(loc.tr('about.why_1')),
      _bulletItem(loc.tr('about.why_2')),
      _bulletItem(loc.tr('about.why_3')),
      _bulletItem(loc.tr('about.why_4')),
      _bulletItem(loc.tr('about.why_5')),
      _bulletItem(loc.tr('about.why_6')),
      _bulletItem(loc.tr('about.why_7')),
      _bulletItem(loc.tr('about.why_8')),
      _bulletItem(loc.tr('about.why_9')),
      _bulletItem(loc.tr('about.why_10')),
    ];
  }

  List<Widget> _valuesSection(AppLocalizations loc) {
    return [
      _sectionTitle(loc.tr('about.values_title')),
      _valueItem(loc.tr('about.value_trust_title'), loc.tr('about.value_trust_desc')),
      _valueItem(loc.tr('about.value_security_title'), loc.tr('about.value_security_desc')),
      _valueItem(loc.tr('about.value_innovation_title'), loc.tr('about.value_innovation_desc')),
      _valueItem(loc.tr('about.value_integrity_title'), loc.tr('about.value_integrity_desc')),
      _valueItem(loc.tr('about.value_excellence_title'), loc.tr('about.value_excellence_desc')),
      _valueItem(loc.tr('about.value_accessibility_title'), loc.tr('about.value_accessibility_desc')),
    ];
  }

  Widget _valueItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, size: 18, color: Color(0xFF1A237E)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A237E))),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(desc, style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  List<Widget> _lookingAheadSection(AppLocalizations loc) {
    return [
      _sectionTitle(loc.tr('about.lookahead_title')),
      _bodyText(loc.tr('about.lookahead_1')),
      const SizedBox(height: 12),
      _bodyText(loc.tr('about.lookahead_2')),
    ];
  }

  List<Widget> _joinSection(AppLocalizations loc) {
    return [
      _sectionTitle(loc.tr('about.join_title')),
      _bodyText(loc.tr('about.join_1')),
      const SizedBox(height: 12),
      _bodyText(loc.tr('about.join_2')),
    ];
  }
}
