import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'api_service.dart';

class ChatService {
  ChatService(this._api);

  final ApiService _api;
  io.Socket? _socket;

  String get _socketUrl => _api.baseUrl.replaceAll('/api', '');

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final token = await _api.getToken();
    if (token == null) return;

    _socket = io.io(
      '$_socketUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );
  }

  void joinConversation(String conversationId) {
    _socket?.emit('join_conversation', {'conversationId': conversationId});
  }

  void sendMessageSocket(String conversationId, String content) {
    _socket?.emit('send_message', {
      'conversationId': conversationId,
      'content': content,
    });
  }

  void onNewMessage(
    void Function(MessageModel) callback, {
    String? conversationId,
  }) {
    _socket?.off('new_message');
    _socket?.on('new_message', (data) {
      final msg = MessageModel.fromJson(data as Map<String, dynamic>);
      if (conversationId != null && msg.conversationId != conversationId) {
        return;
      }
      callback(msg);
    });
  }

  void disconnect() {
    _socket?.off('new_message');
    _socket?.disconnect();
    _socket = null;
  }

  void onAnyNewMessage(void Function() callback) {
    _socket?.on('new_message', (_) => callback());
  }

  Future<List<ConversationModel>> getConversations() async {
    final response = await _api.client.get('/chat/conversations');
    return (response.data as List<dynamic>)
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _api.client.get('/chat/unread-count');
    return (response.data as num).toInt();
  }

  Future<void> markAsRead(String conversationId) async {
    await _api.client.post('/chat/conversations/$conversationId/read');
  }

  Future<ConversationModel> startConversation(String listingId) async {
    final response = await _api.client.post(
      '/chat/conversations',
      data: {'listingId': listingId},
    );
    return ConversationModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final response =
        await _api.client.get('/chat/conversations/$conversationId/messages');
    return (response.data as List<dynamic>)
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MessageModel> sendMessage(
    String conversationId,
    String content,
  ) async {
    final response = await _api.client.post(
      '/chat/conversations/$conversationId/messages',
      data: {'content': content},
    );
    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MessageModel> sendVoiceMessage(
    String conversationId,
    Uint8List bytes, {
    String filename = 'voice.m4a',
  }) async {
    final formData = FormData.fromMap({
      'audio': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _api.client.post(
      '/chat/conversations/$conversationId/voice',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MessageModel> sendImageMessage(
    String conversationId,
    Uint8List bytes, {
    String? filename,
  }) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: filename ?? 'image.jpg',
      ),
    });
    final response = await _api.client.post(
      '/chat/conversations/$conversationId/image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MessageModel> sendDocumentMessage(
    String conversationId,
    Uint8List bytes, {
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'document': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _api.client.post(
      '/chat/conversations/$conversationId/document',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  static bool isVoiceMessage(String content) => content.startsWith('voice:');

  static bool isImageMessage(String content) => content.startsWith('image:');

  static bool isDocumentMessage(String content) => content.startsWith('doc:');

  static String voiceUrl(ApiService api, String content) {
    return api.mediaUrl(content.replaceFirst('voice:', ''));
  }

  static String imageUrl(ApiService api, String content) {
    return api.mediaUrl(content.replaceFirst('image:', ''));
  }

  static String documentUrl(ApiService api, String content) {
    return api.mediaUrl(parseDocument(content).path);
  }

  static ({String name, String path}) parseDocument(String content) {
    final payload = content.replaceFirst('doc:', '');
    final sep = payload.indexOf('|');
    if (sep == -1) {
      return (name: payload.split('/').last, path: payload);
    }
    return (
      name: payload.substring(0, sep),
      path: payload.substring(sep + 1),
    );
  }
}
