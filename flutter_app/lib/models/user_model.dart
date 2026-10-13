class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final double balance;
  final String? cardNumber;
  final String? cardExpiry;
  final String? cardCvv;
  final String status;
  final int emailVerified;
  final String? profileImage;
  final String? phone;
  final String currency;

  final String? rejectionReason;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.balance,
    this.cardNumber,
    this.cardExpiry,
    this.cardCvv,
    required this.status,
    this.emailVerified = 0,
    this.profileImage,
    this.phone,
    this.currency = 'USD',
    this.rejectionReason,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0,
      cardNumber: json['card_number'],
      cardExpiry: json['card_expiry'],
      cardCvv: json['card_cvv'],
      status: json['status'] ?? 'pending',
      emailVerified: int.tryParse(json['email_verified']?.toString() ?? '0') ?? 0,
      profileImage: json['profile_image']?.toString(),
      phone: json['phone']?.toString(),
      currency: json['currency']?.toString() ?? 'USD',
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }
}

class TransactionModel {
  final int id;
  final String type;
  final double amount;
  final String? recipientAccount;
  final String? recipientName;
  final String? description;
  final String status;
  final DateTime createdAt;
  final String? rejectionReason;
  final String? paymentMethod;
  final String? paymentDetails;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    this.recipientAccount,
    this.recipientName,
    this.description,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.paymentMethod,
    this.paymentDetails,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      type: json['type'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      recipientAccount: json['recipient_account'],
      recipientName: json['recipient_name']?.toString(),
      description: json['description'],
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      rejectionReason: json['rejection_reason']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      paymentDetails: json['payment_details']?.toString(),
    );
  }
}

class LoanModel {
  final int id;
  final double amount;
  final double interest;
  final int loanTerm;
  final String loanType;
  final String? reason;
  final String status;
  final DateTime createdAt;
  final String? userName;
  final String? userEmail;
  final String? rejectionReason;
  final double totalRepayment;

  LoanModel({
    required this.id,
    required this.amount,
    required this.interest,
    this.loanTerm = 1,
    this.loanType = 'Personal',
    this.reason,
    required this.status,
    required this.createdAt,
    this.userName,
    this.userEmail,
    this.rejectionReason,
    double? totalRepayment,
  }) : totalRepayment = totalRepayment ?? (amount + (amount * (interest / 100)));

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    final amount = double.tryParse(json['amount']?.toString() ?? '0') ?? 0;
    final interest = double.tryParse(json['interest']?.toString() ?? '4') ?? 4;
    return LoanModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      amount: amount,
      interest: interest,
      loanTerm: int.tryParse(json['loan_term']?.toString() ?? '1') ?? 1,
      loanType: json['loan_type'] ?? 'Personal',
      reason: json['reason']?.toString(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      userName: json['name'],
      userEmail: json['email'],
      rejectionReason: json['rejection_reason']?.toString(),
      totalRepayment: amount + (amount * (interest / 100)),
    );
  }
}
