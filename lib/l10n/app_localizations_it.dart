// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get myTeams => 'Le Mie Squadre';

  @override
  String get addTeam => 'Aggiungi Squadra';

  @override
  String get addNewTeam => 'Aggiungi Nuova Squadra';

  @override
  String get teamName => 'Nome Squadra';

  @override
  String get teamNameHint => 'es. Ragazzi Esordienti A';

  @override
  String get cancel => 'Annulla';

  @override
  String get add => 'Aggiungi';

  @override
  String get noTeamsYet => 'Nessuna squadra.';

  @override
  String get noTeamsHint =>
      'Tocca il pulsante + per aggiungere la tua prima squadra!';
}
