import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/notebook_model.dart';
import '../repositories/database_repository.dart';
import 'notebooks_screen.dart';

/// Profondità massima dei gruppi (decisione UX, vedi docs/taccuino-design.md).
const maxGroupDepth = 3;

/// Stili predefiniti: chiave salvata -> etichetta nella lingua dell'app.
Map<String, String> styleLabels(AppLocalizations l10n) => {
      'freestyle': l10n.freestyle,
      'backstroke': l10n.backstroke,
      'breaststroke': l10n.breaststroke,
      'butterfly': l10n.butterfly,
      'medley': l10n.im,
    };

/// Modalità predefinite: chiave salvata -> etichetta nella lingua dell'app.
Map<String, String> modeLabels(AppLocalizations l10n) => {
      'kick': l10n.modeKick,
      'arms': l10n.modeArms,
      'full': l10n.modeFull,
      'pull_buoy': l10n.modePullBuoy,
      'kickboard': l10n.modeKickboard,
    };

String _display(Map<String, String> labels, String value) => labels[value] ?? value;

/// Testo scritto -> valore da salvare. Se corrisponde a un predefinito
/// (nella lingua corrente) si salva la chiave, così cambiando lingua le
/// statistiche non si spezzano in due voci.
String _toStored(Map<String, String> labels, String text) {
  final t = text.trim();
  final lower = t.toLowerCase();
  for (final e in labels.entries) {
    if (e.key == lower || e.value.toLowerCase() == lower) return e.key;
  }
  return t;
}

String formatMeters(BuildContext context, int meters) =>
    '${NumberFormat.decimalPattern(Localizations.localeOf(context).toString()).format(meters)} m';

/// Metri di un nodo; con un "Nx" dentro mostra i metri certi seguiti da "+".
String formatNodeMeters(BuildContext context, NotebookNode node) {
  final m = node.meters;
  return m != null
      ? formatMeters(context, m)
      : formatMeters(context, node.definedMeters).replaceFirst(' m', '+ m');
}

enum _SheetAction { delete, duplicate }

/// Editor ad albero di un taccuino. Ogni modifica viene salvata subito.
class NotebookEditorScreen extends StatefulWidget {
  final Notebook notebook;

  /// Tutti i taccuini, per suggerire gli stili/modalità già usati.
  final List<Notebook> others;

  const NotebookEditorScreen({super.key, required this.notebook, this.others = const []});

  @override
  State<NotebookEditorScreen> createState() => _NotebookEditorScreenState();
}

class _NotebookEditorScreenState extends State<NotebookEditorScreen> {
  final _collapsed = <NotebookGroup>{};
  final _keys = <NotebookNode, GlobalKey>{};

  NotebookGroup get _root => widget.notebook.root;

  void _changed() {
    setState(() {});
    context.read<DatabaseRepository>().updateNotebook(widget.notebook);
  }

  Future<void> _rename() async {
    final title = await showNotebookTitleDialog(context, initial: widget.notebook.title);
    if (title == null || !mounted) return;
    widget.notebook.title = title;
    _changed();
  }

  /// Valori personalizzati già usati in tutti i taccuini, per i suggerimenti.
  List<String> _used(String Function(NotebookLine) field, Map<String, String> labels) {
    final seen = <String>{...labels.keys};
    final result = <String>[];
    void walk(NotebookNode n) {
      switch (n) {
        case NotebookLine():
          final v = field(n);
          if (v.isNotEmpty && seen.add(v.toLowerCase())) result.add(v);
        case NotebookGroup():
          n.children.forEach(walk);
      }
    }

    walk(_root);
    for (final nb in widget.others) {
      walk(nb.root);
    }
    return result;
  }

