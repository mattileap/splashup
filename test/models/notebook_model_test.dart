import 'package:flutter_test/flutter_test.dart';
import 'package:splashup/models/notebook_model.dart';

NotebookLine line(int? reps, int distance, [String style = '', String mode = '']) =>
    NotebookLine(reps: reps, distance: distance, style: style, mode: mode);

void main() {
  test('esempio del design doc: 4x [2x [2x50 ×3] Pausa 1\'] = 2400 m', () {
    final g = NotebookGroup(reps: 4, children: [
      NotebookGroup(
        reps: 2,
        recovery: Recovery(RecoveryType.rest, "1'"),
        children: [
          line(2, 50, 'freestyle', 'kick'),
          line(2, 50, 'freestyle', 'arms'),
          line(2, 50, 'freestyle', 'full'),
        ],
      ),
    ]);
    expect(g.meters, 2400);
    expect(g.definedMeters, 2400);
    expect(g.isPartial, isFalse);
  });

  test('alternanza braccia/gambe: 3x [3x [2x50, 2x [25, 25]]] = 1800 m, per stile e modalità', () {
    final g = NotebookGroup(reps: 3, children: [
      NotebookGroup(reps: 3, children: [
        line(2, 50, 'freestyle', 'kick'),
        NotebookGroup(reps: 2, children: [
          line(1, 25, 'freestyle', 'arms'),
          line(1, 25, 'Freestyle ', 'KICK'),
        ]),
      ]),
    ]);
    expect(g.meters, 1800);
    expect(g.metersByStyle, {'freestyle': 1800});
    expect(g.metersByMode, {'kick': 1350, 'arms': 450});
  });

  test('Nx: totale indefinito, definiti contati, stats senza i rami Nx', () {
    final root = NotebookGroup(children: [
      line(1, 400, 'freestyle'),
      NotebookGroup(reps: 4, children: [line(null, 50, 'backstroke'), line(1, 100, 'backstroke')]),
    ]);
    expect(root.meters, isNull);
    expect(root.isPartial, isTrue);
    expect(root.definedMeters, 800);
    expect(root.metersByStyle, {'freestyle': 400, 'backstroke': 400});
    expect(root.metersByMode, isEmpty);
  });

  test('gruppo vuoto vale 0 m', () {
    expect(NotebookGroup(reps: 3).meters, 0);
  });

  test('toMap/fromMap conserva albero, recupero e Nx', () {
    final nb = Notebook(id: 'n1', title: 'Martedì', root: NotebookGroup(children: [
      NotebookGroup(label: 'Serie', reps: 4, recovery: Recovery(RecoveryType.start, "1'30"), children: [
        NotebookLine(distance: 100, style: 'medley', note: 'sciolto', reps: null),
      ]),
    ]));
    final map = nb.toMap();
    expect(map['schemaVersion'], Notebook.schemaVersion);

    final back = Notebook.fromMap(map, 'n1');
    expect(back.toMap(), map);
    final serie = back.root.children.single as NotebookGroup;
    expect(serie.recovery!.type, RecoveryType.start);
    expect((serie.children.single as NotebookLine).reps, isNull);
  });
}
