import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import '../l10n/app_localizations.dart';
import '../models/team_model.dart';
import '../services/auth_service.dart'; // Import AuthService

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final AuthService _authService = AuthService();

  // This function is now inside the state, making it easier to manage.
  Future<void> _addTeam(CollectionReference teamsCollection) async {
    // Prevent adding a team if the user is not logged in (redundant check)
    if (FirebaseAuth.instance.currentUser == null) return;

    final l10n = AppLocalizations.of(context)!;
    final TextEditingController teamNameController = TextEditingController();

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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.add),
              onPressed: () async {
                final newTeamName = teamNameController.text;
                if (newTeamName.isNotEmpty) {
                  // Use the passed-in collection reference
                  await teamsCollection.add({'name': newTeamName});
                }
                if (mounted) Navigator.of(context).pop();
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
    // Get the current user's ID inside the build method.
    // This ensures we always have the latest auth state.
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    // Handle the case where the user ID is somehow null
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text("Error: User not logged in. Please restart the app."),
        ),
      );
    }

    // Define the collection reference here, using the guaranteed non-null userId.
    final CollectionReference teamsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('teams');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myTeams),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              // The AuthWrapper will handle navigation
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Use the collection reference defined in the build method.
        stream: teamsCollection.snapshots(),
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
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.group_work, color: Colors.blue),
                  ),
                  title: Text(
                    team.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to the list of athletes for this team.
                    print("${team.name} tapped!");
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Pass the collection reference to the add function.
        onPressed: () => _addTeam(teamsCollection),
        tooltip: l10n.addTeam,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
