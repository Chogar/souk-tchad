import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../utils/avatar_image_prep.dart';
import 'api_service.dart';

class UsersService {
  UsersService(this._api);

  final ApiService _api;

  Future<UserModel> updateProfile({
    required String name,
    String? phone,
  }) async {
    final response = await _api.client.patch(
      '/users/me',
      data: {
        'name': name.trim(),
        if (phone != null) 'phone': phone.trim(),
      },
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> uploadAvatar(String filePath) async {
    final bytes = await prepareAvatarImage(filePath);
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(
        bytes,
        filename: 'avatar.jpg',
        contentType: DioMediaType.parse('image/jpeg'),
      ),
    });
    final response = await _api.client.post(
      '/users/me/avatar',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.client.patch(
      '/users/me/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> deleteAccount() async {
    await _api.client.delete('/users/me');
  }
}
