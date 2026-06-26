import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

typedef RegisterPushToken = Future<void> Function(String token, String platform);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService(this._registerToken);

  final RegisterPushToken _registerToken;
  bool _ready = false;
  bool _permissionAsked = false;

  bool get isReady => _ready;

  Future<void> _ensureFirebase() async {
    if (_ready) return;
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _ready = true;
    } catch (e) {
      debugPrint('Push notifications unavailable (add Firebase config): $e');
    }
  }

  /// Appelé après connexion — pas au lancement de l'app.
  Future<void> enableAfterLogin() async {
    await _ensureFirebase();
    if (!_ready || _permissionAsked) {
      await registerCurrentToken();
      return;
    }

    _permissionAsked = true;
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_syncToken);
    await registerCurrentToken();
  }

  Future<void> registerCurrentToken() async {
    if (!_ready) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _syncToken(token);
  }

  Future<void> _syncToken(String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    try {
      await _registerToken(token, platform);
    } catch (e) {
      debugPrint('Push token registration failed: $e');
    }
  }
}
