import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/notebook_model.dart';
import '../repositories/database_repository.dart';
import 'notebook_editor_screen.dart';

/// Elenco dei taccuini allenatore, l'ultimo modificato in cima.
class NotebooksScreen extends StatefulWidget {
  const NotebooksScreen({super.key});

  @override
  State<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends State<NotebooksScreen> {
  late final Stream<List<Notebook>> _notebooksStream;
  List<Notebook> _notebooks = const [];

  @override
  void initState() {
    super.initState();
    _notebooksStream = context.read<DatabaseRepository>().getNotebooksStream();
  }

  void _open(Notebook notebook) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotebookEditorScreen(
          notebook: notebook,
          // Suggerimenti di stile/modalità presi da tutti i taccuini
          others: _notebooks,
        ),
      ),
    );
  }

  Future<void> _add() async {
    final title = await showNotebookTitleDialog(context);
    if (title == null || !mounted) return;
    final db = context.read<DatabaseRepository>();
    final notebook = Notebook(id: '', title: title);
    final id = await db.addNotebook(notebook);
    if (!mounted) return;
    _open(Notebook(id: id, title: title, root: notebook.root));
  }

  Future<void> _rename(Notebook notebook) async {
    final title = await showNotebookTitleDialog(context, initial: notebook.title);
    if (title == null || !mounted) return;
    notebook.title = title;
    await context.read<DatabaseRepository>().updateNotebook(notebook);
  }

  Future<void> _delete(Notebook notebook) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteNotebookTitle),
        content: Text(l10n.deleteNotebookMessage(notebook.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<DatabaseRepository>().deleteNotebook(notebook.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notebooks)),
      body: StreamBuilder<List<Notebook>>(
        stream: _notebooksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(l10n.errorWithDetails(snapshot.error.toString())));
          }
          _notebooks = snapshot.data ?? const [];

          if (_notebooks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(l10n.noNotebooksYet,
                        style: const TextStyle(fontSize: 22, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(l10n.noNotebooksHint,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 88), // Spazio per il FAB
            itemCount: _notebooks.length,
            itemBuilder: (context, index) {
              final notebook = _notebooks[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(notebook.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(formatNodeMeters(context, notebook.root)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) => action == 'rename'
                        ? _rename(notebook)
                        : _delete(notebook),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                      PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                    ],
                  ),
                  onTap: () => _open(notebook),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: l10n.addNotebook,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Dialog per il titolo di un taccuino (nuovo o da rinominare).
/// Restituisce il titolo ripulito, o null se annullato/vuoto.
Future<String?> showNotebookTitleDialog(BuildContext context, {String initial = ''}) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initial);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(initial.isEmpty ? l10n.addNotebook : l10n.rename),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.notebookTitle,
          hintText: l10n.notebookTitleHint,
        ),
        onSubmitted: (_) => Navigator.of(dialogContext).pop(true),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  final title = controller.text.trim();
  controller.dispose();
  return ok == true && title.isNotEmpty ? title : null;
}
