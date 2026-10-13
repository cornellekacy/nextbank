import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _country = '';
  String _currency = 'USD';
  DateTime? _dateOfBirth;
  File? _profileImage;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola', 'Antigua and Barbuda', 'Argentina', 'Armenia', 'Australia', 'Austria', 'Azerbaijan',
    'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados', 'Belarus', 'Belgium', 'Belize', 'Benin', 'Bhutan', 'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei', 'Bulgaria', 'Burkina Faso', 'Burundi',
    'Cabo Verde', 'Cambodia', 'Cameroon', 'Canada', 'Central African Republic', 'Chad', 'Chile', 'China', 'Colombia', 'Comoros', 'Congo', 'Costa Rica', 'Croatia', 'Cuba', 'Cyprus', 'Czech Republic',
    'Denmark', 'Democratic Republic of the Congo', 'Djibouti', 'Dominica', 'Dominican Republic',
    'Ecuador', 'Egypt', 'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Estonia', 'Eswatini', 'Ethiopia',
    'Fiji', 'Finland', 'France',
    'Gabon', 'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece', 'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana',
    'Haiti', 'Honduras', 'Hungary',
    'Iceland', 'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel', 'Italy',
    'Jamaica', 'Japan', 'Jordan',
    'Kazakhstan', 'Kenya', 'Kiribati', 'Kosovo', 'Kuwait', 'Kyrgyzstan',
    'Laos', 'Latvia', 'Lebanon', 'Lesotho', 'Liberia', 'Libya', 'Liechtenstein', 'Lithuania', 'Luxembourg',
    'Madagascar', 'Malawi', 'Malaysia', 'Maldives', 'Mali', 'Malta', 'Marshall Islands', 'Mauritania', 'Mauritius', 'Mexico', 'Micronesia', 'Moldova', 'Monaco', 'Mongolia', 'Montenegro', 'Morocco', 'Mozambique', 'Myanmar',
    'Namibia', 'Nauru', 'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'North Korea', 'North Macedonia', 'Norway',
    'Oman',
    'Pakistan', 'Palau', 'Palestine', 'Panama', 'Papua New Guinea', 'Paraguay', 'Peru', 'Philippines', 'Poland', 'Portugal',
    'Qatar',
    'Romania', 'Russia', 'Rwanda',
    'Saint Kitts and Nevis', 'Saint Lucia', 'Saint Vincent and the Grenadines', 'Samoa', 'San Marino', 'Sao Tome and Principe', 'Saudi Arabia', 'Senegal', 'Serbia', 'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia', 'Solomon Islands', 'Somalia', 'South Africa', 'South Korea', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland', 'Syria',
    'Taiwan', 'Tajikistan', 'Tanzania', 'Thailand', 'Timor-Leste', 'Togo', 'Tonga', 'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Turkmenistan', 'Tuvalu',
    'Uganda', 'Ukraine', 'United Arab Emirates', 'United Kingdom', 'United States', 'Uruguay', 'Uzbekistan',
    'Vanuatu', 'Vatican City', 'Venezuela', 'Vietnam',
    'Yemen',
    'Zambia', 'Zimbabwe',
  ];

  static const List<Map<String, String>> _currencies = [
    {'code': 'AED', 'name': 'UAE Dirham'},
    {'code': 'AFN', 'name': 'Afghan Afghani'},
    {'code': 'ALL', 'name': 'Albanian Lek'},
    {'code': 'AMD', 'name': 'Armenian Dram'},
    {'code': 'ANG', 'name': 'Netherlands Antillean Guilder'},
    {'code': 'AOA', 'name': 'Angolan Kwanza'},
    {'code': 'ARS', 'name': 'Argentine Peso'},
    {'code': 'AUD', 'name': 'Australian Dollar'},
    {'code': 'AWG', 'name': 'Aruban Florin'},
    {'code': 'AZN', 'name': 'Azerbaijani Manat'},
    {'code': 'BAM', 'name': 'Bosnia-Herzegovina Convertible Mark'},
    {'code': 'BBD', 'name': 'Barbadian Dollar'},
    {'code': 'BDT', 'name': 'Bangladeshi Taka'},
    {'code': 'BGN', 'name': 'Bulgarian Lev'},
    {'code': 'BHD', 'name': 'Bahraini Dinar'},
    {'code': 'BIF', 'name': 'Burundian Franc'},
    {'code': 'BMD', 'name': 'Bermudan Dollar'},
    {'code': 'BND', 'name': 'Brunei Dollar'},
    {'code': 'BOB', 'name': 'Bolivian Boliviano'},
    {'code': 'BRL', 'name': 'Brazilian Real'},
    {'code': 'BSD', 'name': 'Bahamian Dollar'},
    {'code': 'BTN', 'name': 'Bhutanese Ngultrum'},
    {'code': 'BWP', 'name': 'Botswanan Pula'},
    {'code': 'BYN', 'name': 'Belarusian Ruble'},
    {'code': 'BZD', 'name': 'Belize Dollar'},
    {'code': 'CAD', 'name': 'Canadian Dollar'},
    {'code': 'CDF', 'name': 'Congolese Franc'},
    {'code': 'CHF', 'name': 'Swiss Franc'},
    {'code': 'CLP', 'name': 'Chilean Peso'},
    {'code': 'CNY', 'name': 'Chinese Yuan'},
    {'code': 'COP', 'name': 'Colombian Peso'},
    {'code': 'CRC', 'name': 'Costa Rican Colon'},
    {'code': 'CUP', 'name': 'Cuban Peso'},
    {'code': 'CVE', 'name': 'Cape Verdean Escudo'},
    {'code': 'CZK', 'name': 'Czech Koruna'},
    {'code': 'DJF', 'name': 'Djiboutian Franc'},
    {'code': 'DKK', 'name': 'Danish Krone'},
    {'code': 'DOP', 'name': 'Dominican Peso'},
    {'code': 'DZD', 'name': 'Algerian Dinar'},
    {'code': 'EGP', 'name': 'Egyptian Pound'},
    {'code': 'ERN', 'name': 'Eritrean Nakfa'},
    {'code': 'ETB', 'name': 'Ethiopian Birr'},
    {'code': 'EUR', 'name': 'Euro'},
    {'code': 'FJD', 'name': 'Fijian Dollar'},
    {'code': 'FKP', 'name': 'Falkland Islands Pound'},
    {'code': 'GBP', 'name': 'British Pound Sterling'},
    {'code': 'GEL', 'name': 'Georgian Lari'},
    {'code': 'GHS', 'name': 'Ghanaian Cedi'},
    {'code': 'GIP', 'name': 'Gibraltar Pound'},
    {'code': 'GMD', 'name': 'Gambian Dalasi'},
    {'code': 'GNF', 'name': 'Guinean Franc'},
    {'code': 'GTQ', 'name': 'Guatemalan Quetzal'},
    {'code': 'GYD', 'name': 'Guyanaese Dollar'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar'},
    {'code': 'HNL', 'name': 'Honduran Lempira'},
    {'code': 'HRK', 'name': 'Croatian Kuna'},
    {'code': 'HTG', 'name': 'Haitian Gourde'},
    {'code': 'HUF', 'name': 'Hungarian Forint'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah'},
    {'code': 'ILS', 'name': 'Israeli New Sheqel'},
    {'code': 'INR', 'name': 'Indian Rupee'},
    {'code': 'IQD', 'name': 'Iraqi Dinar'},
    {'code': 'IRR', 'name': 'Iranian Rial'},
    {'code': 'ISK', 'name': 'Icelandic Krona'},
    {'code': 'JMD', 'name': 'Jamaican Dollar'},
    {'code': 'JOD', 'name': 'Jordanian Dinar'},
    {'code': 'JPY', 'name': 'Japanese Yen'},
    {'code': 'KES', 'name': 'Kenyan Shilling'},
    {'code': 'KGS', 'name': 'Kyrgystani Som'},
    {'code': 'KHR', 'name': 'Cambodian Riel'},
    {'code': 'KMF', 'name': 'Comorian Franc'},
    {'code': 'KPW', 'name': 'North Korean Won'},
    {'code': 'KRW', 'name': 'South Korean Won'},
    {'code': 'KWD', 'name': 'Kuwaiti Dinar'},
    {'code': 'KYD', 'name': 'Cayman Islands Dollar'},
    {'code': 'KZT', 'name': 'Kazakhstani Tenge'},
    {'code': 'LAK', 'name': 'Laotian Kip'},
    {'code': 'LBP', 'name': 'Lebanese Pound'},
    {'code': 'LKR', 'name': 'Sri Lankan Rupee'},
    {'code': 'LRD', 'name': 'Liberian Dollar'},
    {'code': 'LSL', 'name': 'Lesotho Loti'},
    {'code': 'LYD', 'name': 'Libyan Dinar'},
    {'code': 'MAD', 'name': 'Moroccan Dirham'},
    {'code': 'MDL', 'name': 'Moldovan Leu'},
    {'code': 'MGA', 'name': 'Malagasy Ariary'},
    {'code': 'MKD', 'name': 'Denar'},
    {'code': 'MMK', 'name': 'Myanma Kyat'},
    {'code': 'MNT', 'name': 'Mongolian Tugrik'},
    {'code': 'MOP', 'name': 'Macanese Pataca'},
    {'code': 'MRU', 'name': 'Mauritanian Ouguiya'},
    {'code': 'MUR', 'name': 'Mauritian Rupee'},
    {'code': 'MVR', 'name': 'Maldivian Rufiyaa'},
    {'code': 'MWK', 'name': 'Malawian Kwacha'},
    {'code': 'MXN', 'name': 'Mexican Peso'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit'},
    {'code': 'MZN', 'name': 'Mozambican Metical'},
    {'code': 'NAD', 'name': 'Namibian Dollar'},
    {'code': 'NGN', 'name': 'Nigerian Naira'},
    {'code': 'NIO', 'name': 'Nicaraguan Cordoba'},
    {'code': 'NOK', 'name': 'Norwegian Krone'},
    {'code': 'NPR', 'name': 'Nepalese Rupee'},
    {'code': 'NZD', 'name': 'New Zealand Dollar'},
    {'code': 'OMR', 'name': 'Omani Rial'},
    {'code': 'PAB', 'name': 'Panamanian Balboa'},
    {'code': 'PEN', 'name': 'Peruvian Sol'},
    {'code': 'PGK', 'name': 'Papua New Guinean Kina'},
    {'code': 'PHP', 'name': 'Philippine Peso'},
    {'code': 'PKR', 'name': 'Pakistani Rupee'},
    {'code': 'PLN', 'name': 'Polish Zloty'},
    {'code': 'PYG', 'name': 'Paraguayan Guarani'},
    {'code': 'QAR', 'name': 'Qatari Rial'},
    {'code': 'RON', 'name': 'Romanian Leu'},
    {'code': 'RSD', 'name': 'Serbian Dinar'},
    {'code': 'RUB', 'name': 'Russian Ruble'},
    {'code': 'RWF', 'name': 'Rwandan Franc'},
    {'code': 'SAR', 'name': 'Saudi Riyal'},
    {'code': 'SBD', 'name': 'Solomon Islands Dollar'},
    {'code': 'SCR', 'name': 'Seychellois Rupee'},
    {'code': 'SDG', 'name': 'Sudanese Pound'},
    {'code': 'SEK', 'name': 'Swedish Krona'},
    {'code': 'SGD', 'name': 'Singapore Dollar'},
    {'code': 'SHP', 'name': 'Saint Helena Pound'},
    {'code': 'SLL', 'name': 'Sierra Leonean Leone'},
    {'code': 'SOS', 'name': 'Somali Shilling'},
    {'code': 'SRD', 'name': 'Surinamese Dollar'},
    {'code': 'SSP', 'name': 'South Sudanese Pound'},
    {'code': 'STN', 'name': 'Sao Tome and Principe Dobra'},
    {'code': 'SVC', 'name': 'Salvadoran Colon'},
    {'code': 'SYP', 'name': 'Syrian Pound'},
    {'code': 'SZL', 'name': 'Swazi Lilangeni'},
    {'code': 'THB', 'name': 'Thai Baht'},
    {'code': 'TJS', 'name': 'Tajikistani Somoni'},
    {'code': 'TMT', 'name': 'Turkmenistani Manat'},
    {'code': 'TND', 'name': 'Tunisian Dinar'},
    {'code': 'TOP', 'name': 'Tongan Pa\'anga'},
    {'code': 'TRY', 'name': 'Turkish Lira'},
    {'code': 'TTD', 'name': 'Trinidad and Tobago Dollar'},
    {'code': 'TWD', 'name': 'New Taiwan Dollar'},
    {'code': 'TZS', 'name': 'Tanzanian Shilling'},
    {'code': 'UAH', 'name': 'Ukrainian Hryvnia'},
    {'code': 'UGX', 'name': 'Ugandan Shilling'},
    {'code': 'USD', 'name': 'US Dollar'},
    {'code': 'UYU', 'name': 'Uruguayan Peso'},
    {'code': 'UZS', 'name': 'Uzbekistan Som'},
    {'code': 'VES', 'name': 'Venezuelan Bolivar'},
    {'code': 'VND', 'name': 'Vietnamese Dong'},
    {'code': 'VUV', 'name': 'Vanuatu Vatu'},
    {'code': 'WST', 'name': 'Samoan Tala'},
    {'code': 'XAF', 'name': 'CFA Franc BEAC'},
    {'code': 'XCD', 'name': 'East Caribbean Dollar'},
    {'code': 'XOF', 'name': 'CFA Franc BCEAO'},
    {'code': 'XPF', 'name': 'CFP Franc'},
    {'code': 'YER', 'name': 'Yemeni Rial'},
    {'code': 'ZAR', 'name': 'South African Rand'},
    {'code': 'ZMW', 'name': 'Zambian Kwacha'},
    {'code': 'ZWL', 'name': 'Zimbabwean Dollar'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _currencyDisplayName(String code) {
    final match = _currencies.where((c) => c['code'] == code);
    if (match.isNotEmpty) return '${match.first['code']} - ${match.first['name']}';
    return code;
  }

  void _openCurrencyPicker() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CurrencyPickerSheet(
        currencies: _currencies,
        selectedCode: _currency,
        searchHint: loc.tr('register.currency_hint'),
        onSelect: (code) {
          setState(() => _currency = code);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dateController.text = '${picked.month}/${picked.day}/${picked.year}';
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final loc = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final result = await ApiService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        phone: _phoneController.text.trim(),
        country: _country,
        dateOfBirth: '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
        currency: _currency,
        profileImage: _profileImage,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(loc.tr('register.success_title')),
            content: Text(loc.tr('register.success_msg')),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(loc.tr('register.ok')),
              ),
            ],
          ),
        );
      } else {
        _showError(result['error'] ?? loc.tr('register.failed'));
      }
    } catch (e) {
      _showError(loc.tr('common.connection_error'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF01579B)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset('assets/logo.png', height: 60, fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 4),
                          Text(loc.tr('register.title'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(loc.tr('register.subtitle'),
                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                                  child: _profileImage == null
                                      ? Icon(Icons.person, size: 44, color: Colors.grey.shade400)
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('register.name_required') : null,
                            decoration: InputDecoration(
                              hintText: loc.tr('register.name_hint'),
                              prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('register.email_required') : null,
                            decoration: InputDecoration(
                              hintText: loc.tr('register.email_hint'),
                              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().isEmpty) ? loc.tr('register.phone_required') : null,
                            decoration: InputDecoration(
                              hintText: loc.tr('register.phone_hint'),
                              prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _country.isEmpty ? null : _country,
                            validator: (v) => (v == null || v.isEmpty) ? loc.tr('register.country_required') : null,
                            decoration: InputDecoration(
                              hintText: loc.tr('register.country_hint'),
                              prefixIcon: Icon(Icons.public, color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (v) => setState(() => _country = v ?? ''),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _openCurrencyPicker,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                hintText: loc.tr('register.currency_hint'),
                                prefixIcon: Icon(Icons.monetization_on_outlined, color: Colors.grey.shade500),
                                suffixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              child: Text(_currencyDisplayName(_currency), style: const TextStyle(fontSize: 14)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            readOnly: true,
                            onTap: _pickDate,
                            controller: _dateController,
                            validator: (_) => _dateOfBirth == null ? loc.tr('register.dob_required') : null,
                            decoration: InputDecoration(
                              hintText: loc.tr('register.dob_hint'),
                              prefixIcon: Icon(Icons.calendar_today, color: Colors.grey.shade500),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (v) {
                              if (v == null || v.isEmpty) return loc.tr('register.password_empty');
                              if (v.length < 6) return loc.tr('register.password_too_short');
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: loc.tr('register.password_hint'),
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade500),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            validator: (v) {
                              if (v == null || v.isEmpty) return loc.tr('register.confirm_empty');
                              if (v != _passwordController.text) return loc.tr('register.confirm_mismatch');
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: loc.tr('register.confirm_hint'),
                              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade500),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0D47A1)]),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: FilledButton(
                                onPressed: _loading ? null : _register,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _loading
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : Text(loc.tr('register.submit'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          TextSpan(text: loc.tr('login.no_account'), style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                          TextSpan(text: loc.tr('login.register_link'), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, decoration: TextDecoration.underline)),
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
}

class _CurrencyPickerSheet extends StatefulWidget {
  final List<Map<String, String>> currencies;
  final String selectedCode;
  final String searchHint;
  final ValueChanged<String> onSelect;

  const _CurrencyPickerSheet({
    required this.currencies,
    required this.selectedCode,
    required this.searchHint,
    required this.onSelect,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
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
