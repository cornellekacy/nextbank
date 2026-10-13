import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'register_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _editing = false;
  bool _changingPassword = false;
  bool _processing = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _countryController = TextEditingController();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _countryController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await ApiService.getProfile();
      if (!mounted) return;
      if (result['success'] == true && result['user'] != null) {
        final user = result['user'];
        _nameController.text = user['name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _dobController.text = user['date_of_birth'] ?? '';
        _countryController.text = user['country'] ?? '';
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _processing = true);
    try {
      final result = await ApiService.uploadProfileImage(picked.path);
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() => _user!['profile_image'] = result['profile_image']);
        _showSuccess('Profile image updated');
      } else {
        _showError(result['error'] ?? 'Failed to upload image');
      }
    } catch (_) {
      _showError('Failed to upload image');
    } finally { if (mounted) setState(() => _processing = false); }
  }

  Future<void> _saveProfile() async {
    final loc = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty) {
      _showError(loc.tr('profile.name_required'));
      return;
    }

    setState(() => _processing = true);
    try {
      final result = await ApiService.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        country: _countryController.text.trim(),
      );
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() => _editing = false);
        _showSuccess(loc.tr('profile.updated'));
        _loadProfile();
      } else {
        _showError(result['error'] ?? loc.tr('common.failed'));
      }
    } catch (_) {
      _showError(loc.tr('common.connection_error'));
    } finally { if (mounted) setState(() => _processing = false); }
  }

  Future<void> _changePassword() async {
    final loc = AppLocalizations.of(context);
    if (_currentPassController.text.isEmpty || _newPassController.text.isEmpty) {
      _showError(loc.tr('profile.password_fill_all'));
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      _showError(loc.tr('profile.password_no_match'));
      return;
    }
    if (_newPassController.text.length < 6) {
      _showError(loc.tr('profile.password_min_length'));
      return;
    }

    setState(() => _processing = true);
    try {
      final result = await ApiService.changePassword(
        currentPassword: _currentPassController.text,
        newPassword: _newPassController.text,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() => _changingPassword = false);
        _currentPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
        _showSuccess(loc.tr('profile.password_changed'));
      } else {
        _showError(result['error'] ?? loc.tr('common.failed'));
      }
    } catch (_) {
      _showError(loc.tr('common.connection_error'));
    } finally { if (mounted) setState(() => _processing = false); }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _imageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${ApiService.baseUrl}/$path';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(loc.tr('profile.title')),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_editing && !_changingPassword)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _user == null
                  ? Center(child: Text(loc.tr('profile.load_error')))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildAvatarSection(loc),
                          const SizedBox(height: 24),
                          _buildSignUpDetails(loc),
                          const SizedBox(height: 20),
                          _buildLanguageSection(loc),
                          const SizedBox(height: 20),
                          _buildCurrencySection(loc),
                          const SizedBox(height: 20),
                          if (_editing) _buildEditForm(loc),
                          if (_changingPassword) _buildChangePasswordForm(loc),
                          if (!_editing && !_changingPassword) ...[
                            _buildActionButton(loc.tr('profile.edit_profile'), Icons.edit_outlined, () => setState(() => _editing = true)),
                            const SizedBox(height: 12),
                            _buildActionButton(loc.tr('profile.change_password'), Icons.lock_outline, () => setState(() => _changingPassword = true)),
                          ],
                        ],
                      ),
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

  Widget _buildAvatarSection(AppLocalizations loc) {
    final profileImage = _user?['profile_image'];
    return Container(
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
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white.withAlpha(30),
                  backgroundImage: profileImage != null && profileImage.toString().isNotEmpty
                      ? NetworkImage(_imageUrl(profileImage))
                      : null,
                  child: profileImage == null || profileImage.toString().isEmpty
                      ? Text(
                          (_user?['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 20, color: Color(0xFF1A237E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _user?['name'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _user?['email'] ?? '',
            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1A237E).withAlpha(180)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value.isNotEmpty ? value : '-', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpDetails(AppLocalizations loc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.tr('profile.signup_details'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
          const SizedBox(height: 6),
          Divider(color: Colors.grey[200]),
          _buildInfoRow(Icons.person_outline, loc.tr('profile.name'), _user?['name'] ?? ''),
          _buildInfoRow(Icons.email_outlined, loc.tr('profile.email'), _user?['email'] ?? ''),
          _buildInfoRow(Icons.phone_outlined, loc.tr('profile.phone'), _user?['phone'] ?? ''),
          _buildInfoRow(Icons.calendar_today_outlined, loc.tr('profile.dob'), _user?['date_of_birth'] ?? ''),
          _buildInfoRow(Icons.flag_outlined, loc.tr('profile.country'), _user?['country'] ?? ''),
          _buildInfoRow(Icons.verified_outlined, loc.tr('profile.status'), (_user?['status'] ?? '').toString().toUpperCase()),
          _buildInfoRow(Icons.calendar_month_outlined, loc.tr('profile.joined'), _formatDate(_user?['created_at'] ?? '')),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(AppLocalizations loc) {
    final currentLang = _user?['language'] ?? 'en';
    final languages = [
      {'code': 'en', 'name': 'English'},
      {'code': 'es', 'name': 'Español'},
      {'code': 'fr', 'name': 'Français'},
      {'code': 'ar', 'name': 'العربية'},
      {'code': 'pt', 'name': 'Português'},
      {'code': 'de', 'name': 'Deutsch'},
      {'code': 'it', 'name': 'Italiano'},
      {'code': 'ru', 'name': 'Русский'},
      {'code': 'zh', 'name': '中文'},
      {'code': 'ja', 'name': '日本語'},
      {'code': 'ko', 'name': '한국어'},
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: const Color(0xFF1A237E).withAlpha(180)),
              const SizedBox(width: 10),
              Text(loc.tr('profile.language'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
            ],
          ),
          const SizedBox(height: 6),
          Divider(color: Colors.grey[200]),
          ...languages.map((l) {
            final selected = currentLang == l['code'];
            return RadioListTile<String>(
              title: Text(l['name']!, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
              value: l['code']!,
              groupValue: currentLang,
              activeColor: const Color(0xFF1A237E),
              onChanged: (val) async {
                if (val == null || _processing) return;
                setState(() => _processing = true);
                try {
                  final result = await ApiService.saveLanguage(val);
                  if (!mounted) return;
                  if (result['success'] == true) {
                    setState(() => _user!['language'] = val);
                    NextBankApp.of(context)?.setLocale(val);
                    _showSuccess(loc.tr('profile.language_saved'));
                  } else {
                    _showError(result['error'] ?? loc.tr('common.failed'));
                  }
                } finally { if (mounted) setState(() => _processing = false); }
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEditForm(AppLocalizations loc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.tr('profile.edit_profile'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
          const SizedBox(height: 16),
          _buildTextField(_nameController, loc.tr('profile.name'), Icons.person_outline),
          const SizedBox(height: 12),
          _buildTextField(_phoneController, loc.tr('profile.phone'), Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildTextField(_dobController, loc.tr('profile.dob'), Icons.calendar_today_outlined),
          const SizedBox(height: 12),
          _buildTextField(_countryController, loc.tr('profile.country'), Icons.flag_outlined),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _editing = false),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(loc.tr('common.cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _processing ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _processing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(loc.tr('common.save')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordForm(AppLocalizations loc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.tr('profile.change_password'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
          const SizedBox(height: 16),
          _buildPasswordField(_currentPassController, loc.tr('profile.current_password'), _obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
          const SizedBox(height: 12),
          _buildPasswordField(_newPassController, loc.tr('profile.new_password'), _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
          const SizedBox(height: 12),
          _buildPasswordField(_confirmPassController, loc.tr('profile.confirm_password'), _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _changingPassword = false),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(loc.tr('common.cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _processing ? null : _changePassword,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _processing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(loc.tr('common.save')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E).withAlpha(180)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1A237E)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade500),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1A237E)),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  String _currencyDisplayName(String code) {
    for (final c in _currencies) {
      if (c['code'] == code) return '$code - ${c['name']}';
    }
    return code;
  }

  static const List<Map<String, String>> _currencies = [
    {'code': 'AED', 'name': 'UAE Dirham'}, {'code': 'AFN', 'name': 'Afghan Afghani'},
    {'code': 'ALL', 'name': 'Albanian Lek'}, {'code': 'AMD', 'name': 'Armenian Dram'},
    {'code': 'ANG', 'name': 'Netherlands Antillean Guilder'}, {'code': 'AOA', 'name': 'Angolan Kwanza'},
    {'code': 'ARS', 'name': 'Argentine Peso'}, {'code': 'AUD', 'name': 'Australian Dollar'},
    {'code': 'AWG', 'name': 'Aruban Florin'}, {'code': 'AZN', 'name': 'Azerbaijani Manat'},
    {'code': 'BAM', 'name': 'Bosnia-Herzegovina Convertible Mark'}, {'code': 'BBD', 'name': 'Barbadian Dollar'},
    {'code': 'BDT', 'name': 'Bangladeshi Taka'}, {'code': 'BGN', 'name': 'Bulgarian Lev'},
    {'code': 'BHD', 'name': 'Bahraini Dinar'}, {'code': 'BIF', 'name': 'Burundian Franc'},
    {'code': 'BMD', 'name': 'Bermudan Dollar'}, {'code': 'BND', 'name': 'Brunei Dollar'},
    {'code': 'BOB', 'name': 'Bolivian Boliviano'}, {'code': 'BRL', 'name': 'Brazilian Real'},
    {'code': 'BSD', 'name': 'Bahamian Dollar'}, {'code': 'BTN', 'name': 'Bhutanese Ngultrum'},
    {'code': 'BWP', 'name': 'Botswanan Pula'}, {'code': 'BYN', 'name': 'Belarusian Ruble'},
    {'code': 'BZD', 'name': 'Belize Dollar'}, {'code': 'CAD', 'name': 'Canadian Dollar'},
    {'code': 'CDF', 'name': 'Congolese Franc'}, {'code': 'CHF', 'name': 'Swiss Franc'},
    {'code': 'CLP', 'name': 'Chilean Peso'}, {'code': 'CNY', 'name': 'Chinese Yuan'},
    {'code': 'COP', 'name': 'Colombian Peso'}, {'code': 'CRC', 'name': 'Costa Rican Colon'},
    {'code': 'CUP', 'name': 'Cuban Peso'}, {'code': 'CVE', 'name': 'Cape Verdean Escudo'},
    {'code': 'CZK', 'name': 'Czech Koruna'}, {'code': 'DJF', 'name': 'Djiboutian Franc'},
    {'code': 'DKK', 'name': 'Danish Krone'}, {'code': 'DOP', 'name': 'Dominican Peso'},
    {'code': 'DZD', 'name': 'Algerian Dinar'}, {'code': 'EGP', 'name': 'Egyptian Pound'},
    {'code': 'ERN', 'name': 'Eritrean Nakfa'}, {'code': 'ETB', 'name': 'Ethiopian Birr'},
    {'code': 'EUR', 'name': 'Euro'}, {'code': 'FJD', 'name': 'Fijian Dollar'},
    {'code': 'FKP', 'name': 'Falkland Islands Pound'}, {'code': 'GBP', 'name': 'British Pound Sterling'},
    {'code': 'GEL', 'name': 'Georgian Lari'}, {'code': 'GHS', 'name': 'Ghanaian Cedi'},
    {'code': 'GIP', 'name': 'Gibraltar Pound'}, {'code': 'GMD', 'name': 'Gambian Dalasi'},
    {'code': 'GNF', 'name': 'Guinean Franc'}, {'code': 'GTQ', 'name': 'Guatemalan Quetzal'},
    {'code': 'GYD', 'name': 'Guyanaese Dollar'}, {'code': 'HKD', 'name': 'Hong Kong Dollar'},
    {'code': 'HNL', 'name': 'Honduran Lempira'}, {'code': 'HRK', 'name': 'Croatian Kuna'},
    {'code': 'HTG', 'name': 'Haitian Gourde'}, {'code': 'HUF', 'name': 'Hungarian Forint'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah'}, {'code': 'ILS', 'name': 'Israeli New Sheqel'},
    {'code': 'INR', 'name': 'Indian Rupee'}, {'code': 'IQD', 'name': 'Iraqi Dinar'},
    {'code': 'IRR', 'name': 'Iranian Rial'}, {'code': 'ISK', 'name': 'Icelandic Krona'},
    {'code': 'JMD', 'name': 'Jamaican Dollar'}, {'code': 'JOD', 'name': 'Jordanian Dinar'},
    {'code': 'JPY', 'name': 'Japanese Yen'}, {'code': 'KES', 'name': 'Kenyan Shilling'},
    {'code': 'KGS', 'name': 'Kyrgystani Som'}, {'code': 'KHR', 'name': 'Cambodian Riel'},
    {'code': 'KMF', 'name': 'Comorian Franc'}, {'code': 'KPW', 'name': 'North Korean Won'},
    {'code': 'KRW', 'name': 'South Korean Won'}, {'code': 'KWD', 'name': 'Kuwaiti Dinar'},
    {'code': 'KYD', 'name': 'Cayman Islands Dollar'}, {'code': 'KZT', 'name': 'Kazakhstani Tenge'},
    {'code': 'LAK', 'name': 'Laotian Kip'}, {'code': 'LBP', 'name': 'Lebanese Pound'},
    {'code': 'LKR', 'name': 'Sri Lankan Rupee'}, {'code': 'LRD', 'name': 'Liberian Dollar'},
    {'code': 'LSL', 'name': 'Lesotho Loti'}, {'code': 'LYD', 'name': 'Libyan Dinar'},
    {'code': 'MAD', 'name': 'Moroccan Dirham'}, {'code': 'MDL', 'name': 'Moldovan Leu'},
    {'code': 'MGA', 'name': 'Malagasy Ariary'}, {'code': 'MKD', 'name': 'Denar'},
    {'code': 'MMK', 'name': 'Myanma Kyat'}, {'code': 'MNT', 'name': 'Mongolian Tugrik'},
    {'code': 'MOP', 'name': 'Macanese Pataca'}, {'code': 'MRU', 'name': 'Mauritanian Ouguiya'},
    {'code': 'MUR', 'name': 'Mauritian Rupee'}, {'code': 'MVR', 'name': 'Maldivian Rufiyaa'},
    {'code': 'MWK', 'name': 'Malawian Kwacha'}, {'code': 'MXN', 'name': 'Mexican Peso'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit'}, {'code': 'MZN', 'name': 'Mozambican Metical'},
    {'code': 'NAD', 'name': 'Namibian Dollar'}, {'code': 'NGN', 'name': 'Nigerian Naira'},
    {'code': 'NIO', 'name': 'Nicaraguan Cordoba'}, {'code': 'NOK', 'name': 'Norwegian Krone'},
    {'code': 'NPR', 'name': 'Nepalese Rupee'}, {'code': 'NZD', 'name': 'New Zealand Dollar'},
    {'code': 'OMR', 'name': 'Omani Rial'}, {'code': 'PAB', 'name': 'Panamanian Balboa'},
    {'code': 'PEN', 'name': 'Peruvian Sol'}, {'code': 'PGK', 'name': 'Papua New Guinean Kina'},
    {'code': 'PHP', 'name': 'Philippine Peso'}, {'code': 'PKR', 'name': 'Pakistani Rupee'},
    {'code': 'PLN', 'name': 'Polish Zloty'}, {'code': 'PYG', 'name': 'Paraguayan Guarani'},
    {'code': 'QAR', 'name': 'Qatari Rial'}, {'code': 'RON', 'name': 'Romanian Leu'},
    {'code': 'RSD', 'name': 'Serbian Dinar'}, {'code': 'RUB', 'name': 'Russian Ruble'},
    {'code': 'RWF', 'name': 'Rwandan Franc'}, {'code': 'SAR', 'name': 'Saudi Riyal'},
    {'code': 'SBD', 'name': 'Solomon Islands Dollar'}, {'code': 'SCR', 'name': 'Seychellois Rupee'},
    {'code': 'SDG', 'name': 'Sudanese Pound'}, {'code': 'SEK', 'name': 'Swedish Krona'},
    {'code': 'SGD', 'name': 'Singapore Dollar'}, {'code': 'SHP', 'name': 'Saint Helena Pound'},
    {'code': 'SLL', 'name': 'Sierra Leonean Leone'}, {'code': 'SOS', 'name': 'Somali Shilling'},
    {'code': 'SRD', 'name': 'Surinamese Dollar'}, {'code': 'SSP', 'name': 'South Sudanese Pound'},
    {'code': 'STN', 'name': 'Sao Tome and Principe Dobra'}, {'code': 'SVC', 'name': 'Salvadoran Colon'},
    {'code': 'SYP', 'name': 'Syrian Pound'}, {'code': 'SZL', 'name': 'Swazi Lilangeni'},
    {'code': 'THB', 'name': 'Thai Baht'}, {'code': 'TJS', 'name': 'Tajikistani Somoni'},
    {'code': 'TMT', 'name': 'Turkmenistani Manat'}, {'code': 'TND', 'name': 'Tunisian Dinar'},
    {'code': 'TOP', 'name': 'Tongan Pa\'anga'}, {'code': 'TRY', 'name': 'Turkish Lira'},
    {'code': 'TTD', 'name': 'Trinidad and Tobago Dollar'}, {'code': 'TWD', 'name': 'New Taiwan Dollar'},
    {'code': 'TZS', 'name': 'Tanzanian Shilling'}, {'code': 'UAH', 'name': 'Ukrainian Hryvnia'},
    {'code': 'UGX', 'name': 'Ugandan Shilling'}, {'code': 'USD', 'name': 'US Dollar'},
    {'code': 'UYU', 'name': 'Uruguayan Peso'}, {'code': 'UZS', 'name': 'Uzbekistan Som'},
    {'code': 'VES', 'name': 'Venezuelan Bolivar'}, {'code': 'VND', 'name': 'Vietnamese Dong'},
    {'code': 'VUV', 'name': 'Vanuatu Vatu'}, {'code': 'WST', 'name': 'Samoan Tala'},
    {'code': 'XAF', 'name': 'CFA Franc BEAC'}, {'code': 'XCD', 'name': 'East Caribbean Dollar'},
    {'code': 'XOF', 'name': 'CFA Franc BCEAO'}, {'code': 'XPF', 'name': 'CFP Franc'},
    {'code': 'YER', 'name': 'Yemeni Rial'}, {'code': 'ZAR', 'name': 'South African Rand'},
    {'code': 'ZMW', 'name': 'Zambian Kwacha'}, {'code': 'ZWL', 'name': 'Zimbabwean Dollar'},
  ];

  Widget _buildCurrencySection(AppLocalizations loc) {
    final currentCurrency = _user?['currency'] ?? 'USD';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on_outlined, color: const Color(0xFF1A237E).withAlpha(180)),
              const SizedBox(width: 10),
              Text(loc.tr('register.currency_hint'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[800])),
            ],
          ),
          const SizedBox(height: 6),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openCurrencyPicker(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on_outlined, size: 20, color: Color(0xFF1A237E)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_currencyDisplayName(currentCurrency), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                  Icon(Icons.edit_outlined, size: 18, color: Colors.grey[500]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCurrencyPicker() {
    final loc = AppLocalizations.of(context);
    final currentCurrency = _user?['currency'] ?? 'USD';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ProfileCurrencyPickerSheet(
        currencies: _currencies,
        selectedCode: currentCurrency,
        onSelect: (code) async {
          Navigator.of(ctx).pop();
          if (_processing) return;
          setState(() => _processing = true);
          try {
            final result = await ApiService.saveCurrency(code);
            if (!mounted) return;
            if (result['success'] == true) {
              ApiService.updateCachedCurrency(code);
              setState(() => _user!['currency'] = code);
              _showSuccess(loc.tr('profile.currency_saved'));
            } else {
              _showError(result['error'] ?? loc.tr('common.failed'));
            }
          } finally { if (mounted) setState(() => _processing = false); }
        },
      ),
    );
  }
}

class _ProfileCurrencyPickerSheet extends StatefulWidget {
  final List<Map<String, String>> currencies;
  final String selectedCode;
  final ValueChanged<String> onSelect;

  const _ProfileCurrencyPickerSheet({
    required this.currencies,
    required this.selectedCode,
    required this.onSelect,
  });

  @override
  State<_ProfileCurrencyPickerSheet> createState() => _ProfileCurrencyPickerSheetState();
}

class _ProfileCurrencyPickerSheetState extends State<_ProfileCurrencyPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.currencies.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c['code']!.toLowerCase().contains(q) || c['name']!.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Select Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by code or name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () { _searchController.clear(); setState(() => _query = ''); },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No currency found', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final c = filtered[i];
                      final isSelected = c['code'] == widget.selectedCode;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: Theme.of(context).colorScheme.primary.withAlpha(20),
                        leading: Text(
                          c['code']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade800,
                          ),
                        ),
                        title: Text(c['name']!, style: const TextStyle(fontSize: 14)),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20)
                            : null,
                        onTap: () => widget.onSelect(c['code']!),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}