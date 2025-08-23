import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'move_athletes_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ADDED: State to hold the number of teams.
  int _teamCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeamCount();
  }

  // ADDED: Function to get the number of teams from Firestore.
  Future<void> _fetchTeamCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
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

  // RESTORED: This function was missing from the previous version.
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
          // UPDATED: This ListTile is now disabled if there are fewer than 2 teams.
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
