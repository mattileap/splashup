import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';

class AddAthleteScreen extends StatefulWidget {
  final CollectionReference athletesCollection;

  const AddAthleteScreen({super.key, required this.athletesCollection});

  @override
  State<AddAthleteScreen> createState() => _AddAthleteScreenState();
}

class _AddAthleteScreenState extends State<AddAthleteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedBirthYear;
  late List<int> _birthYearOptions;

  String _gender = 'Male';
  bool _isActive = true;
  // The keys of this map are the values we save to Firestore. They are language-independent.
  final Map<String, bool> _preferredStyles = {
    'Freestyle': false,
    'Butterfly': false,
    'Backstroke': false,
    'Breaststroke': false,
  };

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _birthYearOptions =
        List.generate(100, (index) => currentYear - index);
    _selectedBirthYear = currentYear;
  }

  Future<void> _saveAthlete() async {
    if (_formKey.currentState!.validate()) {
      final selectedStyles = _preferredStyles.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      await widget.athletesCollection.add({
        'name': _nameController.text,
        'birthYear': _selectedBirthYear,
        'gender': _gender,
        'preferredStyles': selectedStyles,
        'isActive': _isActive,
        'notes': _notesController.text,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // UPDATED: Create a map to link the database keys to the translated display names.
    final Map<String, String> styleDisplayNames = {
      'Freestyle': l10n.freestyle,
      'Butterfly': l10n.butterfly,
      'Backstroke': l10n.backstroke,
      'Breaststroke': l10n.breaststroke,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addNewAthlete),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAthlete,
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
              value: _selectedBirthYear,
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
                });
              },
              validator: (value) =>
                  value == null ? 'Please select a year' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: InputDecoration(labelText: l10n.gender),
              items: [
                DropdownMenuItem(value: 'Male', child: Text(l10n.male)),
                DropdownMenuItem(value: 'Female', child: Text(l10n.female)),
              ],
              onChanged: (value) => setState(() => _gender = value!),
            ),
            const SizedBox(height: 16),
            Text(l10n.preferredStyles,
                style: Theme.of(context).textTheme.titleMedium),
            ..._preferredStyles.keys.map((styleKey) {
              return CheckboxListTile(
                // UPDATED: Use the translated name for the title.
                title: Text(styleDisplayNames[styleKey]!),
                value: _preferredStyles[styleKey],
                onChanged: (value) =>
                    setState(() => _preferredStyles[styleKey] = value!),
              );
            }),
            SwitchListTile(
              title: Text(l10n.status),
              subtitle: Text(_isActive ? l10n.active : l10n.inactive),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.notes),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
