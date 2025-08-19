import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../models/team_model.dart';
import '../models/athlete_model.dart';
import 'add_athlete_screen.dart';

class AthletesScreen extends StatelessWidget {
  final Team team;

  const AthletesScreen({super.key, required this.team});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    // Create a reference to the 'athletes' sub-collection inside a specific team
    final athletesCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('teams')
        .doc(team.id)
        .collection('athletes');

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
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

          final athletes = snapshot.data!.docs
              .map((doc) => Athlete.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: athletes.length,
            itemBuilder: (context, index) {
              final athlete = athletes[index];
              return ListTile(
                leading: CircleAvatar(child: Text(athlete.name.substring(0, 1))),
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
