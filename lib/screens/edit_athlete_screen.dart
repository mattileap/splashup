import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../models/athlete_model.dart';
import '../models/team_model.dart';
import 'package:collection/collection.dart';

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
    };
    for (var style in widget.athlete.preferredStyles) {
      if (_preferredStyles.containsKey(style)) {
        _preferredStyles[style] = true;
      }
    }

    final currentYear = DateTime.now().year;
    _birthYearOptions = List.generate(100, (index) => currentYear - index);

    _nameController.addListener(_markDirty);
    _notesController.addListener(_markDirty);
  }

  void _markDirty() {
    final selectedStyles = _preferredStyles.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    // UPDATED: Corrected the class name.
    final stylesEqual = const DeepCollectionEquality()
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
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context); // Store the navigator
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(l10n.discardChangesWarning),
        actions: <Widget>[
          TextButton(
            onPressed: () => navigator.pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => navigator.pop(true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }


  Future<void> _updateAthlete() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isDirty = false;
      });

      final selectedStyles = _preferredStyles.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      final athleteRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('teams')
          .doc(widget.team.id)
          .collection('athletes')
          .doc(widget.athlete.id);

      await athleteRef.update({
        'name': _nameController.text,
        'birthYear': _selectedBirthYear,
        'gender': _gender,
        'preferredStyles': selectedStyles,
        'isActive': _isActive,
        'notes': _notesController.text,
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
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
    };

    // UPDATED: Replaced deprecated WillPopScope with PopScope.
    return PopScope(
      canPop: !_isDirty,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _canPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
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
                    value!.isEmpty ? 'Please enter a name' : null,
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
                    value == null ? 'Please select a year' : null,
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