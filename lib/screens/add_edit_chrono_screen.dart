import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/chrono_model.dart';

class AddEditChronoScreen extends StatefulWidget {
  final CollectionReference chronoCollection;
  final Chrono? existingChrono;

  const AddEditChronoScreen({
    super.key,
    required this.chronoCollection,
    this.existingChrono,
  });

  @override
  State<AddEditChronoScreen> createState() => _AddEditChronoScreenState();
}

class _AddEditChronoScreenState extends State<AddEditChronoScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  int _poolLength = 50;
  String _style = 'Freestyle';
  int? _distance;
  String _chronoType = 'Training'; // ADDED: State for the new dropdown
  final _finalTimeController = TextEditingController();
  final _notesController = TextEditingController();

  bool get isEditing => widget.existingChrono != null;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final chrono = widget.existingChrono!;
      _selectedDate = chrono.date;
      _poolLength = chrono.poolLength;
      _style = chrono.style;
      _distance = chrono.distance;
      _chronoType = chrono.type; // ADDED
      _finalTimeController.text = chrono.finalTime;
      _notesController.text = chrono.notes;
    } else {
      _selectedDate = DateTime.now();
      _distance = 50;
    }
    _finalTimeController.addListener(() => _markDirty(true));
    _notesController.addListener(() => _markDirty(true));
  }
  
  void _markDirty(bool isDirty) {
    if (_isDirty != isDirty) {
      setState(() {
        _isDirty = isDirty;
      });
    }
  }

  @override
  void dispose() {
    _finalTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<bool> _canPop() async {
    if (!_isDirty) return true;

    final l10n = AppLocalizations.of(context)!;
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(l10n.discardChangesWarning),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }


  Future<void> _saveChrono() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'date': Timestamp.fromDate(_selectedDate),
        'poolLength': _poolLength,
        'distance': _distance,
        'style': _style,
        'finalTime': _finalTimeController.text,
        'notes': _notesController.text,
        'type': _chronoType, // ADDED
      };

      if (isEditing) {
        await widget.chronoCollection.doc(widget.existingChrono!.id).update(data);
      } else {
        await widget.chronoCollection.add(data);
      }

      if (mounted) Navigator.of(context).pop();
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
    
    // ADDED: Map for chrono type translations
    final Map<String, String> typeDisplayNames = {
      'Training': l10n.training,
      'Race': l10n.race,
    };

    final List<int> distanceOptions = [50, 100, 200, 400, 800, 1500];
    if (_poolLength == 25) {
      distanceOptions.insert(0, 25);
    }
    if (!distanceOptions.contains(_distance)) {
      _distance = 50;
    }

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
          title: Text(isEditing ? l10n.editChrono : l10n.addChrono),
          actions: [
            IconButton(icon: const Icon(Icons.save), onPressed: _saveChrono),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              ListTile(
                title: Text(l10n.date),
                subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && pickedDate != _selectedDate) {
                    setState(() {
                      _selectedDate = pickedDate;
                      _markDirty(true);
                    });
                  }
                },
              ),
              DropdownButtonFormField<String>(
                // UPDATED: Replaced 'value' with 'initialValue'
                initialValue: _chronoType,
                decoration: InputDecoration(labelText: l10n.chronoType),
                items: typeDisplayNames.keys
                    .map((t) => DropdownMenuItem(value: t, child: Text(typeDisplayNames[t]!)))
                    .toList(),
                onChanged: (value) => setState(() {
                  _chronoType = value!;
                  _markDirty(true);
                }),
              ),
              DropdownButtonFormField<int>(
                // UPDATED: Replaced 'value' with 'initialValue'
                initialValue: _poolLength,
                decoration: InputDecoration(labelText: l10n.poolLength),
                items: [25, 50]
                    .map((len) => DropdownMenuItem(value: len, child: Text('$len m')))
                    .toList(),
                onChanged: (value) => setState(() {
                  _poolLength = value!;
                  _markDirty(true);
                }),
              ),
              DropdownButtonFormField<int>(
                // UPDATED: Replaced 'value' with 'initialValue'
                initialValue: _distance,
                decoration: InputDecoration(labelText: l10n.distance),
                items: distanceOptions
                    .map((dist) => DropdownMenuItem(value: dist, child: Text('$dist m')))
                    .toList(),
                onChanged: (value) => setState(() {
                  _distance = value!;
                  _markDirty(true);
                }),
                 validator: (v) => v == null ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                // UPDATED: Replaced 'value' with 'initialValue'
                initialValue: _style,
                decoration: InputDecoration(labelText: l10n.style),
                items: styleDisplayNames.keys
                    .map((s) => DropdownMenuItem(value: s, child: Text(styleDisplayNames[s]!)))
                    .toList(),
                onChanged: (value) => setState(() {
                  _style = value!;
                  _markDirty(true);
                }),
              ),
              TextFormField(
                controller: _finalTimeController,
                decoration: InputDecoration(
                    labelText: l10n.finalTime, hintText: l10n.finalTimeHint),
                validator: (v) => v!.isEmpty ? 'Required' : null,
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
