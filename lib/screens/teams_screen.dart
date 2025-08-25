import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../models/team_model.dart';
import '../services/auth_service.dart';
import 'athletes_screen.dart';
import 'settings_screen.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final AuthService _authService = AuthService();

  Future<void> _editTeam(Team team) async {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController teamNameController =
        TextEditingController(text: team.name);

    // Store the Navigator for use after the await
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.editTeam),
          content: TextField(
            controller: teamNameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.teamName,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(l10n.save),
              onPressed: () async {
                final newTeamName = teamNameController.text;
                if (newTeamName.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .collection('teams')
                      .doc(team.id)
                      .update({'name': newTeamName});
                }
                // Use the stored navigator
                if (mounted) navigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  // UPDATED: This is the full, correct implementation of the _addTeam function.
  Future<void> _addTeam(CollectionReference teamsCollection) async {
    if (FirebaseAuth.instance.currentUser == null) return;

    final l10n = AppLocalizations.of(context)!;
    final TextEditingController teamNameController = TextEditingController();
    // Store the Navigator for use after the await
    final navigator = Navigator.of(context);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.addNewTeam),
          content: TextField(
            controller: teamNameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.teamName,
              hintText: l10n.teamNameHint,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor:
                    WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
                foregroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.onPrimary),
              ),
              child: Text(l10n.add),
              onPressed: () async {
                final newTeamName = teamNameController.text;
                if (newTeamName.isNotEmpty) {
                  await teamsCollection.add({'name': newTeamName});
                }
                // Use the stored navigator
                if (mounted) navigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text("Error: User not logged in. Please restart the app."),
        ),
      );
    }

    final CollectionReference teamsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('teams');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myTeams),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: teamsCollection.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_add_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noTeamsYet,
                    style: const TextStyle(fontSize: 22, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noTeamsHint,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final teams =
              snapshot.data!.docs.map((doc) => Team.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 16.0),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.group_work, color: Theme.of(context).colorScheme.onPrimary),
                  ),
                  title: Text(
                    team.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () => _editTeam(team),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AthletesScreen(team: team),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTeam(teamsCollection),
        tooltip: l10n.addTeam,
        child: const Icon(Icons.add),
      ),
    );
  }
}