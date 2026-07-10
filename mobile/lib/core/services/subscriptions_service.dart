import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class PlanModel {
  const PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.maxListings,
    required this.hasAds,
    this.paymentRequired = false,
    this.paymentAvailable = true,
  });

  final String id;
  final String name;
  final int price;
  final int maxListings;
  final bool hasAds;
  final bool paymentRequired;
  final bool paymentAvailable;

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      maxListings: json['maxListings'] as int,
      hasAds: json['hasAds'] as bool? ?? false,
      paymentRequired: json['paymentRequired'] as bool? ?? false,
      paymentAvailable: json['paymentAvailable'] as bool? ?? true,
    );
  }
}

class PaymentInstructions {
  const PaymentInstructions({
    required this.momoNumber,
    required this.momoLabel,
    required this.currency,
    required this.airtelMoneyNumber,
    required this.moovMoneyNumber,
  });

  final String momoNumber;
  final String momoLabel;
  final String currency;
  final String airtelMoneyNumber;
  final String moovMoneyNumber;

  String numberForProvider(String provider) {
    switch (provider) {
      case 'moov_money':
        return moovMoneyNumber;
      case 'airtel_money':
        return airtelMoneyNumber;
      default:
        return momoNumber;
    }
  }

  factory PaymentInstructions.fromJson(Map<String, dynamic> json) {
    final airtel =
        json['airtelMoneyNumber'] as String? ?? json['momoNumber'] as String? ?? '';
    final moov =
        json['moovMoneyNumber'] as String? ?? json['momoNumber'] as String? ?? '';
    return PaymentInstructions(
      momoNumber: json['momoNumber'] as String? ?? airtel,
      momoLabel: json['momoLabel'] as String? ?? 'Souk Tchad',
      currency: json['currency'] as String? ?? 'XAF',
      airtelMoneyNumber: airtel,
      moovMoneyNumber: moov,
    );
  }
}

class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.message,
    required this.momoNumber,
    required this.momoLabel,
    this.payerReference,
    this.provider,
  });

  final String orderId;
  final int amount;
  final String currency;
  final String message;
  final String momoNumber;
  final String momoLabel;
  final String? payerReference;
  final String? provider;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    final instructions =
        (json['instructions'] as Map<String, dynamic>?) ?? const {};
    return CheckoutResult(
      orderId: json['orderId'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String? ?? 'XAF',
      message: json['message'] as String? ?? '',
      momoNumber: instructions['momoNumber'] as String? ?? '',
      momoLabel: instructions['momoLabel'] as String? ?? 'Souk Tchad',
      payerReference: json['payerReference'] as String?,
      provider: json['provider'] as String?,
    );
  }
}

class SubscriptionsService {
  SubscriptionsService(this._api);

  final ApiService _api;

  Future<List<PlanModel>> getPlans() async {
    final response = await _api.client.get('/subscriptions/plans');
    return (response.data as List<dynamic>)
        .map((e) => PlanModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentInstructions> getPaymentInstructions() async {
    final response = await _api.client.get('/subscriptions/payment-instructions');
    return PaymentInstructions.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<UserModel> subscribe(String planId) async {
    final response = await _api.client.post(
      '/subscriptions/subscribe',
      data: {'plan': planId},
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CheckoutResult> checkout({
    required String planId,
    required String provider,
    required XFile proofImage,
  }) async {
    final bytes = await proofImage.readAsBytes();
    final name =
        proofImage.name.isNotEmpty ? proofImage.name : 'payment_proof.jpg';
    final formData = FormData.fromMap({
      'plan': planId,
      'provider': provider,
      'proof': MultipartFile.fromBytes(
        bytes,
        filename: name,
        contentType: DioMediaType.parse('image/jpeg'),
      ),
    });

    // Ne pas forcer Content-Type : Dio doit ajouter le boundary multipart.
    final response = await _api.client.post(
      '/subscriptions/checkout',
      data: formData,
      options: Options(
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return CheckoutResult.fromJson(response.data as Map<String, dynamic>);
  }
}
