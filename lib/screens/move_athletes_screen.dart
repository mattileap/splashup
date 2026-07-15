import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/team_model.dart';
import '../models/athlete_model.dart';
import '../repositories/database_repository.dart';

enum MoveType { single, byYear, all }

class MoveAthletesScreen extends StatefulWidget {
  final Team? initialSourceTeam;
  // ADDED: New parameter to control deletion after moving.
  final bool deleteSourceTeamOnSuccess;

  const MoveAthletesScreen({
    super.key,
    this.initialSourceTeam,
    this.deleteSourceTeamOnSuccess = false, // Defaults to false
  });

  @override
  State<MoveAthletesScreen> createState() => _MoveAthletesScreenState();
}

class _MoveAthletesScreenState extends State<MoveAthletesScreen> {
  MoveType _moveType = MoveType.single;
  Team? _sourceTeam;
  Team? _destinationTeam;
  Athlete? _selectedAthlete;
  int? _selectedBirthYear;

  // Stream creati fuori da build(): crearli inline causava una nuova
  // sottoscrizione a ogni rebuild. Lo stream degli atleti viene ricreato
  // solo quando cambia la squadra sorgente o il tipo di spostamento.
  late final Stream<List<Team>> _teamsStream;
  Stream<List<Athlete>>? _sourceAthletesStream;

  @override
  void initState() {
    super.initState();
    if (widget.initialSourceTeam != null) {
      _sourceTeam = widget.initialSourceTeam;
      _moveType = MoveType.all;
    }
    _teamsStream = context.read<DatabaseRepository>().getTeamsStream();
    _refreshSourceAthletesStream();
  }

  /// Ricrea lo stream degli atleti della squadra sorgente. Va richiamato
  /// quando cambia _sourceTeam o _moveType (gli stream Sembast sono
  /// single-subscription: il cambio di selettore richiede uno stream nuovo).
  void _refreshSourceAthletesStream() {
    _sourceAthletesStream = _sourceTeam == null
        ? null
        : context.read<DatabaseRepository>().getAthletesStream(_sourceTeam!.id);
  }

  Future<void> _performMove() async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final db = context.read<DatabaseRepository>();

