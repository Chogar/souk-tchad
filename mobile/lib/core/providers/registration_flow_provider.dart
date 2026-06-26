import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationDraft {
  const RegistrationDraft({
    required this.email,
    this.registrationToken,
    this.devCode,
  });

  final String email;
  final String? registrationToken;
  final String? devCode;

  RegistrationDraft copyWith({
    String? email,
    String? registrationToken,
    String? devCode,
  }) {
    return RegistrationDraft(
      email: email ?? this.email,
      registrationToken: registrationToken ?? this.registrationToken,
      devCode: devCode ?? this.devCode,
    );
  }
}

class RegistrationDraftNotifier extends Notifier<RegistrationDraft?> {
  @override
  RegistrationDraft? build() => null;

  void setDraft(RegistrationDraft? draft) => state = draft;
}

final registrationDraftProvider =
    NotifierProvider<RegistrationDraftNotifier, RegistrationDraft?>(
  RegistrationDraftNotifier.new,
);
