import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://androidback.xyz/nextbank/backend';

  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': _token!,
  };

  static const Map<String, String> _currencySymbols = {
    'USD': '\$', 'EUR': '€', 'GBP': '£', 'NGN': '₦', 'KES': 'KSh',
    'ZAR': 'R', 'GHS': 'GH₵', 'INR': '₹', 'CAD': 'CA\$', 'AUD': 'A\$',
    'JPY': '¥', 'CNY': '¥', 'BRL': 'R\$', 'MXN': 'MX\$', 'CHF': 'CHF',
    'SEK': 'kr', 'NOK': 'kr', 'DKK': 'kr', 'SGD': 'S\$', 'HKD': 'HK\$',
    'KRW': '₩', 'AED': 'د.إ', 'SAR': '﷼', 'EGP': 'E£', 'TZS': 'TSh',
    'UGX': 'USh', 'ETB': 'Br', 'PKR': 'Rs', 'BDT': '৳', 'PHP': '₱',
    'IDR': 'Rp', 'MYR': 'RM', 'THB': '฿', 'VND': '₫', 'RUB': '₽',
    'TRY': '₺', 'PLN': 'zł', 'CZK': 'Kč', 'ILS': '₪', 'QAR': 'QR',
    'COP': 'COL\$', 'ARS': 'AR\$', 'CLP': 'CL\$', 'PEN': 'S/.',
    'MAD': 'MAD', 'DZD': 'DA', 'TND': 'DT', 'CDF': 'FC',
    'XAF': 'FCFA', 'XOF': 'CFA', 'GMD': 'D', 'MZN': 'MT',
    'RWF': 'FRw', 'BIF': 'FBu', 'MWK': 'MK', 'ZMW': 'ZK',
    'AOA': 'Kz', 'MGA': 'Ar', 'SCR': '₨', 'MUR': '₨',
    'NPR': '₨', 'LKR': 'Rs', 'MMK': 'K', 'KHR': '៛',
    'LAK': '₭', 'MNT': '₮', 'KZT': '₸', 'UZS': 'so\'m',
    'AFN': '؋', 'IQD': 'ع.د', 'JOD': 'JD', 'KWD': 'KD',
    'BHD': 'BD', 'OMR': '﷼', 'YER': '﷼', 'SYP': '£',
    'LBP': 'L£', 'IRR': '﷼', 'BOB': 'Bs',
    'VES': 'Bs.S', 'GYD': 'G\$', 'TTD': 'TT\$', 'JMD': 'J\$',
    'BBD': 'Bds\$', 'HTG': 'G', 'DOP': 'RD\$', 'CUP': '₱',
    'NIO': 'C\$', 'HNL': 'L', 'GTQ': 'Q', 'BZD': 'BZ\$',
    'FJD': 'FJ\$', 'TOP': 'T\$', 'WST': 'WS\$', 'PGK': 'K',
    'SBD': 'SI\$', 'VUV': 'VT', 'BTN': 'Nu.',
    'ISK': 'kr', 'HUF': 'Ft', 'RON': 'lei', 'BGN': 'лв',
    'RSD': 'din.', 'MKD': 'ден', 'ALL': 'L', 'BAM': 'KM',
    'MDL': 'lei', 'GEL': '₾', 'AMD': '֏', 'AZN': 'ман',
    'KGS': 'сом', 'TJS': 'ЅМ', 'TMT': 'T', 'XPF': '₣',
  };

  static String get userCurrency => _currentUser?['currency']?.toString() ?? 'USD';

  static String get currencySymbol => _currencySymbols[userCurrency] ?? userCurrency;

  static String currencySymbolFor(String code) => _currencySymbols[code] ?? code;

  static void updateCachedCurrency(String currency) {
    if (_currentUser != null) {
      _currentUser!['currency'] = currency;
      _saveSession();
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, {String phone = '', String country = '', String dateOfBirth = '', String currency = 'USD', File? profileImage}) async {
    if (profileImage != null) {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/register.php'));
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['phone'] = phone;
      request.fields['country'] = country;
      request.fields['date_of_birth'] = dateOfBirth;
      request.fields['currency'] = currency;
      request.files.add(await http.MultipartFile.fromPath('profile_image', profileImage.path));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      return jsonDecode(response.body);
    }
    final response = await http.post(
      Uri.parse('$baseUrl/register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password, 'phone': phone, 'country': country, 'date_of_birth': dateOfBirth, 'currency': currency}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true && data['user'] != null) {
      _token = base64Encode(utf8.encode(data['user']['id'].toString()));
      _currentUser = Map<String, dynamic>.from(data['user']);
      await _saveSession();
    }
    return data;
  }

  static Future<Map<String, dynamic>?> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('auth_token');
    final savedUser = prefs.getString('user_data');
    if (savedToken != null && savedUser != null) {
      _token = savedToken;
      _currentUser = Map<String, dynamic>.from(jsonDecode(savedUser));
      return _currentUser;
    }
    return null;
  }

  static Future<void> _saveSession() async {
    if (_token == null || _currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('user_data', jsonEncode(_currentUser));
  }

  static Future<void> clearSession() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_dashboard.php'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPaymentMethods() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_payment_methods.php'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> managePaymentMethods({
    String? method,
    int? id,
    String? name,
    String? details,
    int? isActive,
  }) async {
    late http.Response response;
    final uri = Uri.parse('$baseUrl/manage_payment_methods.php${id != null && method == 'DELETE' ? '?id=$id' : ''}');

    if (method == 'GET') {
      response = await http.get(uri, headers: _headers);
    } else if (method == 'POST') {
      response = await http.post(uri, headers: _headers, body: jsonEncode({'name': name, 'details': details, 'is_active': isActive}));
    } else if (method == 'PUT') {
      response = await http.put(uri, headers: _headers, body: jsonEncode({'id': id, 'name': name, 'details': details, 'is_active': isActive}));
    } else {
      response = await http.delete(uri, headers: _headers);
    }
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deposit(double amount, String description, {int? paymentMethodId, File? proofFile}) async {
    if (proofFile != null || paymentMethodId != null) {
      final uri = Uri.parse('$baseUrl/deposit.php');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = _token ?? '';
      request.fields['amount'] = amount.toString();
      request.fields['description'] = description;
      if (paymentMethodId != null) request.fields['payment_method_id'] = paymentMethodId.toString();
      if (proofFile != null) {
        request.files.add(await http.MultipartFile.fromPath('proof', proofFile.path));
      }
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      return jsonDecode(resp.body);
    } else {
      final response = await http.post(
        Uri.parse('$baseUrl/deposit.php'),
        headers: _headers,
        body: jsonEncode({'amount': amount, 'description': description}),
      );
      return jsonDecode(response.body);
    }
  }

  static Future<Map<String, dynamic>> getAdminDeposits(String status) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin_deposits.php?status=$status'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> approveDeposit(int txId, String action, {String reason = ''}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin_deposits.php'),
      headers: _headers,
      body: jsonEncode({'transaction_id': txId, 'action': action, 'rejection_reason': reason}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getUsers(String status) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_users.php?status=$status'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_users.php?status=all'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyEmail(int userId, bool verified) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify_email.php'),
      headers: _headers,
      body: jsonEncode({'user_id': userId, 'verified': verified}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> approveUser(int userId, String action, {String reason = ''}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/approve_user.php'),
      headers: _headers,
      body: jsonEncode({'user_id': userId, 'action': action, 'rejection_reason': reason}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> withdraw(double amount, String description, {String pin = '', String paymentMethod = '', String paymentDetails = ''}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/withdraw.php'),
      headers: _headers,
      body: jsonEncode({'amount': amount, 'description': description, 'pin': pin, 'payment_method': paymentMethod, 'payment_details': paymentDetails}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> setWithdrawalPin(String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/set_withdrawal_pin.php'),
      headers: _headers,
      body: jsonEncode({'pin': pin}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> adminResetPin(int userId, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin_reset_pin.php'),
      headers: _headers,
      body: jsonEncode({'user_id': userId, 'pin': pin}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> transfer(double amount, String recipient, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transfer.php'),
      headers: _headers,
      body: jsonEncode({'amount': amount, 'recipient': recipient, 'description': description}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getTransactions({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_transactions.php?page=$page'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> applyLoan(double amount, {int loanTerm = 1, String loanType = 'Personal', String reason = ''}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/apply_loan.php'),
      headers: _headers,
      body: jsonEncode({'amount': amount, 'loan_term': loanTerm, 'loan_type': loanType, 'reason': reason}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getLoans() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_loans.php'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAdminLoans(String status) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin_loans.php?status=$status'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> approveLoan(int loanId, String action, {String reason = ''}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin_loans.php'),
      headers: _headers,
      body: jsonEncode({'loan_id': loanId, 'action': action, 'rejection_reason': reason}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_notifications.php'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> markNotificationRead(dynamic notificationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mark_notification_read.php'),
      headers: _headers,
      body: jsonEncode({'notification_id': notificationId}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getAdminWithdrawals(String status) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin_withdrawals.php?status=$status'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> approveWithdrawal(int txId, String action, {String reason = ''}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin_withdrawals.php'),
      headers: _headers,
      body: jsonEncode({'transaction_id': txId, 'action': action, 'rejection_reason': reason}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> adminAddFunds(int userId, double amount, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin_funds.php'),
      headers: _headers,
      body: jsonEncode({'user_id': userId, 'amount': amount, 'type': 'add', 'description': description}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> adminDeductFunds(int userId, double amount, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin_funds.php'),
      headers: _headers,
      body: jsonEncode({'user_id': userId, 'amount': amount, 'type': 'deduct', 'description': description}),
    );
    return jsonDecode(response.body);
  }

  static Future<void> saveDeviceToken(String deviceToken) async {
    await http.post(
      Uri.parse('$baseUrl/save_device_token.php'),
      headers: _headers,
      body: jsonEncode({'device_token': deviceToken}),
    );
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final response = await http.get(Uri.parse('$baseUrl/admin_settings.php'), headers: _headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> saveSettings(Map<String, String> settings) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin_settings.php'),
      headers: _headers,
      body: jsonEncode({'settings': settings}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> testSmtp(Map<String, dynamic> smtpData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin_test_smtp.php'),
      headers: _headers,
      body: jsonEncode(smtpData),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot_password.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> resetPassword(String email, String code, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset_password.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createTicket(String subject, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create_ticket.php'),
      headers: _headers,
      body: jsonEncode({'subject': subject, 'message': message}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getTickets(String status) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_tickets.php?status=$status'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getTicketMessages(int ticketId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_ticket_messages.php?ticket_id=$ticketId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> sendMessage(int ticketId, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send_message.php'),
      headers: _headers,
      body: jsonEncode({'ticket_id': ticketId, 'message': message}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> closeTicket(int ticketId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/close_ticket.php'),
      headers: _headers,
      body: jsonEncode({'ticket_id': ticketId}),
    );
    return jsonDecode(response.body);
  }

  static Future<void> logout() async {
    await clearSession();
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile.php'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateProfile({required String name, String phone = '', String dateOfBirth = '', String country = ''}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profile.php'),
      headers: _headers,
      body: jsonEncode({'action': 'update_profile', 'name': name, 'phone': phone, 'date_of_birth': dateOfBirth, 'country': country}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> changePassword({required String currentPassword, required String newPassword}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profile.php'),
      headers: _headers,
      body: jsonEncode({'action': 'change_password', 'current_password': currentPassword, 'new_password': newPassword}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> uploadProfileImage(String filePath) async {
    final uri = Uri.parse('$baseUrl/profile.php');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = _token ?? '';
    request.fields['action'] = 'upload_image';
    request.files.add(await http.MultipartFile.fromPath('profile_image', filePath));
    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    final result = jsonDecode(resp.body);
    if (result['success'] == true && result['profile_image'] != null) {
      if (_currentUser != null) {
        _currentUser!['profile_image'] = result['profile_image'];
        _saveSession();
      }
    }
    return result;
  }

  static Future<Map<String, dynamic>> saveLanguage(String language) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profile.php'),
      headers: _headers,
      body: jsonEncode({'action': 'save_language', 'language': language}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> saveCurrency(String currency) async {
    final response = await http.post(
      Uri.parse('$baseUrl/profile.php'),
      headers: _headers,
      body: jsonEncode({'action': 'save_currency', 'currency': currency}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getWithdrawalPaymentMethods() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_withdrawal_methods.php'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> manageWithdrawalPaymentMethods({
    String? method,
    int? id,
    String? name,
    String? details,
    int? isActive,
  }) async {
    late http.Response response;
    final uri = Uri.parse('$baseUrl/manage_withdrawal_methods.php${id != null && method == 'DELETE' ? '?id=$id' : ''}');

    if (method == 'GET') {
      response = await http.get(uri, headers: _headers);
    } else if (method == 'POST') {
      response = await http.post(uri, headers: _headers, body: jsonEncode({'name': name, 'details': details, 'is_active': isActive}));
    } else if (method == 'PUT') {
      response = await http.put(uri, headers: _headers, body: jsonEncode({'id': id, 'name': name, 'details': details, 'is_active': isActive}));
    } else {
      response = await http.delete(uri, headers: _headers);
    }
    return jsonDecode(response.body);
  }
}
