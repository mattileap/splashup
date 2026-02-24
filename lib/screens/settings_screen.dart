import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/team_model.dart';
import '../repositories/database_repository.dart';
import '../services/theme_service.dart';
import 'move_athletes_screen.dart';
// SYNC: NUOVO IMPORT per il Sync
// import '../services/cloud/cloud_sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _teamCount = 0;
  int _selectedMonths = 12;
  int _selectedYears = 2;
  
  // SYNC: Stato per gestire il caricamento del backup
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _fetchTeamCount();
  }

  Future<void> _fetchTeamCount() async {
    final db = context.read<DatabaseRepository>();
    // Otteniamo la lista attuale delle squadre per contarle
    final teams = await db.getTeamsStream().first;
    
    if (mounted) {
      setState(() {
        _teamCount = teams.length;
      });
    }
  }

 /*
  // --- SYNC LOGIC ---
  Future<void> _handleCloudBackup() async {
    setState(() => _isSyncing = true);
    final messenger = ScaffoldMessenger.of(context);
    // Recuperiamo il DB locale dal provider
    final db = context.read<DatabaseRepository>();
    // Creiamo il servizio di sync al volo
    final syncService = CloudSyncService(db);

    try {
      await syncService.backupToCloud(context);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Backup su Google Drive completato! (Cloud Firestore)')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Errore Backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }
  // ---------END SYNC LOGIC---------
*/

  Future<void> _runDeactivation() async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final db = context.read<DatabaseRepository>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deactivateInactiveAthletes),
        content: Text(l10n.deactivationConfirmation),
        actions: [
          TextButton(onPressed: () => navigator.pop(false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => navigator.pop(true), child: Text(l10n.run)),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      // Usiamo la funzione ottimizzata del repository locale
      final deactivatedCount = await db.deactivateInactiveAthletes(_selectedMonths);
      
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.deactivationComplete(deactivatedCount))));
      }
    } catch (e) {
      debugPrint('Error running deactivation: $e');
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text("Error during deactivation")));
      }
    }
  }

  Future<void> _runDeletion() async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final db = context.read<DatabaseRepository>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteInactiveAthletes),
        content: Text(l10n.deletionConfirmation),
        actions: [
          TextButton(onPressed: () => navigator.pop(false), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => navigator.pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      // Usiamo la funzione ottimizzata del repository locale
      final deletedCount = await db.deleteInactiveAthletes(_selectedYears);
      
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.deletionComplete(deletedCount))));
      }
    } catch (e) {
      debugPrint('Error running deletion: $e');
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text("Error during deletion")));
      }
    }
  }
  
  Future<void> _showDeleteTeamDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final db = context.read<DatabaseRepository>();

    final teamToDelete = await showDialog<Team>(
      context: context,
      builder: (context) {
        return StreamBuilder<List<Team>>(
          stream: db.getTeamsStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final teams = snapshot.data ?? [];
            return SimpleDialog(
              title: Text(l10n.selectTeamToDelete),
              children: teams.map((team) => SimpleDialogOption(
                onPressed: () => navigator.pop(team),
                child: Text(team.name),
              )).toList(),
            );
          },
        );
      },
    );

    if (teamToDelete == null || !mounted) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTeam),
        content: Text(l10n.deleteTeamWarning),
        actions: [
          TextButton(onPressed: () => navigator.pop('cancel'), child: Text(l10n.cancel)),
          TextButton(onPressed: () => navigator.pop('move'), child: Text(l10n.moveAthletesOption)),
          ElevatedButton(onPressed: () => navigator.pop('delete'), child: Text(l10n.deleteAnyway)),
        ],
      ),
    );

    if (choice == 'move') {
      if (!mounted) return;
      // Navighiamo alla schermata di spostamento, che è già configurata per gestire ID locali
      navigator.push(MaterialPageRoute(
        builder: (context) => MoveAthletesScreen(
          initialSourceTeam: teamToDelete,
          deleteSourceTeamOnSuccess: true,
        ),
      ));
    } else if (choice == 'delete') {
      // Step 3: Final confirmation with text input.
      if (!mounted) return;
      final confirmationController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteTeam),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.deleteTeamConfirmation),
              TextField(controller: confirmationController, decoration: const InputDecoration(labelText: 'DELETE')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => navigator.pop(false), child: Text(l10n.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (confirmationController.text == 'DELETE') {
                  navigator.pop(true);
                }
              },
              child: Text(l10n.delete),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          // Il metodo deleteTeam del repository è già cascading (elimina anche atleti e crono)
          await db.deleteTeam(teamToDelete.id);
          
          if (mounted) {
            // Usa il metodo l10n corretto con parametro
            messenger.showSnackBar(SnackBar(content: Text(l10n.teamDeleted(teamToDelete.name))));
            // Aggiorniamo il conteggio squadre
            _fetchTeamCount();
          }
        } catch (e) {
          debugPrint('Error deleting team: $e');
        }
      }
    }
  }

  // Trasformato da "Elimina Account" a "Elimina Tutti i Dati" (Factory Reset locale)
  Future<void> _showDeleteAllDataDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmationController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final db = context.read<DatabaseRepository>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.dataReset),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(l10n.deleteDataWarning), // "Questa azione è irreversibile..." va bene anche qui
                    const SizedBox(height: 20),
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: confirmationController,
                        decoration: InputDecoration(
                          labelText: l10n.typeToDelete,
                        ),
                        onChanged: (value) {
                          setState(() {
                            formKey.currentState!.validate();
                          });
                        },
                        validator: (value) {
                          if (value != 'DELETE') {
                            return '';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(l10n.cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: confirmationController,
                  builder: (context, value, child) {
                    return ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.disabled)) {
                              return Colors.grey;
                            }
                            return Colors.red.withAlpha(200); 
                          },
                        ),
                      ),
                      onPressed: value.text == 'DELETE'
                          ? () async {
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                // Eliminazione manuale di tutte le squadre (cascading su tutto il resto)
                                final teams = await db.getTeamsStream().first;
                                for(var team in teams) {
                                  await db.deleteTeam(team.id);
                                }
                                
                                if (!mounted) return;
                                navigator.popUntil((route) => route.isFirst);
                                messenger.showSnackBar(
                                  SnackBar(content: Text(l10n.dataReset)),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                navigator.pop();
                                messenger.showSnackBar(
                                  SnackBar(content: Text(l10n.dataResetFailed)),
                                );
                              }
                            }
                          : null,
                      child: Text(l10n.delete),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.appearance,
                style: Theme.of(context).textTheme.titleSmall),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l10n.theme),
            trailing: DropdownButton<ThemeMode>(
              value: themeService.themeMode,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.system),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.light),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.dark),
                ),
              ],
              onChanged: (ThemeMode? mode) {
                if (mode != null) {
                  themeService.setThemeMode(mode);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.dataManagement,
                style: Theme.of(context).textTheme.titleSmall),
          ),
          ListTile(
            enabled: _teamCount >= 2,
            leading: const Icon(Icons.sync_alt),
            title: Text(l10n.moveAthletes),
            subtitle: Text(
              _teamCount < 2 
              ? l10n.moveAthletesDeny
              : l10n.moveAthletesDescription
            ),
            onTap: _teamCount >= 2 ? () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MoveAthletesScreen()),
              );
            } : null,
          ),
          
          // ADDED: New ListTile for deleting a team.
          ListTile(
            enabled: _teamCount > 0,
            leading: const Icon(Icons.group_remove_outlined),
            title: Text(l10n.deleteTeam),
            subtitle: Text(l10n.deleteTeamDescription),
            onTap: _showDeleteTeamDialog,
          ),

          const Divider(),
          // ADDED: New Data Cleanup section
          ListTile(
            title: Text(l10n.dataCleanup,
                style: Theme.of(context).textTheme.titleSmall),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text(l10n.deactivateInactiveAthletes),
            subtitle: Text(l10n.deactivateInactiveDescription),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.deactivateAfter),
                DropdownButton<int>(
                  value: _selectedMonths,
                  items: [3, 6, 12, 18, 24].map((months) {
                    return DropdownMenuItem(
                      value: months,
                      child: Text('$months ${l10n.months}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMonths = value);
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: _runDeactivation,
                  child: Text(l10n.run),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // ADDED: New UI for the deletion feature.
          ListTile(
            leading: const Icon(Icons.person_remove_outlined),
            title: Text(l10n.deleteInactiveAthletes),
            subtitle: Text(l10n.deleteInactiveDescription),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.deleteAfter),
                DropdownButton<int>(
                  value: _selectedYears,
                  items: [1, 2, 3, 5].map((years) {
                    return DropdownMenuItem(
                      value: years,
                      child: Text('$years ${l10n.years}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedYears = value);
                    }
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withAlpha(200)),
                  onPressed: _runDeletion,
                  child: Text(l10n.run),
                ),
              ],
            ),
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            // Ho cambiato il titolo per riflettere che siamo offline
            title: Text(
              l10n.deleteData, // O usa una stringa l10n se vuoi aggiungerla
              style: const TextStyle(color: Colors.red),
            ),
            onTap: _showDeleteAllDataDialog,
          ),

 /*
          // --- SEZIONE TEST SYNC (DA NASCONDERE IN PRODUZIONE) ---
          if (true) ...[ // Cambia 'true' in 'false' per nascondere
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
              child: Text("CLOUD DEBUG AREA", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: _isSyncing 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.cloud_upload, color: Colors.blue),
              title: const Text("Backup su Google"),
              subtitle: const Text("Carica dati locali su Firebase"),
              enabled: !_isSyncing,
              onTap: _handleCloudBackup,
            ),
          ],
          // ---END SEZIONE TEST SYNC (DA NASCONDERE IN PRODUZIONE) ---
*/
        ],
      ),
    );
  }
}