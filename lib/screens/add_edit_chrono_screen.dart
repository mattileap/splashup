import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/chrono_model.dart';
import '../models/team_model.dart';

/// Custom InputFormatter for sequential time input (MM:SS.cc)
/// Digits shift left automatically, decimal point is ignored
class TimeInputFormatter extends TextInputFormatter {
  String _currentValue = '00:00.00';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    final oldText = oldValue.text;

    // Handle complete deletion (when field is cleared)
    if (newText.isEmpty) {
      _currentValue = '00:00.00';
      return TextEditingValue(
        text: _currentValue,
        selection: TextSelection.collapsed(offset: _currentValue.length),
      );
    }

    // If user is deleting (backspace)
    if (newText.length < oldText.length) {
      _handleBackspace();
      return TextEditingValue(
        text: _currentValue,
        selection: TextSelection.collapsed(offset: _currentValue.length),
      );
    }

    // Get the last character typed
    final lastChar = newText[newText.length - 1];

    // Ignore decimal point (we format automatically)
    if (lastChar == '.') {
      return TextEditingValue(
        text: _currentValue,
        selection: TextSelection.collapsed(offset: _currentValue.length),
      );
    }

    // Handle digits 0-9 only
    if (RegExp(r'[0-9]').hasMatch(lastChar)) {
      _handleDigit(lastChar);
      return TextEditingValue(
        text: _currentValue,
        selection: TextSelection.collapsed(offset: _currentValue.length),
      );
    }

