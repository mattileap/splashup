import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _showDeleteConfirmationDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final confirmationController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
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
                            return ''; // Return empty string for no visible error
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
                                // UPDATED: Pop all screens until we get back to the root (AuthWrapper).
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
