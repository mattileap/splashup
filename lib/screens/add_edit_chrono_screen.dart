import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/chrono_model.dart';
import '../models/team_model.dart'; // Import the Team model

/// A screen that provides a form for both adding a new chrono record and
/// editing an existing one.
class AddEditChronoScreen extends StatefulWidget {
  // The Firestore collection where the chrono will be saved or updated.
  final CollectionReference chronoCollection;
  // An optional existing chrono. If provided, the screen is in "edit" mode.
  final Chrono? existingChrono;
  // ADDED: The team is now required to get the default pool length.
  final Team team;
  // Parameters for receiving data from the stopwatch.
  final String? initialTime;
  final String? initialNotes;

  const AddEditChronoScreen({
    super.key,
    required this.chronoCollection,
    required this.team,
    this.existingChrono,
    this.initialTime,
    this.initialNotes,
  });

  @override
  State<AddEditChronoScreen> createState() => _AddEditChronoScreenState();
}

class _AddEditChronoScreenState extends State<AddEditChronoScreen> {
  // A global key for the form to handle validation.
  final _formKey = GlobalKey<FormState>();

  // State variables to hold the form data.
  late DateTime _selectedDate;
  late int _poolLength; // No longer initialized here
  String _style = 'Freestyle';
  int? _distance;
  String _chronoType = 'Training';
  final _finalTimeController = TextEditingController();
  final _notesController = TextEditingController();

  // A getter to easily check if the screen is in editing mode.
  bool get isEditing => widget.existingChrono != null;
  // A flag to track if the user has made any changes to the form.
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    // If we are editing, pre-fill the form with the existing chrono's data.
    if (isEditing) {
      final chrono = widget.existingChrono!;
      _selectedDate = chrono.date;
      _poolLength = chrono.poolLength;
      _style = chrono.style;
      _distance = chrono.distance;
      _chronoType = chrono.type;
      _finalTimeController.text = chrono.finalTime;
      _notesController.text = chrono.notes;
    } else {
      // If adding a new chrono, set default values.
      _selectedDate = DateTime.now();
      // UPDATED: Use the team's default pool length when adding a new chrono.
      _poolLength = widget.team.poolLength;
      _distance = 50;
      // UPDATED: If initial data is passed from stopwatch, use it.
      _finalTimeController.text = widget.initialTime ?? '';
      _notesController.text = widget.initialNotes ?? '';

      // UPDATED: If we received data from the stopwatch, consider the form "dirty"
      // so the user gets a warning if they try to go back without saving.
      if (widget.initialTime != null || (widget.initialNotes != null && widget.initialNotes!.isNotEmpty)) {
        _isDirty = true;
      }
    }
    // These listeners will set the dirty flag if the user makes any manual edits.
    _finalTimeController.addListener(() => _markDirty(true));
    _notesController.addListener(() => _markDirty(true));
  }
  
  /// Sets the `_isDirty` flag to true when the form is modified.
  void _markDirty(bool isDirty) {
    if (_isDirty != isDirty) {
      setState(() {
        _isDirty = isDirty;
      });
    }
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is removed from the tree.
    _finalTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Shows a confirmation dialog if there are unsaved changes.
  Future<bool> _canPop() async {
    if (!_isDirty) return true; // Allow navigation if no changes were made.

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
            onPressed: () => Navigator.of(dialogContext).pop(false), // Don't pop
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true), // Pop
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  /// Validates and saves the form data to Firestore.
  Future<void> _saveChrono() async {
    // First, check if the form is valid.
    if (_formKey.currentState!.validate()) {
      
      setState(() {
        _isDirty = false; // Mark as not dirty before popping to avoid double warning.
      });

      // Create a map of the data to be saved.
      final data = {
        'date': Timestamp.fromDate(_selectedDate),
        'poolLength': _poolLength,
        'distance': _distance,
        'style': _style,
        'finalTime': _finalTimeController.text,
        'notes': _notesController.text,
        'type': _chronoType,
      };

      // If editing, update the existing document. Otherwise, add a new one.
      if (isEditing) {
        await widget.chronoCollection.doc(widget.existingChrono!.id).update(data);
      } else {
        await widget.chronoCollection.add(data);
      }

      // Close the screen after saving.
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Maps for translating database keys into display names.
    final Map<String, String> styleDisplayNames = {
      'Freestyle': l10n.freestyle,
      'Butterfly': l10n.butterfly,
      'Backstroke': l10n.backstroke,
      'Breaststroke': l10n.breaststroke,
      'IM': l10n.im,
    };
    final Map<String, String> typeDisplayNames = {
      'Training': l10n.training,
      'Race': l10n.race,
    };

    // Dynamically generate the list of available distances.
    final List<int> distanceOptions = [50, 100, 200, 400, 800, 1500];
    if (_poolLength == 25) {
      distanceOptions.insert(0, 25);
    }
    // Reset distance selection if it becomes invalid after changing pool length.
    if (!distanceOptions.contains(_distance)) {
      _distance = 50;
    }

    // Use PopScope to intercept back navigation and check for unsaved changes.
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
              // A ListTile that acts as a button to open the date picker.
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
              // Dropdown for selecting the chrono type (Race or Training).
              DropdownButtonFormField<String>(
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
              // Dropdown for selecting the pool length.
              DropdownButtonFormField<int>(
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
              // Dropdown for selecting the distance.
              DropdownButtonFormField<int>(
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
              // Dropdown for selecting the swimming style.
              DropdownButtonFormField<String>(
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
              // Text field for the final time.
              TextFormField(
                controller: _finalTimeController,
                decoration: InputDecoration(
                    labelText: l10n.finalTime, hintText: l10n.finalTimeHint),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              // Text field for notes.
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