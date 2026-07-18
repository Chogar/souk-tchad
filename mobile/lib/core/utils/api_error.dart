import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../errors/google_sign_in_canceled.dart';
import '../l10n/app_strings.dart';

/// Retourne une chaîne vide si l'erreur doit être ignorée (ex. annulation Google).
String apiErrorMessage(
  Object error,
  AppStrings strings, {
  String? serverUrl,
}) {
  if (error is GoogleSignInCanceled) {
    return '';
  }

  if (error is GoogleSignInException) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return '';
    }
    if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
        error.code == GoogleSignInExceptionCode.providerConfigurationError) {
      return strings.googleInvalidClient;
    }
  }

  if (error is StateError) {
    switch (error.message) {
      case 'GOOGLE_NOT_CONFIGURED':
        return strings.googleNotConfigured;
      case 'GOOGLE_INVALID_CLIENT':
        return strings.googleInvalidClient;
      case 'GOOGLE_NO_ID_TOKEN':
        return strings.googleInvalidClient;
      case 'GOOGLE_USE_WEB_BUTTON':
        return strings.googleUseWebButton;
    }
  }

  if (error is PlatformException &&
      (error.code == 'google_sign_in' ||
          (error.message ?? '').contains('GIDClientID') ||
          (error.message ?? '').contains('invalid_client'))) {
    return strings.googleInvalidClient;
  }

  if (error is DioException) {
    if (error.response?.statusCode == 409) {
      return strings.emailAlreadyUsed;
    }
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) return message.join('\n');
      return message.toString();
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return strings.serverUnreachableDetail(
        serverUrl ?? error.requestOptions.baseUrl,
      );
    }
    if (error.type == DioExceptionType.sendTimeout) {
      return strings.photoUploadSlow;
    }
  }

  return error.toString().replaceAll('Exception: ', '');
}
