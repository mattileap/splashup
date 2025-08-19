import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../models/team_model.dart';
import '../models/athlete_model.dart';
import 'add_athlete_screen.dart';

// UPDATED: Converted to a StatefulWidget to handle search state.
class AthletesScreen extends StatefulWidget {
  final Team team;

  const AthletesScreen({super.key, required this.team});

  @override
  State<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends State<AthletesScreen> {
  // ADDED: State for managing the search query.
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Add a listener to the controller to update the state on text change.
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final athletesCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('teams')
        .doc(widget.team.id)
        .collection('athletes');

    return Scaffold(
      appBar: AppBar(
        // UPDATED: The title now includes a search bar.
        title: TextField(
          controller: _searchController,
          autofocus: false,
          decoration: InputDecoration(
            hintText: l10n.searchAthletes,
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          // ADDED: A button to clear the search field.
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: athletesCollection.orderBy('name').snapshots(),
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
                  const Icon(Icons.person_off_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noAthletesYet,
                    style: const TextStyle(fontSize: 22, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noAthletesHint,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final allAthletes = snapshot.data!.docs
              .map((doc) => Athlete.fromFirestore(doc))
              .toList();
          
          // ADDED: Filter the list of athletes based on the search query.
          final filteredAthletes = _searchQuery.isEmpty
              ? allAthletes
              : allAthletes
                  .where((athlete) => athlete.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
                  .toList();

          return ListView.builder(
            // Use the filtered list to build the UI.
            itemCount: filteredAthletes.length,
            itemBuilder: (context, index) {
              final athlete = filteredAthletes[index];
              return ListTile(
                leading:
                    CircleAvatar(child: Text(athlete.name.substring(0, 1))),
                title: Text(athlete.name),
                subtitle: Text('${l10n.birthYear}: ${athlete.birthYear}'),
                onTap: () {
                  // TODO: Navigate to athlete details/times screen
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AddAthleteScreen(athletesCollection: athletesCollection),
            ),
          );
        },
        tooltip: l10n.addAthlete,
        child: const Icon(Icons.add),
      ),
    );
  }
}
