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
  String get teamNameHint => 'es. Nome Squadra - Categoria';

  @override
  String get pool => 'Vasca';

  @override
  String get cancel => 'Annulla';

  @override
  String get add => 'Aggiungi';

  @override
  String get noTeamsYet => 'Nessuna squadra.';

  @override
  String get noTeamsHint =>
      'Tocca il pulsante + per aggiungere la tua prima squadra!';

  @override
  String get athletes => 'Atleti';

  @override
  String get addAthlete => 'Aggiungi Atleta';

  @override
  String get addNewAthlete => 'Aggiungi Nuovo Atleta';

  @override
  String get athleteName => 'Nome Atleta';

  @override
  String get birthYear => 'Anno di Nascita';

  @override
  String get gender => 'Sesso';

  @override
  String get male => 'Maschio';

  @override
  String get female => 'Femmina';

  @override
  String get preferredStyles => 'Stili Preferiti';

  @override
  String get freestyle => 'Stile Libero';

  @override
  String get butterfly => 'Farfalla';

  @override
  String get backstroke => 'Dorso';

  @override
  String get breaststroke => 'Rana';

  @override
  String get status => 'Stato';

  @override
  String get active => 'Attivo';

  @override
  String get inactive => 'Inattivo';

  @override
  String get notes => 'Note';

  @override
  String get noAthletesYet => 'Nessun atleta.';

  @override
  String get noAthletesHint =>
      'Tocca il pulsante + per aggiungere il tuo primo atleta!';

  @override
  String get searchAthletes => 'Cerca atleti...';

  @override
  String get showInactive => 'Mostra Inattivi';

  @override
  String get notesTitle => 'Note Atleta';

  @override
  String get noNotesForAthlete => 'Nessuna nota per questo atleta.';

  @override
  String get close => 'Chiudi';

  @override
  String get athleteDetails => 'Dettagli Atleta';

  @override
  String get editAthlete => 'Modifica Atleta';

  @override
  String get age => 'Età';

  @override
  String get noTimesRecorded => 'Nessun tempo registrato.';

  @override
  String get addYourFirstTime =>
      'Tocca il pulsante + per aggiungere il primo tempo!';

  @override
  String get addChrono => 'Aggiungi Crono';

  @override
  String get editChrono => 'Modifica Crono';

  @override
  String get date => 'Data';

  @override
  String get poolLength => 'Lunghezza Vasca';

  @override
  String get distance => 'Distanza (metri)';

  @override
  String get style => 'Stile';

  @override
  String get im => 'Misti';

  @override
  String get finalTime => 'Tempo Finale';

  @override
  String get finalTimeHint => 'MM:SS.ss';

  @override
  String get save => 'Salva';

  @override
  String get delete => 'Elimina';

  @override
  String get deleteConfirmation =>
      'Sei sicuro di voler eliminare questo tempo?';

  @override
  String get deleteChronoTitle => 'Elimina Crono';

  @override
  String get unsavedChanges => 'Modifiche non salvate';

  @override
  String get discardChangesWarning =>
      'Hai delle modifiche non salvate. Sei sicuro di volerle ignorare?';

  @override
  String get discard => 'Ignora';

  @override
  String get filterBy => 'Filtra per:';

  @override
  String get allDistances => 'Tutte le Distanze';

  @override
  String get allStyles => 'Tutti gli Stili';

  @override
  String get noResultsFound => 'Nessun risultato per i filtri selezionati.';

  @override
  String get favoriteStyles => 'Stili Preferiti';

  @override
  String get chronoType => 'Tipo';

  @override
  String get training => 'Allenamento';

  @override
  String get race => 'Gara';

  @override
  String get allTypes => 'Tutti i Tipi';

  @override
  String get personalBestsTitle => 'Migliori Personali';

  @override
  String get noBestsYet => 'Nessun record personale registrato.';

  @override
  String get settings => 'Impostazioni';

  @override
  String get appearance => 'Aspetto';

  @override
  String get theme => 'Tema';

  @override
  String get light => 'Chiaro';

  @override
  String get dark => 'Scuro';

  @override
  String get system => 'Sistema';

  @override
  String teamDeleted(String teamName) {
    return 'Squadra \"$teamName\" eliminata.';
  }

  @override
  String get deleteData => 'Reset Dati App';

  @override
  String get deleteAccount => 'Elimina Account';

  @override
  String get deleteDataWarning =>
      'Questa azione è irreversibile. Tutte le tue squadre, atleti e record verranno eliminati permanentemente.';

  @override
  String get dataReset => 'Tutti i dati sono stati eliminati';

  @override
  String get dataResetFailed => 'Eliminazione dati fallita.';

  @override
  String get typeToDelete => 'Scrivi \'DELETE\' per confermare';

  @override
  String get editTeam => 'Modifica Squadra';

  @override
  String get deleteAthlete => 'Elimina Atleta';

  @override
  String get deleteAthleteWarning =>
      'Questo eliminerà permanentemente l\'atleta e tutti i suoi tempi registrati. Vuoi invece disattivarlo?';

  @override
  String get deactivate => 'Disattiva';

  @override
  String get deleteAnyway => 'Elimina Comunque';

  @override
  String get dataManagement => 'Gestione Dati';

  @override
  String get moveAthletes => 'Sposta Atleti';

  @override
  String get moveAthletesDescription => 'Sposta atleti tra le squadre.';

  @override
  String get moveAthletesDeny =>
      'Hai bisogno di almeno due squadre per utilizzare questa funzionalità.';

  @override
  String get moveSingleAthlete => 'Sposta un singolo atleta';

  @override
  String get moveAthletesByYear => 'Sposta atleti per anno di nascita';

  @override
  String get moveAllAthletes => 'Sposta tutti gli atleti di una squadra';

  @override
  String get sourceTeam => 'Squadra di Partenza';

  @override
  String get destinationTeam => 'Squadra di Destinazione';

  @override
  String get selectAthlete => 'Seleziona Atleta';

  @override
  String get noAthletesInTeam => 'Nessun atleta in questa squadra.';

  @override
  String get move => 'Sposta';

  @override
  String get selectTeamsFirst =>
      'Seleziona prima la squadra di partenza e di destinazione.';

  @override
  String get moveConfirmation =>
      'Sei sicuro di voler spostare gli atleti selezionati?';

  @override
  String get moveSuccess => 'Atleti spostati con successo.';

  @override
  String get selectBirthYear => 'Seleziona Anno di Nascita';

  @override
  String get selectSourceTeamFirst => 'Seleziona prima la squadra di partenza';

  @override
  String get noYearsInTeam => 'Nessun atleta con anno di nascita trovato.';

  @override
  String get deleteTeam => 'Elimina Squadra';

  @override
  String get deleteTeamDescription =>
      'Elimina permanentemente una squadra e i suoi atleti.';

  @override
  String get selectTeamToDelete => 'Seleziona Squadra da Eliminare';

  @override
  String get deleteTeamWarning =>
      'Questo eliminerà permanentemente la squadra e tutti i suoi atleti. Cosa vorresti fare?';

  @override
  String get moveAthletesOption => 'Prima Sposta Atleti';

  @override
  String get deleteTeamConfirmation =>
      'Questa azione è irreversibile. Per confermare, scrivi DELETE qui sotto.';

  @override
  String get dataCleanup => 'Pulizia Dati';

  @override
  String get deactivateInactiveAthletes => 'Disattiva Atleti Inattivi';

  @override
  String get deactivateInactiveDescription =>
      'Imposta automaticamente gli atleti come \'Inattivi\' se non hanno nuovi tempi registrati.';

  @override
  String get deactivateAfter => 'Disattiva dopo';

  @override
  String get months => 'mesi';

  @override
  String get run => 'Esegui';

  @override
  String get deactivationConfirmation =>
      'Questo controllerà tutti gli atleti attivi. Se il loro ultimo tempo registrato è più vecchio del periodo selezionato, verranno impostati come \'Inattivi\'. Sei sicuro di voler procedere?';

  @override
  String deactivationComplete(Object count) {
    return 'Pulizia completata. $count atleta(i) sono stati disattivati.';
  }

  @override
  String get deleteInactiveAthletes => 'Elimina Atleti Inattivi';

  @override
  String get deleteInactiveDescription =>
      'Elimina permanentemente gli atleti che sono inattivi da molto tempo.';

  @override
  String get deleteAfter => 'Elimina dopo';

  @override
  String get years => 'anni';

  @override
  String get deletionConfirmation =>
      'Questo eliminerà permanentemente tutti gli atleti che sono stati inattivi per più del periodo selezionato. Questa azione non può essere annullata. Sei sicuro?';

  @override
  String deletionComplete(Object count) {
    return 'Pulizia completata. $count atleta(i) sono stati eliminati.';
  }

  @override
  String get googleSignIn => 'Accedi con Google';

  @override
  String get stopwatch => 'Cronometro';

  @override
  String get lap => 'Giro';

  @override
  String get laps => 'Giri';

  @override
  String get reset => 'Azzera';

  @override
  String get start => 'Avvia';

  @override
  String get stop => 'Ferma';

  @override
  String get saveTime => 'Salva Tempo';

  @override
  String get chronoNotesTitle => 'Note del Tempo';

  @override
  String get noNotesForChrono => 'Nessuna nota per questo tempo.';

  @override
  String get splits => 'Tempi Parziali';

  @override
  String get splitDistance => 'Distanza Parziale';

  @override
  String get noSplitsYet => 'Nessun parziale aggiunto';

  @override
  String get splitTimeHint => 'MM:SS.ss';

  @override
  String splitTimeInvalidError(Object index) {
    return 'Parziale $index: inserisci un tempo cumulativo valido';
  }

  @override
  String splitDistanceMultiple(Object number, Object poolLength) {
    return 'Parziale $number: la distanza deve essere multiplo di $poolLength m';
  }

  @override
  String splitDistanceExceeds(
    Object number,
    Object splitDistance,
    Object totalDistance,
  ) {
    return 'Parziale $number: la distanza ($splitDistance m) supera la distanza totale ($totalDistance m)';
  }

  @override
  String splitDistanceOrder(Object number) {
    return 'Parziale $number: le distanze devono essere in ordine crescente';
  }

  @override
  String splitTimeOrder(Object number) {
    return 'Parziale $number: i tempi devono essere in ordine crescente';
  }

  @override
  String get segment => 'Parziale';

  @override
  String get cumulative => 'Cumulativo';

  @override
  String get invalidTimeFormat => 'Formato tempo non valido';

  @override
  String get splitAnalysis => 'Analisi Parziali';

  @override
  String get filters => 'Filtri';

  @override
  String get type => 'Tipologia';

  @override
  String get legend => 'Legenda';

  @override
  String get noSplitData => 'Nessun dato parziale disponibile';

  @override
  String get tryDifferentFilter =>
      'Prova a selezionare una distanza o uno stile diverso';

  @override
  String get noVisibleLines =>
      'Nessuna linea visibile. Abilita almeno una dalla legenda qui sotto.';

  @override
  String showRecords(Object count) {
    return 'Mostra record: $count';
  }

  @override
  String get distanceMeters => 'Distanza (m)';

  @override
  String get timeSeconds => 'Tempo (s)';

  @override
  String get tooltipMode => 'Visualizzazione Tooltip';

  @override
  String get compactData => 'Compatto (tutti i tempi alla distanza)';

  @override
  String get detailedData => 'Dettagliato (analisi segmento)';

  @override
  String get selectSingleLineForDetails =>
      'Seleziona una sola linea nella checkbox per avere i dettagli corretti';

  @override
  String get appSlogan => 'Dive in. Stand out. SplashUp';

  @override
  String get welcomeSubtitle =>
      'Il tuo compagno di nuoto\n100% Offline & Privato';

  @override
  String get diveInButton => 'Tuffati!';

  @override
  String get loadTestDataTitle => 'Benvenuto in SplashUp!';

  @override
  String get loadTestDataMessage =>
      'Sembra che il tuo database sia vuoto. Vuoi caricare dei dati di prova per esplorare l\'app, oppure preferisci iniziare da zero?';

  @override
  String get loadTestDataBtn => 'Carica Dati di Prova';

  @override
  String get startFreshBtn => 'Inizia da Zero';

  @override
  String get sameSourceDestError =>
      'La squadra di origine e quella di destinazione non possono coincidere.';

  @override
  String get noAthletesToMove => 'Nessun atleta da spostare.';

  @override
  String teamAlsoDeleted(Object name) {
    return '\"$name\" è stata eliminata.';
  }

  @override
  String get errorMovingAthletes =>
      'Errore durante lo spostamento degli atleti';

  @override
  String get moveType => 'Tipo di spostamento';

  @override
  String get errorDeactivation => 'Errore durante la disattivazione';

  @override
  String get errorDeletion => 'Errore durante l\'eliminazione';

  @override
  String get requiredField => 'Obbligatorio';

  @override
  String get timeGreaterThanZero => 'Il tempo deve essere maggiore di zero';

  @override
  String get pleaseEnterName => 'Inserisci un nome';

  @override
  String get pleaseSelectYear => 'Seleziona un anno';

  @override
  String get somethingWentWrong => 'Qualcosa è andato storto';

  @override
  String errorWithDetails(Object error) {
    return 'Errore: $error';
  }

  @override
  String get hideSplits => 'Nascondi parziali';

  @override
  String get showSplits => 'Mostra parziali';

  @override
  String get startLabel => 'Partenza';

  @override
  String get splitLabel => 'Parziale:';

  @override
  String errorSavingAthlete(Object error) {
    return 'Errore nel salvataggio dell\'atleta: $error';
  }

  @override
  String errorSavingChrono(Object error) {
    return 'Errore nel salvataggio del tempo: $error';
  }

  @override
  String get dummyTeamNoviceA => 'Squadra A - Esordienti A';

  @override
  String get dummyTeamMasters => 'Squadra A - Master';

  @override
  String get dummyTeamB => 'Squadra B';

  @override
  String get dummyTeamJuniors => 'Squadra C - Juniores';

  @override
  String dummyAthleteName(Object code) {
    return 'Atleta $code';
  }

  @override
  String get dummyCodeNovice => 'ES';

  @override
  String get dummyCodeMasters => 'M';

  @override
  String get dummyCodeJuniors => 'J';

  @override
  String get dummyAthleteNote =>
      'Atleta di esempio creato a scopo dimostrativo.';

  @override
  String get dummyNoteRace => 'Gara di esempio';

  @override
  String get dummyNoteTraining => 'Allenamento di esempio';

  @override
  String get dummyNotePersonalBest => 'Record personale!';
}
