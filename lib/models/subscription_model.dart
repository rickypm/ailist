class SubscriptionModel {
  final String id;
  final String odId; // user_id or professional_id
  final String odType; // 'user' or 'professional'
  final String plan;
  final String status; // 'active', 'cancelled', 'expired'
  final double amount;
  final String currency;
  final String?  paymentId;
  final String? orderId;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final DateTime createdAt;
  final DateTime?  cancelledAt;

  SubscriptionModel({
    required this.id,
    required this.odId,
    required this.odType,
    required this.plan,
    required this.status,
    required this. amount,
    this.currency = 'INR',
    this.paymentId,
    this.orderId,
    required this.startDate,
    required this.endDate,
    this.autoRenew = true,
    required this.createdAt,
    this.cancelledAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] ?? '',
      odId: json['owner_id'] ?? '',
      odType: json['owner_type'] ?? 'user',
      plan: json['plan'] ?? 'free',
      status: json['status'] ?? 'active',
      amount: (json['amount'] ??  0).toDouble(),
      currency: json['currency'] ?? 'INR',
      paymentId: json['payment_id'],
      orderId: json['order_id'],
      startDate:  json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now().add(const Duration(days: 30)),
      autoRenew: json['auto_renew'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': odId,
      'owner_type': odType,
      'plan': plan,
      'status':  status,
      'amount': amount,
      'currency': currency,
      'payment_id': paymentId,
      'order_id': orderId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'auto_renew': autoRenew,
      'created_at': createdAt.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }

  bool get isActive => status == 'active' && endDate. isAfter(DateTime.now());
  bool get isExpired => endDate.isBefore(DateTime.now());
  bool get isCancelled => status == 'cancelled';

  int get daysRemaining {
    if (isExpired) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  String get planDisplayName {
    switch (plan) {
      case 'basic':
        return 'Basic';
      case 'plus':
        return 'Plus';
      case 'pro':
        return 'Pro';
      case 'starter':
        return 'Starter';
      case 'business':
        return 'Business';
      default:
        return 'Free';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'active': 
        return 'Active';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
        return 'Expired';
      default:
        return status.toUpperCase();
    }
  }

  SubscriptionModel copyWith({
    String? id,
    String?  odId,
    String? odType,
    String? plan,
    String? status,
    double? amount,
    String?  currency,
    String? paymentId,
    String? orderId,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoRenew,
    DateTime? createdAt,
    DateTime? cancelledAt,
  }) {
    return SubscriptionModel(
      id:  id ?? this.id,
      odId: odId ?? this. odId,
      odType:  odType ?? this.odType,
      plan: plan ?? this. plan,
      status: status ??  this.status,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentId: paymentId ?? this.paymentId,
      orderId: orderId ??  this.orderId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      autoRenew: autoRenew ?? this.autoRenew,
      createdAt:  createdAt ?? this.createdAt,
      cancelledAt:  cancelledAt ?? this.cancelledAt,
    );
  }
}