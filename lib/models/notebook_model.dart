/// Modello del taccuino allenatore: un albero di gruppi e righe con calcolo
/// automatico dei metri. Design completo in `docs/taccuino-design.md`.
///
/// I nodi sono mutabili di proposito: l'editor modifica l'albero sul posto.
/// Per duplicare un nodo: `NotebookNode.fromMap(node.toMap())`.
library;

/// Tipo di recupero: partenza ciclica (@1'30) o pausa fissa (Pausa 1').
enum RecoveryType { start, rest }

/// Recupero di un nodo. Solo metadata da mostrare, non entra nei metri.
class Recovery {
  RecoveryType type;
  String value;

  Recovery(this.type, this.value);

  Map<String, dynamic> toMap() => {'type': type.name, 'value': value};

  factory Recovery.fromMap(Map<String, dynamic> map) => Recovery(
        RecoveryType.values.byName(map['type'] as String),
        map['value'] as String,
      );
}

sealed class NotebookNode {
  /// Ripetizioni (riga) o moltiplicatore (gruppo). `null` = "Nx", deciso
  /// dall'atleta: il totale del nodo diventa indefinito.
  int? reps;
  Recovery? recovery;

  NotebookNode({this.reps = 1, this.recovery});

  /// Metri totali, `null` se il nodo o un suo discendente è "Nx".
  int? get meters;

  /// Metri dei soli rami definiti: i sottoalberi "Nx" vengono saltati.
  int get definedMeters {
    var sum = 0;
    _forEachDefinedLine(this, 1, (_, m) => sum += m);
    return sum;
  }

  /// Vero se una parte dell'albero è "Nx" e quindi [definedMeters] è parziale.
  bool get isPartial => meters == null;

  /// Metri per stile, sui soli rami definiti. Righe senza stile escluse.
  Map<String, int> get metersByStyle => _metersBy((l) => l.style);

  /// Metri per modalità, sui soli rami definiti. Righe senza modalità escluse.
  Map<String, int> get metersByMode => _metersBy((l) => l.mode);

  Map<String, int> _metersBy(String Function(NotebookLine) key) {
    final result = <String, int>{};
    _forEachDefinedLine(this, 1, (line, m) {
      // Predefiniti salvati come chiave (es. "freestyle"), personalizzati
      // come scritti: "Pull" e " pull " sono la stessa voce.
      final k = key(line).trim().toLowerCase();
      if (k.isNotEmpty) result[k] = (result[k] ?? 0) + m;
    });
    return result;
  }

  Map<String, dynamic> toMap();

  factory NotebookNode.fromMap(Map<String, dynamic> map) =>
      switch (map['kind']) {
        'group' => NotebookGroup.fromMap(map),
        'line' => NotebookLine.fromMap(map),
        final kind => throw FormatException('Nodo taccuino sconosciuto: $kind'),
      };

  Map<String, dynamic> _baseMap() => {
        'reps': reps,
        if (recovery != null) 'recovery': recovery!.toMap(),
      };
}

/// Gruppo: etichetta facoltativa, moltiplicatore e figli.
class NotebookGroup extends NotebookNode {
  String label;
  final List<NotebookNode> children;

  NotebookGroup({
    this.label = '',
    super.reps,
    super.recovery,
    List<NotebookNode>? children,
  }) : children = children ?? [];

  @override
  int? get meters {
    if (reps == null) return null;
    var sum = 0;
    for (final child in children) {
      final m = child.meters;
      if (m == null) return null;
      sum += m;
    }
    return reps! * sum;
  }

  @override
  Map<String, dynamic> toMap() => {
        'kind': 'group',
        ..._baseMap(),
        'label': label,
        'children': children.map((c) => c.toMap()).toList(),
      };

  factory NotebookGroup.fromMap(Map<String, dynamic> map) => NotebookGroup(
        label: map['label'] as String? ?? '',
        reps: map['reps'] as int?,
        recovery: _recoveryFromMap(map),
        children: (map['children'] as List? ?? [])
            .map((c) => NotebookNode.fromMap(Map<String, dynamic>.from(c as Map)))
            .toList(),
      );
}

/// Riga: ripetizioni × distanza, con stile, modalità e nota facoltative.
class NotebookLine extends NotebookNode {
  int distance;
  String style;
  String mode;
  String note;

  NotebookLine({
    required this.distance,
    this.style = '',
    this.mode = '',
    this.note = '',
    super.reps,
    super.recovery,
  });

  @override
  int? get meters => reps == null ? null : reps! * distance;

  @override
  Map<String, dynamic> toMap() => {
        'kind': 'line',
        ..._baseMap(),
        'distance': distance,
        'style': style,
        'mode': mode,
        'note': note,
      };

  factory NotebookLine.fromMap(Map<String, dynamic> map) => NotebookLine(
        distance: map['distance'] as int,
        style: map['style'] as String? ?? '',
        mode: map['mode'] as String? ?? '',
        note: map['note'] as String? ?? '',
        reps: map['reps'] as int?,
        recovery: _recoveryFromMap(map),
      );
}

/// Un taccuino: titolo e albero radice (gruppo senza etichetta, 1x).
class Notebook {
  /// Versione del formato, scritta fin da subito nelle mappe esportate.
  static const schemaVersion = 1;

  final String id;
  String title;
  final NotebookGroup root;

  Notebook({required this.id, required this.title, NotebookGroup? root})
      : root = root ?? NotebookGroup();

  Map<String, dynamic> toMap() => {
        'schemaVersion': schemaVersion,
        'title': title,
        'root': root.toMap(),
      };

  factory Notebook.fromMap(Map<String, dynamic> map, String id) => Notebook(
        id: id,
        title: map['title'] as String? ?? '',
        root: NotebookGroup.fromMap(Map<String, dynamic>.from(map['root'] as Map)),
      );
}

Recovery? _recoveryFromMap(Map<String, dynamic> map) => map['recovery'] == null
    ? null
    : Recovery.fromMap(Map<String, dynamic>.from(map['recovery'] as Map));

/// Visita le righe dei rami definiti con i metri già moltiplicati per tutti
/// i moltiplicatori degli antenati.
void _forEachDefinedLine(
  NotebookNode node,
  int factor,
  void Function(NotebookLine line, int meters) visit,
) {
  final reps = node.reps;
  if (reps == null) return;
  switch (node) {
    case NotebookLine():
      visit(node, factor * reps * node.distance);
    case NotebookGroup():
      for (final child in node.children) {
        _forEachDefinedLine(child, factor * reps, visit);
      }
  }
}
