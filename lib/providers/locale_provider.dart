import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en'));

  void setLocale(Locale locale) {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    state = locale;
  }
}

// A simple mock localization system for demonstration purposes
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('ha'), // Hausa
    Locale('fr'), // French
    Locale('sw'), // Swahili
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'welcome': 'Welcome Agent',
      'dashboard': 'Dashboard',
      'scanBeneficiary': 'Disburse Aid',
      'dailyReport': 'Daily Report',
      'totalDistributions': 'Total Distributions',
      'verifiedBeneficiaries': 'Verified Beneficiaries',
      'language': 'Language',
      'login': 'Login Securely',
      'syncing': 'Syncing Data...',
    },
    'ha': {
      'welcome': 'Barka da zuwa Agent',
      'dashboard': 'Allon Kulawa',
      'scanBeneficiary': 'Bayar da Taimako',
      'dailyReport': 'Rahoton Yau',
      'totalDistributions': 'Jimillar Rarrabawa',
      'verifiedBeneficiaries': 'Ingantattun Masu Karba',
      'language': 'Harshe',
      'login': 'Shiga Cikin Tsaro',
      'syncing': 'Ana Daidaita bayanai...',
    },
    'fr': {
      'welcome': 'Bienvenue Agent',
      'dashboard': 'Tableau de bord',
      'scanBeneficiary': 'Distribuer l\'aide',
      'dailyReport': 'Rapport Quotidien',
      'totalDistributions': 'Distributions totales',
      'verifiedBeneficiaries': 'Bénéficiaires vérifiés',
      'language': 'Langue',
      'login': 'Connexion sécurisée',
      'syncing': 'Synchronisation des données...',
    },
    'sw': {
      'welcome': 'Karibu Wakala',
      'dashboard': 'Dashibodi',
      'scanBeneficiary': 'Kusambaza Msaada',
      'dailyReport': 'Ripoti ya Kila Siku',
      'totalDistributions': 'Jumla ya Usambazaji',
      'verifiedBeneficiaries': 'Wafaidika Waliothibitishwa',
      'language': 'Lugha',
      'login': 'Ingia kwa Usalama',
      'syncing': 'Inasawazisha Data...',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .map((l) => l.languageCode)
      .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
