import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../l10n/app_localizations.dart';
import '../models/athlete_model.dart';
import '../models/team_model.dart';
import '../repositories/database_repository.dart';

class EditAthleteScreen extends StatefulWidget {
  final Team team;
  final Athlete athlete;

  const EditAthleteScreen({
    super.key,
    required this.team,
    required this.athlete,
  });

  @override
  State<EditAthleteScreen> createState() => _EditAthleteScreenState();
}

class _EditAthleteScreenState extends State<EditAthleteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late int? _selectedBirthYear;
  late List<int> _birthYearOptions;
  late String _gender;
  late bool _isActive;
  late Map<String, bool> _preferredStyles;

  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.athlete.name);
    _notesController = TextEditingController(text: widget.athlete.notes);
    _selectedBirthYear = widget.athlete.birthYear;
    _gender = widget.athlete.gender;
    _isActive = widget.athlete.isActive;

    _preferredStyles = {
      'Freestyle': false,
      'Butterfly': false,
      'Backstroke': false,
      'Breaststroke': false,
      // 'IM' mancava: un atleta con IM tra gli stili preferiti non lo
      // vedeva in modifica e lo perdeva silenziosamente al salvataggio.
      'IM': false,
    };
    for (var style in widget.athlete.preferredStyles) {
      if (_preferredStyles.containsKey(style)) {
        _preferredStyles[style] = true;
      }
    }

    final currentYear = DateTime.now().year;
    _birthYearOptions = List.generate(100, (index) => currentYear - index);
    // Difensivo: se l'anno di nascita salvato è fuori dal range dei 100
    // anni generati, il DropdownButtonFormField andrebbe in assertion
    // ("value must be in items") crashando la schermata.
    if (_selectedBirthYear != null &&
        !_birthYearOptions.contains(_selectedBirthYear)) {
      _birthYearOptions.add(_selectedBirthYear!);
      _birthYearOptions.sort((a, b) => b.compareTo(a)); // Discendente
    }

    _nameController.addListener(_markDirty);
    _notesController.addListener(_markDirty);
  }

  void _markDirty() {
    final selectedStyles = _preferredStyles.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // Confronto NON ordinato: l'ordine degli stili salvati può differire
    // dall'ordine della mappa, e col confronto ordinato la schermata
    // risultava sempre "dirty" (warning di uscita anche senza modifiche).
    final stylesEqual = const DeepCollectionEquality.unordered()
        .equals(selectedStyles, widget.athlete.preferredStyles);

    final newDirtyState = _nameController.text != widget.athlete.name ||
        _notesController.text != widget.athlete.notes ||
        _selectedBirthYear != widget.athlete.birthYear ||
        _gender != widget.athlete.gender ||
        _isActive != widget.athlete.isActive ||
        !stylesEqual;

    if (newDirtyState != _isDirty) {
      setState(() {
        _isDirty = newDirtyState;
      });
    }
  }
  
  @override
  void dispose() {
    _nameController.removeListener(_markDirty);
    _notesController.removeListener(_markDirty);
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _canPop() async {
    if (!_isDirty) {
      return true;
    }
    
    // FIXED: Store context and l10n before async operations
    if (!mounted) return true;
    final currentContext = context;
    final l10n = AppLocalizations.of(currentContext)!;
    
    final shouldPop = await showDialog<bool>(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(l10n.discardChangesWarning),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  Future<void> _updateAthlete() async {
    // Capture l10n before any await so it is safe to use after async gaps.
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      // FIXED: Mark as not dirty and close screen immediately
      setState(() {
        _isDirty = false;
      });

      final selectedStyles = _preferredStyles.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // NUOVO: Creazione oggetto Athlete aggiornato
      final updatedAthlete = Athlete(
        id: widget.athlete.id,
        name: _nameController.text.trim(),
        birthYear: _selectedBirthYear ?? 2000,
        gender: _gender,
        preferredStyles: selectedStyles,
        isActive: _isActive,
        notes: _notesController.text.trim(),
      );

      final db = context.read<DatabaseRepository>();
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      // Prima salviamo, POI chiudiamo la schermata: col pop anticipato un
      // eventuale errore di scrittura veniva solo loggato e l'utente
      // credeva di aver salvato.
      try {
        await db.updateAthlete(widget.team.id, updatedAthlete);
      } catch (e) {
        debugPrint('Error updating athlete: $e');
        if (mounted) {
          setState(() => _isDirty = true); // Ripristina lo stato "modificato"
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.errorSavingAthlete(e.toString()))),
          );
        }
        return;
      }

      if (mounted) navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final Map<String, String> styleDisplayNames = {
      'Freestyle': l10n.freestyle,
      'Butterfly': l10n.butterfly,
      'Backstroke': l10n.backstroke,
      'Breaststroke': l10n.breaststroke,
      'IM': l10n.im,
    };

    return PopScope(
      canPop: !_isDirty,
      // FIXED: Replaced deprecated onPopInvoked with onPopInvokedWithResult
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // FIXED: Store navigator before async operation
        final navigator = Navigator.of(context);
        final shouldPop = await _canPop();
        
        // FIXED: Use stored navigator reference instead of context
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.editAthlete),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateAthlete,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.athleteName),
                validator: (value) =>
                    value!.isEmpty ? l10n.pleaseEnterName : null,
              ),
              DropdownButtonFormField<int>(
                // UPDATED: Replaced 'value' with 'initialValue'
                initialValue: _selectedBirthYear,
                decoration: InputDecoration(labelText: l10n.birthYear),
                items: _birthYearOptions.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBirthYear = value;
                    _markDirty();
                  });
                },
                validator: (value) =>
                    value == null ? l10n.pleaseSelectYear : null,
              ),
              DropdownButtonFormField<String>(
                // UPDATED: Replaced 'value' with 'initialValue'
                initialValue: _gender,
                decoration: InputDecoration(labelText: l10n.gender),
                items: [
                  DropdownMenuItem(value: 'Male', child: Text(l10n.male)),
                  DropdownMenuItem(value: 'Female', child: Text(l10n.female)),
                ],
                onChanged: (value) => setState(() {
                  _gender = value!;
                  _markDirty();
                }),
              ),
              const SizedBox(height: 16),
              Text(l10n.preferredStyles,
                  style: Theme.of(context).textTheme.titleMedium),
              ..._preferredStyles.keys.map((styleKey) {
                return CheckboxListTile(
                  title: Text(styleDisplayNames[styleKey]!),
                  value: _preferredStyles[styleKey],
                  onChanged: (value) =>
                      setState(() {
                        _preferredStyles[styleKey] = value!;
                        _markDirty();
                      }),
                );
              }),
              SwitchListTile(
                title: Text(l10n.status),
                subtitle: Text(_isActive ? l10n.active : l10n.inactive),
                value: _isActive,
                onChanged: (value) => setState(() {
                  _isActive = value;
                  _markDirty();
                }),
              ),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: l10n.notes),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}