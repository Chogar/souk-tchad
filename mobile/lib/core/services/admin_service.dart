import 'api_service.dart';

class AdminStats {
  const AdminStats({
    required this.usersTotal,
    required this.usersVerified,
    required this.listingsActive,
    required this.listingsModerated,
    required this.listingsTotal,
    required this.paymentsPending,
    required this.paymentsPaid,
    required this.revenueXaf,
    required this.conversations,
    required this.messages,
    required this.usersByPlan,
  });

  final int usersTotal;
  final int usersVerified;
  final int listingsActive;
  final int listingsModerated;
  final int listingsTotal;
  final int paymentsPending;
  final int paymentsPaid;
  final int revenueXaf;
  final int conversations;
  final int messages;
  final Map<String, int> usersByPlan;

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>? ?? {};
    final listings = json['listings'] as Map<String, dynamic>? ?? {};
    final payments = json['payments'] as Map<String, dynamic>? ?? {};
    final chat = json['chat'] as Map<String, dynamic>? ?? {};
    final byPlan = (users['byPlan'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );
    return AdminStats(
      usersTotal: (users['total'] as num?)?.toInt() ?? 0,
      usersVerified: (users['verified'] as num?)?.toInt() ?? 0,
      listingsActive: (listings['active'] as num?)?.toInt() ?? 0,
      listingsModerated: (listings['moderated'] as num?)?.toInt() ?? 0,
      listingsTotal: (listings['total'] as num?)?.toInt() ?? 0,
      paymentsPending: (payments['pending'] as num?)?.toInt() ?? 0,
      paymentsPaid: (payments['paid'] as num?)?.toInt() ?? 0,
      revenueXaf: (payments['revenueXaf'] as num?)?.toInt() ?? 0,
      conversations: (chat['conversations'] as num?)?.toInt() ?? 0,
      messages: (chat['messages'] as num?)?.toInt() ?? 0,
      usersByPlan: byPlan,
    );
  }
}

class AdminPaymentOrder {
  const AdminPaymentOrder({
    required this.id,
    required this.plan,
    required this.amount,
    required this.currency,
    required this.status,
    this.payerReference,
    this.provider,
    this.proofImageUrl,
    required this.createdAt,
    this.userName,
    this.userEmail,
    this.userPhone,
  });

  final String id;
  final String plan;
  final int amount;
  final String currency;
  final String status;
  final String? payerReference;
  final String? provider;
  final String? proofImageUrl;
  final DateTime createdAt;
  final String? userName;
  final String? userEmail;
  final String? userPhone;

  String get providerLabel {
    switch (provider) {
      case 'airtel_money':
        return 'Airtel Money';
      case 'moov_money':
        return 'Moov Money';
      default:
        return provider ?? 'Mobile Money';
    }
  }

  factory AdminPaymentOrder.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AdminPaymentOrder(
      id: json['id'] as String,
      plan: json['plan'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String? ?? 'XAF',
      status: json['status'] as String,
      payerReference: json['payerReference'] as String?,
      provider: json['provider'] as String?,
      proofImageUrl: json['proofImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userName: user?['name'] as String?,
      userEmail: user?['email'] as String?,
      userPhone: user?['phone'] as String?,
    );
  }
}

class AdminPaymentSettings {
  const AdminPaymentSettings({
    required this.airtelMoneyNumber,
    required this.moovMoneyNumber,
    required this.notificationEmail,
    required this.notifyOnPayment,
    required this.momoLabel,
    this.updatedAt,
  });

  final String airtelMoneyNumber;
  final String moovMoneyNumber;
  final String notificationEmail;
  final bool notifyOnPayment;
  final String momoLabel;
  final DateTime? updatedAt;

  factory AdminPaymentSettings.fromJson(Map<String, dynamic> json) {
    return AdminPaymentSettings(
      airtelMoneyNumber: json['airtelMoneyNumber'] as String? ?? '',
      moovMoneyNumber: json['moovMoneyNumber'] as String? ?? '',
      notificationEmail: json['notificationEmail'] as String? ?? '',
      notifyOnPayment: json['notifyOnPayment'] as bool? ?? true,
      momoLabel: json['momoLabel'] as String? ?? 'Souk Tchad',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

class AdminListingRow {
  const AdminListingRow({
    required this.id,
    required this.title,
    required this.status,
    required this.price,
    required this.city,
    required this.createdAt,
    this.ownerName,
  });

  final String id;
  final String title;
  final String status;
  final double price;
  final String city;
  final DateTime createdAt;
  final String? ownerName;

  factory AdminListingRow.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AdminListingRow(
      id: json['id'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      price: double.parse(json['price'].toString()),
      city: json['city'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      ownerName: user?['name'] as String?,
    );
  }
}

class AdminService {
  AdminService(this._api);

  final ApiService _api;

  Future<AdminStats> getStats() async {
    final response = await _api.client.get('/admin/stats');
    return AdminStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AdminPaymentOrder>> getPayments({String? status}) async {
    final response = await _api.client.get(
      '/admin/payments',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return (response.data as List<dynamic>)
        .map((e) => AdminPaymentOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> confirmPayment(String orderId) async {
    await _api.client.post('/admin/payments/$orderId/confirm');
  }

  Future<void> rejectPayment(String orderId) async {
    await _api.client.post('/admin/payments/$orderId/reject');
  }

  Future<AdminPaymentSettings> getPaymentSettings() async {
    final response = await _api.client.get('/admin/payment-settings');
    return AdminPaymentSettings.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<AdminPaymentSettings> updatePaymentSettings({
    required String airtelMoneyNumber,
    required String moovMoneyNumber,
    required String notificationEmail,
    required bool notifyOnPayment,
  }) async {
    final response = await _api.client.patch(
      '/admin/payment-settings',
      data: {
        'airtelMoneyNumber': airtelMoneyNumber.trim(),
        'moovMoneyNumber': moovMoneyNumber.trim(),
        'notificationEmail': notificationEmail.trim(),
        'notifyOnPayment': notifyOnPayment,
      },
    );
    return AdminPaymentSettings.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<AdminListingRow>> getListings({String? status}) async {
    final response = await _api.client.get(
      '/admin/listings',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return (response.data as List<dynamic>)
        .map((e) => AdminListingRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateListingStatus(String id, String status) async {
    await _api.client.patch(
      '/admin/listings/$id/status',
      data: {'status': status},
    );
  }
}
