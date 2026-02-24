import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/team_model.dart';
import '../models/athlete_model.dart';
import '../repositories/database_repository.dart';
import 'add_athlete_screen.dart';
import 'athlete_details_screen.dart'; 

class AthletesScreen extends StatefulWidget {
  final Team team;

  const AthletesScreen({super.key, required this.team});

  @override
  State<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends State<AthletesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
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

  void _showNotesDialog(BuildContext context, Athlete athlete) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.notesTitle),
          content: Text(
            athlete.notes.isNotEmpty ? athlete.notes : l10n.noNotesForAthlete,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.close),
              onPressed: () {
                Navigator.of(context).pop();
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
    
    // NUOVO: Recuperiamo il repository
    final db = Provider.of<DatabaseRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        // The title is the team name.
        title: Text(widget.team.name),
        // The search bar is in the 'bottom' property of the AppBar.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchAthletes,
                prefixIcon: const Icon(Icons.search),
                // Add a clear button to the search bar
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: Text(l10n.showInactive),
            value: _showInactive,
            onChanged: (bool value) {
              setState(() {
                _showInactive = value;
              });
            },
          ),
          const Divider(height: 1),
          Expanded(
            // NEW: Stream on List<Athlete>
            child: StreamBuilder<List<Athlete>>(
              stream: db.getAthletesStream(widget.team.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }
                
                final allAthletes = snapshot.data ?? [];

                if (allAthletes.isEmpty) {
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

                // Filtraggio in memoria (Sembast è veloce, va benissimo farlo qui)
                final filteredAthletes = allAthletes.where((athlete) {
                  final isStatusMatch = _showInactive || athlete.isActive;
                  final isSearchMatch = _searchQuery.isEmpty ||
                      athlete.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                  return isStatusMatch && isSearchMatch;
                }).toList();

                return ListView.builder(
                  itemCount: filteredAthletes.length,
                  itemBuilder: (context, index) {
                    final athlete = filteredAthletes[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(athlete.name.isNotEmpty 
                          ? athlete.name.substring(0, 1).toUpperCase() 
                          : '?'),
                      ),
                      title: Text(athlete.name),
                      subtitle: Text('${l10n.birthYear}: ${athlete.birthYear}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.note_alt_outlined),
                            onPressed: () => _showNotesDialog(context, athlete),
                          ),
                          if (!athlete.isActive)
                            const Icon(Icons.visibility_off_outlined,
                                color: Colors.grey),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AthleteDetailsScreen(
                              team: widget.team,
                              athlete: athlete,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              // Update: Pass teamId instead of CollectionReference
              builder: (context) => AddAthleteScreen(teamId: widget.team.id),
            ),
          );
        },
        tooltip: l10n.addAthlete,
        child: const Icon(Icons.add),
      ),
    );
  }
}