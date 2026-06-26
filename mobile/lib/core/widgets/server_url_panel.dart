import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locale_provider.dart';
import '../providers/server_config_provider.dart';
import '../utils/api_error.dart';

class ServerUrlPanel extends ConsumerStatefulWidget {
  const ServerUrlPanel({
    super.key,
    this.initiallyExpanded = false,
  });

  final bool initiallyExpanded;

  @override
  ConsumerState<ServerUrlPanel> createState() => _ServerUrlPanelState();
}

class _ServerUrlPanelState extends ConsumerState<ServerUrlPanel> {
  final _controller = TextEditingController();
  late bool _expanded;
  bool _busy = false;
  String? _syncedUrl;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncField(String url) {
    if (_syncedUrl == url) return;
    _syncedUrl = url;
    _controller.text = url;
  }

  Future<void> _test() async {
    final strings = ref.read(stringsProvider);
    setState(() => _busy = true);
    try {
      await ref.read(apiBaseUrlProvider.notifier).testConnection(_controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.connectionOk)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.connectionFailed(apiErrorMessage(e, strings))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final strings = ref.read(stringsProvider);
    setState(() => _busy = true);
    try {
      final url = await ref
          .read(apiBaseUrlProvider.notifier)
          .saveAndApply(_controller.text);
      _syncField(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.serverUrlSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.connectionFailed(apiErrorMessage(e, strings))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final serverUrl = ref.watch(apiBaseUrlProvider).value;
    if (serverUrl != null) {
      _syncField(serverUrl);
    }

    final isLocalhost = serverUrl != null &&
        (serverUrl.contains('127.0.0.1') || serverUrl.contains('localhost'));

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              isLocalhost ? Icons.warning_amber_rounded : Icons.wifi_tethering,
              color: isLocalhost ? Colors.orange.shade800 : null,
            ),
            title: Text(strings.serverConnection),
            subtitle: Text(
              serverUrl ?? strings.serverUrlHint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isLocalhost)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        strings.serverLocalhostWarning,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: strings.serverUrl,
                      hintText: strings.serverUrlHint,
                      prefixIcon: const Icon(Icons.dns_outlined),
                      helperText: strings.serverUrlHelper,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _test,
                          icon: const Icon(Icons.wifi_find),
                          label: Text(strings.testConnection),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(strings.save),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
