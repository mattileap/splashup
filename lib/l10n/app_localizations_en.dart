// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get myTeams => 'My Teams';

  @override
  String get addTeam => 'Add Team';

  @override
  String get addNewTeam => 'Add New Team';

  @override
  String get teamName => 'Team Name';

  @override
  String get teamNameHint => 'e.g., Varsity Girls';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get noTeamsYet => 'No teams yet.';

  @override
  String get noTeamsHint => 'Tap the + button to add your first team!';
}
