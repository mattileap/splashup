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

  // Same setup as above, factored for the shorter tests below.
  Future<Notebook> pumpEditor(WidgetTester tester, NotebookGroup root) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final notebook = Notebook(id: 'n1', title: 'Tuesday', root: root);
    await tester.pumpWidget(Provider<DatabaseRepository>.value(
      value: _FakeRepo(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: NotebookEditorScreen(notebook: notebook),
      ),
    ));
    return notebook;
  }

  testWidgets('move a line into another group', (tester) async {
    final line = NotebookLine(distance: 25, style: 'freestyle');
    final target = NotebookGroup(label: 'Main set', reps: 4);
    await pumpEditor(tester, NotebookGroup(children: [
      NotebookGroup(label: 'Warm-up', children: [line]),
      target,
    ]));

    await tester.tap(find.text('25 Freestyle'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Move to…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to…'));
    await tester.pumpAndSettle();
    // Destinations: main level and "Main set", not the current group.
    expect(find.text('Main level'), findsOneWidget);
    expect(find.textContaining('Warm-up'), findsOneWidget); // Only the row behind the dialog
    await tester.tap(find.text('4x Main set · 0 m'));
    await tester.pumpAndSettle();

    expect(target.children.single, same(line));
    expect(find.text('100 m'), findsWidgets); // 4x 25, group row + total
  });

  testWidgets('a group cannot be moved past the depth limit', (tester) async {
    // Moving "Two levels" (2 group levels) into "Deep" (depth 2) would make 4.
    final moving = NotebookGroup(label: 'Two levels', children: [NotebookGroup()]);
    await pumpEditor(tester, NotebookGroup(children: [
      moving,
      NotebookGroup(label: 'A', children: [NotebookGroup(label: 'Deep')]),
    ]));

    await tester.tap(find.text('Two levels'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Move to…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to…'));
    await tester.pumpAndSettle();
    expect(find.text('A · 0 m'), findsOneWidget);
    expect(find.text('Deep · 0 m'), findsNothing);
  });

  testWidgets('sheet buttons stay above the Android navigation bar', (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 144); // 48 logical
    addTearDown(tester.view.resetPadding);
    await pumpEditor(tester, NotebookGroup());

    await tester.tap(find.text('Line'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Done'));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Done')).bottom, lessThanOrEqualTo(780 - 48));
  });
}