    if (_sourceTeam == null || _destinationTeam == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.selectTeamsFirst)));
      return;
    }
    if (_sourceTeam!.id == _destinationTeam!.id) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sameSourceDestError)));
      return;
    }
    // Validazione PRIMA del dialog di conferma: senza questi check l'utente
    // confermava lo spostamento e non succedeva nulla, senza alcun messaggio.
    if (_moveType == MoveType.single && _selectedAthlete == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.selectAthlete)));
      return;
    }
    if (_moveType == MoveType.byYear && _selectedBirthYear == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.selectBirthYear)));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.moveAthletes),
        content: Text(l10n.moveConfirmation),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.move)),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Recuperiamo tutti gli atleti della squadra sorgente
    // Nota: Otteniamo lo stream e prendiamo il primo elemento (snapshot attuale)
    final allSourceAthletes = await db.getAthletesStream(_sourceTeam!.id).first;
    List<Athlete> athletesToMove = [];

    switch (_moveType) {
      case MoveType.single:
        if (_selectedAthlete == null) return;
        athletesToMove = allSourceAthletes.where((a) => a.id == _selectedAthlete!.id).toList();
        break;
      case MoveType.byYear:
        if (_selectedBirthYear == null) return;
        athletesToMove = allSourceAthletes.where((a) => a.birthYear == _selectedBirthYear).toList();
        break;
      case MoveType.all:
        athletesToMove = allSourceAthletes;
        break;
    }

    if (athletesToMove.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noAthletesToMove)));
      return;
    }

    // Eseguiamo lo spostamento per ogni atleta
    try {
      for (final athlete in athletesToMove) {
        await db.moveAthlete(athlete.id, _sourceTeam!.id, _destinationTeam!.id);
      }

      // Cancellazione opzionale del team sorgente.
      // SAFETY: eliminiamo solo se sono stati spostati TUTTI gli atleti,
      // perché deleteTeam è a cascata ed eliminerebbe anche gli atleti
      // rimasti nella squadra e i loro crono.
      if (widget.deleteSourceTeamOnSuccess && _moveType == MoveType.all) {
        await db.deleteTeam(_sourceTeam!.id);
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.teamAlsoDeleted(_sourceTeam!.name))));
        }
      } else {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.moveSuccess)));
        }
      }
      
      navigator.pop();
    } catch (e) {
      debugPrint('Error moving athletes: $e');
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorMovingAthletes)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final db = Provider.of<DatabaseRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moveAthletes),
      ),
      // StreamBuilder per le squadre
      body: StreamBuilder<List<Team>>(
        stream: _teamsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final teams = snapshot.data ?? [];
          
          // Filtriamo le squadre disponibili per la destinazione
          final destinationTeams = _sourceTeam == null
              ? teams
              : teams.where((t) => t.id != _sourceTeam!.id).toList();

          // Manteniamo la selezione corrente valida se possibile
          final currentSourceTeam = _sourceTeam != null && teams.any((t) => t.id == _sourceTeam!.id)
              ? teams.firstWhere((t) => t.id == _sourceTeam!.id)
              : null;
          final currentDestTeam = _destinationTeam != null && destinationTeams.any((t) => t.id == _destinationTeam!.id)
              ? destinationTeams.firstWhere((t) => t.id == _destinationTeam!.id)
              : null;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              DropdownButtonFormField<MoveType>(
                initialValue: _moveType,
                decoration: InputDecoration(labelText: l10n.moveType),
                items: [
                  DropdownMenuItem(value: MoveType.single, child: Text(l10n.moveSingleAthlete)),
                  DropdownMenuItem(value: MoveType.byYear, child: Text(l10n.moveAthletesByYear)),
                  DropdownMenuItem(value: MoveType.all, child: Text(l10n.moveAllAthletes)),
                ],
                // Se la schermata è stata aperta dal flusso "elimina squadra",
                // il tipo di spostamento resta bloccato su "tutti gli atleti"
                // per evitare eliminazioni a cascata parziali.
                onChanged: widget.deleteSourceTeamOnSuccess
                    ? null
                    : (value) => setState(() {
                          _moveType = value!;
                          _selectedAthlete = null;
                          _selectedBirthYear = null;
                          _refreshSourceAthletesStream();
                        }),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<Team>(
                initialValue: currentSourceTeam,
                decoration: InputDecoration(labelText: l10n.sourceTeam),
                items: teams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                // Sorgente bloccata nel flusso "elimina squadra": la squadra
                // da eliminare è quella scelta nelle impostazioni.
                onChanged: widget.deleteSourceTeamOnSuccess
                    ? null
                    : (value) => setState(() {
                  _sourceTeam = value;
                  // Reset destinazione se coincide con la nuova sorgente
                  if (_destinationTeam != null && _destinationTeam!.id == value!.id) {
                    _destinationTeam = null;
                  }
                  _selectedAthlete = null;
                  _selectedBirthYear = null;
                  _refreshSourceAthletesStream();
                }),
              ),
              DropdownButtonFormField<Team>(
                initialValue: currentDestTeam,
                decoration: InputDecoration(labelText: l10n.destinationTeam),
                items: destinationTeams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                onChanged: (value) => setState(() => _destinationTeam = value),
              ),
              const SizedBox(height: 16),

              if (_moveType == MoveType.single)
                _buildSingleAthleteSelector(context, l10n, db),
              
              if (_moveType == MoveType.byYear)
                _buildYearSelector(context, l10n, db),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.sync_alt),
                label: Text(l10n.move),
                onPressed: _performMove,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSingleAthleteSelector(BuildContext context, AppLocalizations l10n, DatabaseRepository db) {
    if (_sourceTeam == null) {
      return ListTile(
        title: Text(l10n.selectAthlete),
        subtitle: Text(l10n.selectSourceTeamFirst),
        enabled: false,
      );
    }

    return StreamBuilder<List<Athlete>>(
      stream: _sourceAthletesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final athletes = snapshot.data ?? [];

        if (athletes.isEmpty) {
          return ListTile(
            title: Text(l10n.selectAthlete),
            subtitle: Text(l10n.noAthletesInTeam),
            enabled: false,
          );
        }
        
        final currentSelectedAthlete = _selectedAthlete != null && athletes.any((a) => a.id == _selectedAthlete!.id)
            ? athletes.firstWhere((a) => a.id == _selectedAthlete!.id)
            : null;

        return DropdownButtonFormField<Athlete>(
          initialValue: currentSelectedAthlete,
          decoration: InputDecoration(labelText: l10n.selectAthlete),
          items: athletes.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
          onChanged: (value) => setState(() => _selectedAthlete = value),
        );
      },
    );
  }

  Widget _buildYearSelector(BuildContext context, AppLocalizations l10n, DatabaseRepository db) {
    if (_sourceTeam == null) {
      return ListTile(
        title: Text(l10n.selectBirthYear),
        //subtitle: const Text("Select a source team first"),
        subtitle: Text(l10n.selectSourceTeamFirst),
        enabled: false,
      );
    }

    return StreamBuilder<List<Athlete>>(
      stream: _sourceAthletesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final athletes = snapshot.data ?? [];

        // Estrai anni unici dagli atleti
        final uniqueYears = athletes
            .map((a) => a.birthYear)
            .toSet()
            .toList()
            ..sort();

        if (uniqueYears.isEmpty) {
          return ListTile(
            title: Text(l10n.selectBirthYear),
            subtitle: Text(l10n.noYearsInTeam),
            enabled: false,
          );
        }

        final currentSelectedYear = _selectedBirthYear != null && uniqueYears.contains(_selectedBirthYear)
            ? _selectedBirthYear
            : null;

        return DropdownButtonFormField<int>(
          initialValue: currentSelectedYear,
          decoration: InputDecoration(labelText: l10n.selectBirthYear),
          items: uniqueYears.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
          onChanged: (value) => setState(() => _selectedBirthYear = value),
        );
      },
    );
  }
}