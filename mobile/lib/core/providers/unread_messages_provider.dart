import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/chat/screens/conversations_screen.dart';

final unreadMessagesCountProvider = Provider<int>((ref) {
  final conversations = ref.watch(conversationsProvider);
  return conversations.maybeWhen(
    data: (list) =>
        list.fold<int>(0, (sum, conversation) => sum + conversation.unreadCount),
    orElse: () => 0,
  );
});