    // Ignore any other character
    return TextEditingValue(
      text: _currentValue,
      selection: TextSelection.collapsed(offset: _currentValue.length),
    );
  }

  void _handleDigit(String digit) {
    // Remove formatting characters to get just the 6 digits
    final numbers = _currentValue.replaceAll(RegExp(r'[:\.]'), '');
    
    // Shift left and add new digit at the end
    final shifted = '${numbers.substring(1)}$digit';
    
    // Reformat as MM:SS.cc
    _currentValue = '${shifted.substring(0, 2)}:${shifted.substring(2, 4)}.${shifted.substring(4, 6)}';
  }

  void _handleBackspace() {
    // Remove formatting characters
    final numbers = _currentValue.replaceAll(RegExp(r'[:\.]'), '');
    
    // Shift right and add 0 at the beginning
    final shifted = '0${numbers.substring(0, 5)}';
    
    // Reformat as MM:SS.cc
    _currentValue = '${shifted.substring(0, 2)}:${shifted.substring(2, 4)}.${shifted.substring(4, 6)}';
  }

  void reset() {
    _currentValue = '00:00.00';
  }
}

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
  final int? initialTimeMs;
  final List<ChronoSplit>? initialSplits;
  final String? initialNotes;

  const AddEditChronoScreen({
    super.key,
    required this.chronoCollection,
    required this.team,
    this.existingChrono,
    this.initialTime,
    this.initialTimeMs,
    this.initialSplits,
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
  late int _poolLength;
  String _style = 'Freestyle';
  int? _distance;
  String _chronoType = 'Training';
  final _finalTimeController = TextEditingController();
  final _notesController = TextEditingController();
  final _finalTimeFormatter = TimeInputFormatter();

  // NEW: Split management
  List<ChronoSplit> _splits = [];
  late List<TextEditingController> _splitControllers;
  late List<TimeInputFormatter> _splitFormatters;
  // NEW: Error tracking for each split field
  final Map<int, String?> _splitErrors = {};
  int? _finalTimeMs;
  // A getter to easily check if the screen is in editing mode.
  bool get isEditing => widget.existingChrono != null;
  // A flag to track if the user has made any changes to the form.
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _splitControllers = [];
    _splitFormatters = [];

    if (isEditing) {
      final chrono = widget.existingChrono!;
      _selectedDate = chrono.date;
      _poolLength = chrono.poolLength;
      _style = chrono.style;
      _distance = chrono.distance;
      _chronoType = chrono.type;
      _finalTimeController.text = chrono.finalTime;
      _notesController.text = chrono.notes;
      _finalTimeMs = chrono.finalTimeMs;
      // Carica i parziali esistenti
      _splits = List.from(chrono.splits);
    } else {
      // If adding a new chrono, set default values.
      _selectedDate = DateTime.now();
      // Use the team's default pool length when adding a new chrono.
      _poolLength = widget.team.poolLength;
      _distance = 100; // Un valore di default ragionevole
      // UPDATED: If initial data is passed from stopwatch, use it.
      _finalTimeController.text = widget.initialTime ?? '';
      _notesController.text = widget.initialNotes ?? '';
      _finalTimeMs = widget.initialTimeMs;

      // *** LOGICA DI CORREZIONE CHIAVE ***
      if (widget.initialSplits != null && widget.initialSplits!.isNotEmpty) {
        // Calcola la distanza in base ai parziali ricevuti
        _distance = widget.initialSplits!.length * _poolLength;
        _splits = _assignDistancesToSplits(widget.initialSplits!);
        _isDirty = true;
      } else {
        _distance = 100; // Valore di default solo se non ci sono parziali
      }

      if (widget.initialTime != null || (widget.initialNotes != null && widget.initialNotes!.isNotEmpty)) {
        _isDirty = true;
      }
    }
    
    // Genera la tabella e i controller immediatamente, senza aspettare il primo frame.
    // Questo assicura che `_splits` e `_splitControllers` siano sempre sincronizzati.
    _generateSplitsTemplate();
    
    _finalTimeController.addListener(_onFinalTimeChanged);
    _notesController.addListener(() => _markDirty(true));
  }
  
  // CORRETTO: Assegna le distanze corrette ai parziali in ingresso
  List<ChronoSplit> _assignDistancesToSplits(List<ChronoSplit> splits) {
    return splits.asMap().entries.map((entry) {
      final index = entry.key;
      final split = entry.value;
      return ChronoSplit(
        distance: _poolLength * (index + 1),
        time: split.time,
        splitTime: split.splitTime,
      );
    }).toList();
  }

  @override
  void dispose() {
    _finalTimeController.removeListener(_onFinalTimeChanged);
    _finalTimeController.dispose();
    _notesController.dispose();
    for (var controller in _splitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _markDirty(bool isDirty) {
    if (_isDirty != isDirty) {
      setState(() {
        _isDirty = isDirty;
      });
    }
  }

  Future<bool> _canPop() async {
    if (!_isDirty) return true; // Allow navigation if no changes were made.

    // Store context and l10n before async operations
    if (!mounted) return true;
    final currentContext = context;
    final l10n = AppLocalizations.of(currentContext)!;
    
    final shouldPop = await showDialog<bool>(
      context: currentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(l10n.discardChangesWarning),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.discard)),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  void _onFinalTimeChanged() {
    _finalTimeMs = Chrono.parseTimeToMilliseconds(_finalTimeController.text);
    _updateLastSplitWithFinalTime();
    _recalculateAndRefreshSplits();
    _markDirty(true);
  }

  void _updateLastSplitWithFinalTime() {
    if (_splits.isNotEmpty) {
      final lastSplit = _splits.last;
      _splits[_splits.length - 1] = ChronoSplit(
        distance: lastSplit.distance,
        time: _finalTimeMs,
      );
    }
  }
  
  void _generateSplitsTemplate() {
    for (var controller in _splitControllers) {
      controller.dispose();
    }
    _splitControllers.clear();
    _splitFormatters.clear();
    _splitErrors.clear();
    
    final newSplits = <ChronoSplit>[];
    if (_distance == null || _distance! <= 0) {
      setState(() {
        _splits = newSplits;
      });
      return;
    }

    final numberOfSplits = (_distance! / _poolLength).ceil();
    for (int i = 1; i <= numberOfSplits; i++) {
      final splitDistance = i * _poolLength;
      
      final existingSplit = _splits.firstWhere(
        (s) => s.distance == splitDistance,
        orElse: () => ChronoSplit(distance: splitDistance),
      );
      
      newSplits.add(existingSplit);
      
      final controller = TextEditingController(
        text: existingSplit.time != null ? Chrono.formatMillisecondsToTime(existingSplit.time!) : '',
      );
      _splitControllers.add(controller);
      _splitFormatters.add(TimeInputFormatter());
    }

    _splits = newSplits;
    _updateLastSplitWithFinalTime();
    _recalculateAndRefreshSplits();
  }

  void _updateSplitTime(int index, String value) {
    // Clear error for this field
    setState(() {
      _splitErrors[index] = null;
    });

    final timeMs = Chrono.parseTimeToMilliseconds(value);
    
    // Validate format
    if (value.isNotEmpty && timeMs == null) {
      setState(() {
        _splitErrors[index] = AppLocalizations.of(context)!.invalidTimeFormat;
      });
      return;
    }
    
    // Check if time is less than next valid split
    if (index < _splits.length - 1) {
      final nextValidSplit = _splits.skip(index + 1).firstWhere(
        (s) => s.time != null, 
        orElse: () => ChronoSplit(distance: 0, time: null)
      );
      if (nextValidSplit.time != null && timeMs != null && timeMs >= nextValidSplit.time!) {
        setState(() {
          _splitErrors[index] = AppLocalizations.of(context)!.splitTimeOrder(index + 2);
        });
        _splitControllers[index].text = _splits[index].time != null 
          ? Chrono.formatMillisecondsToTime(_splits[index].time!) 
          : '';
        return;
      }
    }
    
    _splits[index] = ChronoSplit(distance: _splits[index].distance, time: timeMs);
    _recalculateAndRefreshSplits();
    _markDirty(true);
  }

  /// **NUOVA FUNZIONE CENTRALIZZATA**
  /// Ricalcola tutti i tempi dei segmenti e i cumulativi, e aggiorna il tempo finale se necessario.
  void _recalculateAndRefreshSplits() {
    setState(() {
      for (int i = 0; i < _splits.length; i++) {
        final currentTime = _splits[i].time;
        
        // FIXED: Trova l'ultimo split VALIDO precedente (non solo quello immediatamente prima)
        int? previousTime;
        for (int j = i - 1; j >= 0; j--) {
          if (_splits[j].time != null) {
            previousTime = _splits[j].time;
            break;
          }
        }
        previousTime ??= 0; // Se non c'è nessun tempo precedente, usa 0
        
        int? segmentTime;
        if (currentTime != null) {
          segmentTime = currentTime - previousTime;
        }

        _splits[i] = ChronoSplit(
          distance: _splits[i].distance,
          time: currentTime,
          splitTime: segmentTime,
        );

        // OPTIMIZATION: Aggiorna solo se il testo è diverso
        if (_splitControllers.length > i) {
          final newText = currentTime != null ? Chrono.formatMillisecondsToTime(currentTime) : '';
          if (_splitControllers[i].text != newText) {
            _splitControllers[i].text = newText;
          }
        }
      }
    });
  }

  /// Shows error message
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Validates and saves the form data to Firestore.
  Future<void> _saveChrono() async {
    // First, check if the form is valid.
    if (_formKey.currentState!.validate()) {
      
      _finalTimeMs ??= Chrono.parseTimeToMilliseconds(_finalTimeController.text);
      
      final validSplits = _splits.where((s) => s.time != null && s.time! > 0).toList();
      if (validSplits.isNotEmpty) {
        // CORRETTO: Chiamata alla funzione di validazione ora esistente
        final validationError = Chrono.validateSplits(
          splits: validSplits,
          totalDistance: _distance ?? 100,
          poolLength: _poolLength,
          l10n: AppLocalizations.of(context)!,
        );
        if (validationError != null) {
          _showError(validationError);
          return;
        }
      }
      
      setState(() { _isDirty = false; });

      // Create a map of the data to be saved
      final data = {
        'date': Timestamp.fromDate(_selectedDate),
        'poolLength': _poolLength,
        'distance': _distance,
        'style': _style,
        'finalTime': _finalTimeController.text,
        'finalTimeMs': _finalTimeMs,
        'splits': validSplits.map((split) => split.toMap()).toList(),
        'notes': _notesController.text,
        'type': _chronoType,
      };

      // Close the screen first
      if (mounted) Navigator.of(context).pop();

      // Then perform Firestore operation (works offline with persistence)
      // If editing, update the existing document. Otherwise, add a new one.      
      try {
        if (isEditing) {
          await widget.chronoCollection.doc(widget.existingChrono!.id).update(data);
        } else {
          await widget.chronoCollection.add(data);
        }
      } catch (e) {
        debugPrint('Error saving chrono: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
    
    // *** LOGICA UNIFICATA E CORRETTA ***
    final Set<int> distanceSet = {50, 100, 200, 400, 800, 1500};
    if (_poolLength == 25) {
      distanceSet.add(25);
    }
    if (_distance != null) {
      distanceSet.add(_distance!);
    }
    final List<int> distanceOptions = distanceSet.toList()..sort();

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
          actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveChrono)],
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
                items: typeDisplayNames.keys.map((t) => DropdownMenuItem(value: t, child: Text(typeDisplayNames[t]!))).toList(),
                onChanged: (value) => setState(() {
                  _chronoType = value!;
                  _markDirty(true);
                }),
              ),
              // Dropdown for selecting the pool length.
              DropdownButtonFormField<int>(
                initialValue: _poolLength,
                decoration: InputDecoration(labelText: l10n.poolLength),
                items: [25, 50].map((len) => DropdownMenuItem(value: len, child: Text('$len m'))).toList(),
                onChanged: (value) {
                  setState(() {
                    _poolLength = value!;
                    _generateSplitsTemplate();
                    _markDirty(true);
                  });
                },
              ),
              // Dropdown for selecting the distance.
              DropdownButtonFormField<int>(
                initialValue: _distance,
                decoration: InputDecoration(labelText: l10n.distance),
                items: distanceOptions.map((dist) => DropdownMenuItem(value: dist, child: Text('$dist m'))).toList(),
                onChanged: (value) {
                  setState(() {
                    _distance = value;
                    _generateSplitsTemplate();
                    _markDirty(true);
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              // Dropdown for selecting the swimming style.
              DropdownButtonFormField<String>(
                initialValue: _style,
                decoration: InputDecoration(labelText: l10n.style),
                items: styleDisplayNames.keys.map((s) => DropdownMenuItem(value: s, child: Text(styleDisplayNames[s]!))).toList(),
                onChanged: (value) => setState(() {
                  _style = value!;
                  _markDirty(true);
                }),
              ),
              // Text field for the final time with sequential input
              TextFormField(
                controller: _finalTimeController,
                decoration: InputDecoration(
                  labelText: l10n.finalTime,
                  hintText: l10n.finalTimeHint,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _finalTimeController.clear();
                      _finalTimeFormatter.reset();
                      _markDirty(true);
                    },
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_finalTimeFormatter],
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              // NEW: Splits section
              const SizedBox(height: 24),
              Text(l10n.splits, style: theme.textTheme.titleMedium),
              if (_splits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    l10n.noSplitsYet,
                    style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                _buildSplitsTable(l10n, theme),
              const SizedBox(height: 16),
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

  /// NEW: Builds the editable splits table
  Widget _buildSplitsTable(AppLocalizations l10n, ThemeData theme) {
    // FIXED: Use theme colors for dark mode compatibility
    final headerColor = theme.colorScheme.surfaceContainerHighest;
    final borderColor = theme.dividerColor;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(3),
          },
          border: TableBorder.all(color: borderColor),
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerColor),
              children: [
                _buildTableCell(l10n.distance, isHeader: true, theme: theme),
                _buildTableCell(l10n.segment, isHeader: true, theme: theme),
                _buildTableCell(l10n.cumulative, isHeader: true, theme: theme),
              ],
            ),
            // Data rows
            ..._splits.asMap().entries.map((entry) {
              return _buildEditableSplitRow(entry.key, entry.value, l10n, theme);
            }),
          ],
        ),
      ),
    );
  }

  TableRow _buildEditableSplitRow(int index, ChronoSplit split, AppLocalizations l10n, ThemeData theme) {
    final bool isLastSplit = index == _splits.length - 1;
    final hasError = _splitErrors[index] != null;
    // FIXED: Use theme color for read-only field
    final readOnlyColor = theme.colorScheme.surfaceContainerHighest;
    
    return TableRow(
      key: ValueKey(split.distance),
      children: [
        _buildTableCell('${split.distance}m', theme: theme),
        _buildTableCell(split.formattedSplitTime, theme: theme),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _splitControllers[index],
                  readOnly: isLastSplit,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: isLastSplit ? [] : [_splitFormatters[index]],
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    hintText: l10n.splitTimeHint,
                    fillColor: isLastSplit ? readOnlyColor : null,
                    filled: isLastSplit,
                    // NEW: Visual error indicator
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                    errorText: hasError ? _splitErrors[index] : null,
                    errorStyle: const TextStyle(fontSize: 10),
                  ),
                  onChanged: (value) {
                    _updateSplitTime(index, value);
                  },
                ),
              ),
              // NEW: Clear button for non-last splits
              if (!isLastSplit)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    _splitControllers[index].clear();
                    _splitFormatters[index].reset();
                    _updateSplitTime(index, '');
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, required ThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 12,
          // FIXED: Use theme text color for proper contrast
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}