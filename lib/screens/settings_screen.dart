import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../models/team_model.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'move_athletes_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _teamCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeamCount();
  }

  Future<void> _fetchTeamCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('teams')
        .count()
        .get();
    
    if (mounted) {
      setState(() {
        _teamCount = snapshot.count ?? 0;
        _isLoading = false;
      });
    }
  }

  // ADDED: New function to handle the entire team deletion flow.
  Future<void> _showDeleteTeamDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final teamsCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('teams');

    // Step 1: Select the team to delete.
    final teamToDelete = await showDialog<Team>(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: teamsCollection.orderBy('name').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final teams = snapshot.data!.docs.map((doc) => Team.fromFirestore(doc)).toList();
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

    // Step 2: Ask whether to move athletes or delete anyway.
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
      // UPDATED: Pass the new flag to the MoveAthletesScreen.
      navigator.push(MaterialPageRoute(
        builder: (context) => MoveAthletesScreen(
          initialSourceTeam: teamToDelete,
          deleteSourceTeamOnSuccess: true,
        ),
      ));
    } else if (choice == 'delete') {
      // Step 3: Final confirmation with text input.
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
        // Perform the deletion
        final teamRef = teamsCollection.doc(teamToDelete.id);
        final athletesSnapshot = await teamRef.collection('athletes').get();
        final batch = FirebaseFirestore.instance.batch();

        for (final athleteDoc in athletesSnapshot.docs) {
          final chronosSnapshot = await athleteDoc.reference.collection('chronos').get();
          for (final chronoDoc in chronosSnapshot.docs) {
            batch.delete(chronoDoc.reference);
          }
          batch.delete(athleteDoc.reference);
        }
        batch.delete(teamRef);
        await batch.commit();
        messenger.showSnackBar(SnackBar(content: Text('"${teamToDelete.name}" was deleted.')));
      }
    }
  }
  
  Future<void> _showDeleteConfirmationDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final confirmationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.deleteAccount),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text(l10n.deleteAccountWarning),
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
                            return Colors.red;
                          },
                        ),
                      ),
                      onPressed: value.text == 'DELETE'
                          ? () async {
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await authService.deleteAccountAndData();
                                navigator.popUntil((route) => route.isFirst);
                              } catch (e) {
                                navigator.pop();
                                messenger.showSnackBar(
                                  const SnackBar(content: Text("Failed to delete account. Please try again.")),
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
              ? "You need at least two teams to use this feature." 
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
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              l10n.deleteAccount,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: _showDeleteConfirmationDialog,
          ),
        ],
      ),
    );
  }
}
