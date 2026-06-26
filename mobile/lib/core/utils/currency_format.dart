import 'package:intl/intl.dart';
import '../providers/locale_provider.dart';

/// Au Tchad : 1 ريال = 5 FCFA (XAF).
const xafPerRiyal = 5;

class CurrencyFormat {
  const CurrencyFormat._();

  /// Montant saisi dans le formulaire → XAF stocké en base.
  static double inputToXaf(double input, AppLocale locale) {
    if (locale == AppLocale.ar) return input * xafPerRiyal;
    return input;
  }

  /// XAF en base → montant affiché dans le formulaire.
  static double xafToInput(double priceXaf, AppLocale locale) {
    if (locale == AppLocale.ar) return priceXaf / xafPerRiyal;
    return priceXaf;
  }

  static String format(double priceXaf, AppLocale locale) {
    if (locale == AppLocale.ar) {
      final riyal = (priceXaf / xafPerRiyal).round();
      final formatted = NumberFormat.decimalPattern('ar').format(riyal);
      return '$formatted ريال';
    }
    return NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    ).format(priceXaf);
  }
}
