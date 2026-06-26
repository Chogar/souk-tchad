import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/server_config_service.dart';

final serverConfigServiceProvider =
    Provider<ServerConfigService>((ref) => ServerConfigService());

final apiBaseUrlProvider =
    AsyncNotifierProvider<ApiBaseUrlNotifier, String>(ApiBaseUrlNotifier.new);

class ApiBaseUrlNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    return ref.read(serverConfigServiceProvider).loadBaseUrl();
  }

  Future<String> saveAndApply(String raw) async {
    final service = ref.read(serverConfigServiceProvider);
    final url = service.normalizeUrl(raw);
    await service.saveBaseUrl(url);
    state = AsyncData(url);
    return url;
  }

  Future<void> testConnection(String raw) async {
    await ref.read(serverConfigServiceProvider).testConnection(raw);
  }
}
