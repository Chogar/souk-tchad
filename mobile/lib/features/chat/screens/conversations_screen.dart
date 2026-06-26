import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_format.dart';
import '../../../core/widgets/auth_required_view.dart';

final conversationsProvider =
    FutureProvider<List<ConversationModel>>((ref) async {
  if (ref.read(authStateProvider).value == null) return [];
  return ref.read(chatServiceProvider).getConversations();
});

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final strings = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final userId = ref.watch(authStateProvider).value?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.messages)),
        body: AuthRequiredView(
          icon: Icons.chat_bubble_outline,
          title: strings.guestMessagesTitle,
          message: strings.guestMessagesHint,
          redirectPath: '/',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.messages),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(conversationsProvider),
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.noConversations,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(shellTabIndexProvider.notifier).setIndex(0),
                      icon: const Icon(Icons.storefront_outlined),
                      label: Text(strings.browseListings),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(conversationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final other = userId != null
                    ? conv.otherParty(userId)
                    : conv.seller;
                final preview = conv.previewText(
                  noMessagesLabel: strings.noMessagesYet,
                  voiceMessageLabel: strings.voiceMessage,
                );
                final time = conv.lastMessage != null
                    ? formatMessageTime(
                        conv.lastMessage!.createdAt,
                        strings,
                        locale,
                      )
                    : formatMessageTime(conv.updatedAt, strings, locale);
                final hasUnread = conv.unreadCount > 0;

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            AppColors.primaryBlue.withValues(alpha: 0.1),
                        child: Text(
                          conv.listing.category.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.accentRed,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              conv.unreadCount > 9
                                  ? '9+'
                                  : '${conv.unreadCount}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    conv.listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        other.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.normal,
                          color: hasUnread
                              ? AppColors.primaryBlue
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasUnread
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary,
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  onTap: () => context.push(
                    '/chat/${conv.id}',
                    extra: conv,
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(strings.errorWith('$e'))),
      ),
    );
  }
}
