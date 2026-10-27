import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:splashup/l10n/app_localizations.dart';
import 'package:splashup/models/notebook_model.dart';
import 'package:splashup/repositories/database_repository.dart';
import 'package:splashup/screens/notebook_editor_screen.dart';

// Only updateNotebook is used by the editor; anything else would throw.
class _FakeRepo implements DatabaseRepository {
  int saves = 0;

  @override
  Future<void> updateNotebook(Notebook notebook) async => saves++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('add a line and a nested group through the edit sheet', (tester) async {
    // Phone-sized screen (360x780 logical), like a real device.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    Future<void> tapInSheet(String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.pumpAndSettle();
      await tester.tap(find.text(text));
    }

    final repo = _FakeRepo();
    final notebook = Notebook(id: 'n1', title: 'Tuesday');
    await tester.pumpWidget(Provider<DatabaseRepository>.value(
      value: repo,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: NotebookEditorScreen(notebook: notebook),
      ),
    ));

    await tester.tap(find.text('Line'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Repetitions'), '4');
    await tester.enterText(find.widgetWithText(TextField, 'Distance (m)'), '100');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Backstroke'));
    await tester.pump();
    // Typing the translated label of a predefined value stores its key.
    await tester.enterText(find.widgetWithText(TextField, 'Mode'), 'kick');
    await tapInSheet('Done');
    await tester.pumpAndSettle();

    final line = notebook.root.children.single as NotebookLine;
    expect([line.reps, line.distance, line.style, line.mode], [4, 100, 'backstroke', 'kick']);
    expect(find.text('100 Backstroke · Kick'), findsOneWidget);
    expect(find.text('400 m'), findsWidgets); // row + session total

    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nx (athlete\'s choice)'));
    await tapInSheet('Done');
    await tester.pumpAndSettle();

    expect(notebook.root.children.last, isA<NotebookGroup>());
    expect(find.text('Line'), findsNWidgets(2)); // root + nested group
    expect(find.text('Partial: some parts are at the athlete\'s choice (Nx)'), findsOneWidget);
    expect(repo.saves, greaterThan(0));
  });
}
