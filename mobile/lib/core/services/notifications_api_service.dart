import 'api_service.dart';

class NotificationsApiService {
  NotificationsApiService(this._api);

  final ApiService _api;

  Future<void> registerToken(String token, {String platform = 'ios'}) async {
    await _api.client.post(
      '/notifications/register-token',
      data: {
        'token': token,
        'platform': platform,
      },
    );
  }
}
