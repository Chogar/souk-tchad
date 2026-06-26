import '../models/user_model.dart';
import 'api_service.dart';

class PlanModel {
  const PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.maxListings,
    required this.hasAds,
  });

  final String id;
  final String name;
  final int price;
  final int maxListings;
  final bool hasAds;

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      maxListings: json['maxListings'] as int,
      hasAds: json['hasAds'] as bool? ?? false,
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

  Future<UserModel> subscribe(String planId) async {
    final response = await _api.client.post(
      '/subscriptions/subscribe',
      data: {'plan': planId},
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
