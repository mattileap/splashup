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
  final _birthYearController = TextEditingController();
  final _notesController = TextEditingController();

  String _gender = 'Male';
  bool _isActive = true;
  final Map<String, bool> _preferredStyles = {
    'Freestyle': false,
    'Butterfly': false,
    'Backstroke': false,
    'Breaststroke': false,
  };

  Future<void> _saveAthlete() async {
    if (_formKey.currentState!.validate()) {
      final selectedStyles = _preferredStyles.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      await widget.athletesCollection.add({
        'name': _nameController.text,
        'birthYear': int.tryParse(_birthYearController.text) ?? 2000,
        'gender': _gender,
        'preferredStyles': selectedStyles,
        'isActive': _isActive,
        'notes': _notesController.text,
        'createdAt': Timestamp.now(), // Good practice to add a timestamp
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            TextFormField(
              controller: _birthYearController,
              decoration: InputDecoration(labelText: l10n.birthYear),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'Please enter a year';
                if (int.tryParse(value) == null) return 'Invalid year';
                return null;
              },
            ),
            DropdownButtonFormField<String>(
              // UPDATED: Replaced deprecated 'value' with 'initialValue'
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
            // UPDATED: Removed unnecessary .toList()
            ..._preferredStyles.keys.map((style) {
              return CheckboxListTile(
                title: Text(style), // Note: these are not translated yet for simplicity
                value: _preferredStyles[style],
                onChanged: (value) =>
                    setState(() => _preferredStyles[style] = value!),
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