  Future<void> _add(NotebookGroup parent, NotebookNode node) async {
    parent.children.add(node);
    _collapsed.remove(parent);
    _changed();
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) _edit(node, parent);
  }

  Future<void> _edit(NotebookNode node, NotebookGroup parent) async {
    final l10n = AppLocalizations.of(context)!;
    // La riga va in alto, così resta visibile sopra il pannello.
    final rowContext = _keys[node]?.currentContext;
    if (rowContext != null) {
      await Scrollable.ensureVisible(rowContext,
          alignment: 0.05, duration: const Duration(milliseconds: 200));
    }
    if (!mounted) return;

    final styles = styleLabels(l10n), modes = modeLabels(l10n);
    final action = await showModalBottomSheet<_SheetAction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _NodeSheet(
        node: node,
        styles: styles,
        modes: modes,
        usedStyles: _used((l) => l.style, styles),
        usedModes: _used((l) => l.mode, modes),
        onChanged: () => setState(() {}),
      ),
    );
    if (!mounted) return;

    final index = parent.children.indexOf(node);
    if (action == _SheetAction.duplicate) {
      parent.children.insert(index + 1, NotebookNode.fromMap(node.toMap()));
    } else if (action == _SheetAction.delete && await _confirmDelete(node)) {
      parent.children.remove(node);
    }
    _changed();
  }

  Future<bool> _confirmDelete(NotebookNode node) async {
    if (node is! NotebookGroup || node.children.isEmpty) return true;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteGroupTitle),
        content: Text(l10n.deleteGroupMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.delete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error))),
        ],
      ),
    );
    return ok == true;
  }

  // --- Costruzione dell'albero ---

  Widget _chip(String text, {bool strong = false}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: strong ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: strong ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              fontWeight: strong ? FontWeight.bold : null)),
    );
  }

  Widget? _repsChip(NotebookNode node) =>
      node.reps == 1 ? null : _chip(node.reps == null ? 'Nx' : '${node.reps}x', strong: true);

  Widget? _recoveryChip(NotebookNode node) {
    final r = node.recovery;
    if (r == null) return null;
    final l10n = AppLocalizations.of(context)!;
    return _chip(r.type == RecoveryType.start ? '@${r.value}' : l10n.restChip(r.value));
  }

  /// Riga toccabile: contenuto che va a capo (font grandi, OpenDyslexic) e
  /// metri allineati a destra.
  Widget _row(NotebookNode node, NotebookGroup parent,
      {Widget? leading, required List<Widget> content, Widget? below}) {
    return InkWell(
      key: _keys.putIfAbsent(node, GlobalKey.new),
      borderRadius: BorderRadius.circular(8),
      onTap: () => _edit(node, parent),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ?leading,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: content,
                  ),
                  ?below,
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(formatNodeMeters(context, node),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _line(NotebookLine line, NotebookGroup parent) {
    final l10n = AppLocalizations.of(context)!;
    final style = _display(styleLabels(l10n), line.style);
    final mode = _display(modeLabels(l10n), line.mode);
    return _row(
      line,
      parent,
      content: [
        ?_repsChip(line),
        Text([
          '${line.distance}',
          if (style.isNotEmpty) style,
          if (mode.isNotEmpty) '· $mode',
        ].join(' ')),
        ?_recoveryChip(line),
      ],
      below: line.note.isEmpty
          ? null
          : Text(line.note,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }

  Widget _group(NotebookGroup group, NotebookGroup parent, int depth) {
    final cs = Theme.of(context).colorScheme;
    // Livelli indicati dal colore, presi dal tema scelto dall'utente
    final color = [cs.primary, cs.tertiary, cs.secondary][(depth - 1) % 3];
    final collapsed = _collapsed.contains(group);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row(
            group,
            parent,
            leading: InkWell(
              onTap: () => setState(() => collapsed ? _collapsed.remove(group) : _collapsed.add(group)),
              child: Icon(collapsed ? Icons.chevron_right : Icons.expand_more),
            ),
            content: [
              ?_repsChip(group),
              if (group.label.isNotEmpty)
                Text(group.label, style: const TextStyle(fontWeight: FontWeight.bold)),
              ?_recoveryChip(group),
            ],
          ),
          if (!collapsed) _children(group, depth),
        ],
      ),
    );
  }

  /// Figli di un gruppo, riordinabili con pressione prolungata, più i
  /// pulsanti per aggiungere. [depth] è la profondità del gruppo (radice = 0).
  Widget _children(NotebookGroup group, int depth) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (oldIndex, newIndex) {
            group.children.insert(newIndex, group.children.removeAt(oldIndex));
            _changed();
          },
          children: [
            for (final (i, child) in group.children.indexed)
              ReorderableDelayedDragStartListener(
                key: ObjectKey(child),
                index: i,
                child: switch (child) {
                  NotebookLine() => _line(child, group),
                  NotebookGroup() => _group(child, group, depth + 1),
                },
              ),
          ],
        ),
        Wrap(
          spacing: 4,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addLine),
              onPressed: () => _add(group, NotebookLine(distance: 50)),
            ),
            if (depth < maxGroupDepth)
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addGroup),
                onPressed: () => _add(group, NotebookGroup()),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stats(String title, Map<String, int> values, Map<String, String> labels) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          for (final e in values.entries)
            _chip('${_display(labels, e.key)} ${formatMeters(context, e.value)}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.notebook.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.rename,
            onPressed: _rename,
          ),
        ],
      ),
      body: ListView(
        // Spazio in fondo: la riga in modifica deve poter salire sopra il pannello
        padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.sizeOf(context).height * 0.5),
        children: [
          if (_root.children.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(l10n.emptyNotebookHint,
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          _children(_root, 0),
          _stats(l10n.metersByStyle, _root.metersByStyle, styleLabels(l10n)),
          _stats(l10n.metersByMode, _root.metersByMode, modeLabels(l10n)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(l10n.sessionTotal, style: TextStyle(color: cs.onSurfaceVariant)),
                  const Spacer(),
                  Text(formatMeters(context, _root.definedMeters),
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              if (_root.isPartial)
                Text(l10n.partialTotal,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pannello di modifica di un nodo. Le modifiche valide vengono applicate
/// subito al nodo (i metri dietro si aggiornano mentre si scrive).
class _NodeSheet extends StatefulWidget {
  final NotebookNode node;
  final Map<String, String> styles, modes;
  final List<String> usedStyles, usedModes;
  final VoidCallback onChanged;

  const _NodeSheet({
    required this.node,
    required this.styles,
    required this.modes,
    required this.usedStyles,
    required this.usedModes,
    required this.onChanged,
  });

  @override
  State<_NodeSheet> createState() => _NodeSheetState();
}

class _NodeSheetState extends State<_NodeSheet> {
  late final NotebookNode node = widget.node;
  late final _label = TextEditingController(text: node is NotebookGroup ? (node as NotebookGroup).label : '');
  late final _reps = TextEditingController(text: '${node.reps ?? 1}');
  late final _distance = TextEditingController(text: node is NotebookLine ? '${(node as NotebookLine).distance}' : '');
  late final _style = TextEditingController(
      text: node is NotebookLine ? _display(widget.styles, (node as NotebookLine).style) : '');
  late final _mode = TextEditingController(
      text: node is NotebookLine ? _display(widget.modes, (node as NotebookLine).mode) : '');
  late final _note = TextEditingController(text: node is NotebookLine ? (node as NotebookLine).note : '');
  late final _recovery = TextEditingController(text: node.recovery?.value ?? '');
  late RecoveryType _recoveryType = node.recovery?.type ?? RecoveryType.start;
  late int _lastReps = node.reps ?? 1;
  String? _repsError, _distanceError;

  @override
  void dispose() {
    for (final c in [_label, _reps, _distance, _style, _mode, _note, _recovery]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Interi maggiori di zero: altrimenti errore sotto il campo e il valore
  /// nel nodo resta quello di prima.
  int? _positive(String text) {
    final v = int.tryParse(text.trim());
    return v != null && v > 0 ? v : null;
  }

  void _apply() {
    final l10n = AppLocalizations.of(context)!;
    final n = node;
    if (n.reps != null) {
      final reps = _positive(_reps.text);
      _repsError = reps == null ? l10n.invalidPositiveNumber : null;
      if (reps != null) n.reps = _lastReps = reps;
    }
    final value = _recovery.text.trim();
    n.recovery = value.isEmpty ? null : Recovery(_recoveryType, value);
    switch (n) {
      case NotebookGroup():
        n.label = _label.text.trim();
      case NotebookLine():
        final d = _positive(_distance.text);
        _distanceError = d == null ? l10n.invalidPositiveNumber : null;
        if (d != null) n.distance = d;
        n.style = _toStored(widget.styles, _style.text);
        n.mode = _toStored(widget.modes, _mode.text);
        n.note = _note.text.trim();
    }
    setState(() {});
    widget.onChanged();
  }

  Widget _suggestions(TextEditingController controller, Map<String, String> labels, List<String> used) {
    final current = _toStored(labels, controller.text);
    return Wrap(
      spacing: 6,
      runSpacing: 0,
      children: [
        for (final v in [...labels.keys, ...used])
          ChoiceChip(
            label: Text(_display(labels, v)),
            selected: current == v,
            visualDensity: VisualDensity.compact,
            onSelected: (_) {
              controller.text = _display(labels, v);
              _apply();
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final n = node;
    final isLine = n is NotebookLine;
    const gap = SizedBox(height: 12);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isLine) ...[
              TextField(
                controller: _label,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.groupLabel, hintText: l10n.groupLabelHint),
                onChanged: (_) => _apply(),
              ),
              gap,
            ],
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _reps,
                    enabled: n.reps != null,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isLine ? l10n.repetitions : l10n.multiplier,
                      errorText: _repsError,
                    ),
                    onChanged: (_) => _apply(),
                  ),
                ),
                FilterChip(
                  label: Text(l10n.openReps),
                  selected: n.reps == null,
                  onSelected: (open) {
                    n.reps = open ? null : _lastReps;
                    _reps.text = '$_lastReps';
                    _apply();
                  },
                ),
                if (isLine)
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _distance,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: l10n.distanceMeters, errorText: _distanceError),
                      onChanged: (_) => _apply(),
                    ),
                  ),
              ],
            ),
            if (isLine) ...[
              gap,
              TextField(
                controller: _style,
                decoration: InputDecoration(labelText: l10n.style),
                onChanged: (_) => _apply(),
              ),
              const SizedBox(height: 4),
              _suggestions(_style, widget.styles, widget.usedStyles),
              gap,
              TextField(
                controller: _mode,
                decoration: InputDecoration(labelText: l10n.modeLabel, hintText: l10n.optional),
                onChanged: (_) => _apply(),
              ),
              const SizedBox(height: 4),
              _suggestions(_mode, widget.modes, widget.usedModes),
              gap,
              TextField(
                controller: _note,
                decoration: InputDecoration(labelText: l10n.noteLabel, hintText: l10n.noteHint),
                onChanged: (_) => _apply(),
              ),
            ],
            gap,
            Text(l10n.recovery, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Partenza e pausa si escludono: un solo valore, cambia il tipo
                SegmentedButton<RecoveryType>(
                  segments: [
                    ButtonSegment(value: RecoveryType.start, label: Text(l10n.recoveryStart)),
                    ButtonSegment(value: RecoveryType.rest, label: Text(l10n.recoveryRest)),
                  ],
                  selected: {_recoveryType},
                  onSelectionChanged: (s) {
                    _recoveryType = s.single;
                    _apply();
                  },
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _recovery,
                    decoration: const InputDecoration(hintText: "1'30"),
                    onChanged: (_) => _apply(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(l10n.duplicate),
                  onPressed: () => Navigator.of(context).pop(_SheetAction.duplicate),
                ),
                TextButton.icon(
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  label: Text(l10n.delete,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onPressed: () => Navigator.of(context).pop(_SheetAction.delete),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.done),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
