import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/models/message_model.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/time_format.dart';
import 'conversations_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  final String conversationId;
  final ConversationModel? conversation;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  List<MessageModel> _messages = [];
  ConversationModel? _conversation;
  bool _loading = true;
  bool _isRecording = false;
  bool _uploading = false;
  String? _playingMessageId;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _initChat();
  }

  void _appendMessage(MessageModel msg) {
    if (_messages.any((m) => m.id == msg.id)) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  Future<void> _initChat() async {
    final chat = ref.read(chatServiceProvider);
    await chat.connect();
    chat.joinConversation(widget.conversationId);
    chat.onNewMessage(
      (msg) {
        if (!mounted) return;
        _appendMessage(msg);
        ref.invalidate(conversationsProvider);
      },
      conversationId: widget.conversationId,
    );

    if (_conversation == null) {
      try {
        final conversations = await chat.getConversations();
        for (final conversation in conversations) {
          if (conversation.id == widget.conversationId) {
            _conversation = conversation;
            break;
          }
        }
      } catch (_) {}
    }

    try {
      await chat.markAsRead(widget.conversationId);
      ref.invalidate(conversationsProvider);
    } catch (_) {}

    final messages = await chat.getMessages(widget.conversationId);
    if (mounted) {
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final chat = ref.read(chatServiceProvider);
    final msg = await chat.sendMessage(widget.conversationId, text);
    _appendMessage(msg);
    ref.invalidate(conversationsProvider);
  }

  Future<void> _startRecording() async {
    if (kIsWeb) return;

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(stringsProvider).micPermission)),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() => _isRecording = true);
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path == null || path.isEmpty) return;

    try {
      final bytes = await XFile(path).readAsBytes();
      final chat = ref.read(chatServiceProvider);
      final msg = await chat.sendVoiceMessage(
        widget.conversationId,
        bytes,
        filename: p.basename(path),
      );
      if (mounted) {
        _appendMessage(msg);
        ref.invalidate(conversationsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${ref.read(stringsProvider).voiceError} : $e',
            ),
          ),
        );
      }
    }
  }

  Future<Uint8List> _prepareImageBytes(XFile file) async {
    if (kIsWeb) return file.readAsBytes();

    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/chat_${DateTime.now().microsecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 75,
      minWidth: 1200,
      minHeight: 1200,
    );

    if (result != null) {
      return XFile(result.path).readAsBytes();
    }
    return file.readAsBytes();
  }

  Future<void> _pickImage() async {
    if (_uploading) return;

    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await _prepareImageBytes(file);
      final chat = ref.read(chatServiceProvider);
      final msg = await chat.sendImageMessage(
        widget.conversationId,
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'image.jpg',
      );
      if (mounted) {
        _appendMessage(msg);
        ref.invalidate(conversationsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${ref.read(stringsProvider).attachmentError} : $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickDocument() async {
    if (_uploading) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await XFile(file.path!).readAsBytes();
    }
    if (bytes == null) return;

    setState(() => _uploading = true);
    try {
      final chat = ref.read(chatServiceProvider);
      final msg = await chat.sendDocumentMessage(
        widget.conversationId,
        bytes,
        filename: file.name,
      );
      if (mounted) {
        _appendMessage(msg);
        ref.invalidate(conversationsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${ref.read(stringsProvider).attachmentError} : $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openDocument(MessageModel msg) async {
    final api = ref.read(apiServiceProvider);
    final url = ChatService.documentUrl(api, msg.content);
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(stringsProvider).attachmentError)),
        );
      }
    }
  }

  void _openImagePreview(String url) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _playVoice(MessageModel msg) async {
    final api = ref.read(apiServiceProvider);
    final url = ChatService.voiceUrl(api, msg.content);
    if (_playingMessageId == msg.id) {
      await _audioPlayer.stop();
      setState(() => _playingMessageId = null);
      return;
    }
    setState(() => _playingMessageId = msg.id);
    await _audioPlayer.play(UrlSource(url));
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingMessageId = null);
    });
  }

  Widget _messageBubble(
    MessageModel msg,
    bool isMe,
    AppStrings strings,
    AppLocale locale,
  ) {
    final api = ref.read(apiServiceProvider);
    final isVoice = ChatService.isVoiceMessage(msg.content);
    final isImage = ChatService.isImageMessage(msg.content);
    final isDocument = ChatService.isDocumentMessage(msg.content);
    final time = formatMessageTime(msg.createdAt, strings, locale);

    Widget bubbleContent;
    if (isVoice) {
      bubbleContent = InkWell(
        onTap: () => _playVoice(msg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _playingMessageId == msg.id
                  ? Icons.stop_circle
                  : Icons.play_circle_fill,
              color: isMe ? Colors.white : AppColors.primaryBlue,
            ),
            const SizedBox(width: 8),
            Text(
              strings.voiceMessage,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      );
    } else if (isImage) {
      final url = ChatService.imageUrl(api, msg.content);
      bubbleContent = InkWell(
        onTap: () => _openImagePreview(url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                width: 200,
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (_, _, _) => Icon(
              Icons.broken_image_outlined,
              color: isMe ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ),
      );
    } else if (isDocument) {
      final doc = ChatService.parseDocument(msg.content);
      bubbleContent = InkWell(
        onTap: () => _openDocument(msg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              color: isMe ? Colors.white : AppColors.primaryBlue,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    strings.openDocument,
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      bubbleContent = Text(
        msg.content,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          height: 1.35,
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryBlue : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: bubbleContent,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).value?.id;
    final strings = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final conv = _conversation;
    final other = userId != null && conv != null
        ? conv.otherParty(userId)
        : null;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: conv != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (other != null)
                    Text(
                      other.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              )
            : Text(strings.chatTitle),
        actions: [
          if (conv != null)
            IconButton(
              tooltip: strings.viewListing,
              icon: const Icon(Icons.storefront_outlined),
              onPressed: () => context.push('/listing/${conv.listing.id}'),
            ),
        ],
      ),
      body: Column(
        children: [
          if (conv != null)
            Material(
              color: AppColors.primaryBlue.withValues(alpha: 0.06),
              child: InkWell(
                onTap: () => context.push('/listing/${conv.listing.id}'),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        conv.listing.category.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conv.listing.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${CurrencyFormat.format(conv.listing.price, strings.locale)} · ${conv.listing.city}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            strings.chatEmptyHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.sender.id == userId;
                          return _messageBubble(msg, isMe, strings, locale);
                        },
                      ),
          ),
          if (_isRecording)
            Container(
              width: double.infinity,
              color: AppColors.accentRed.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                strings.recordingHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.accentRed),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _uploading ? null : _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    tooltip: strings.attachImage,
                  ),
                  IconButton(
                    onPressed: _uploading ? null : _pickDocument,
                    icon: const Icon(Icons.attach_file),
                    tooltip: strings.attachDocument,
                  ),
                  if (!kIsWeb)
                    IconButton.filled(
                      onPressed: _uploading ? null : _toggleRecording,
                      icon: Icon(
                        _isRecording ? Icons.stop_circle : Icons.mic,
                        color: _isRecording ? AppColors.accentRed : null,
                      ),
                      tooltip: _isRecording
                          ? strings.recordingHint
                          : strings.voiceMessage,
                    ),
                  if (!kIsWeb) const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_uploading,
                      decoration: InputDecoration(
                        hintText: strings.yourMessage,
                        border: const OutlineInputBorder(),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (_uploading)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton.filled(
                      onPressed: _send,
                      icon: const Icon(Icons.send),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
