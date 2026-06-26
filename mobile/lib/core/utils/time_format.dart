import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';

String formatMessageTime(DateTime date, AppStrings strings, AppLocale locale) {
  final now = DateTime.now();
  final local = date.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(local.year, local.month, local.day);

  final intlLocale = switch (locale) {
    AppLocale.ar => 'ar',
    AppLocale.en => 'en',
    AppLocale.fr => 'fr',
  };

  if (messageDay == today) {
    return DateFormat.Hm(intlLocale).format(local);
  }
  if (messageDay == today.subtract(const Duration(days: 1))) {
    return strings.yesterday;
  }
  return DateFormat.MMMd(intlLocale).format(local);
}
