import '../services/chat_service.dart';
import 'listing_model.dart';
import 'user_model.dart';

class ConversationLastMessage {
  const ConversationLastMessage({
    required this.content,
    required this.createdAt,
    required this.senderId,
  });

  final String content;
  final DateTime createdAt;
  final String senderId;

  factory ConversationLastMessage.fromJson(Map<String, dynamic> json) {
    return ConversationLastMessage(
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      senderId: json['senderId'] as String,
    );
  }
}

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.listing,
    required this.buyer,
    required this.seller,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  final String id;
  final ListingModel listing;
  final UserModel buyer;
  final UserModel seller;
  final DateTime updatedAt;
  final ConversationLastMessage? lastMessage;
  final int unreadCount;

  UserModel otherParty(String currentUserId) =>
      buyer.id == currentUserId ? seller : buyer;

  String previewText({
    required String noMessagesLabel,
    required String voiceMessageLabel,
  }) {
    if (lastMessage == null) return noMessagesLabel;
    if (ChatService.isVoiceMessage(lastMessage!.content)) {
      return voiceMessageLabel;
    }
    return lastMessage!.content;
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      listing: ListingModel.fromJson(
        json['listing'] as Map<String, dynamic>,
      ),
      buyer: UserModel.fromJson(json['buyer'] as Map<String, dynamic>),
      seller: UserModel.fromJson(json['seller'] as Map<String, dynamic>),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastMessage: json['lastMessage'] != null
          ? ConversationLastMessage.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            )
          : null,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
