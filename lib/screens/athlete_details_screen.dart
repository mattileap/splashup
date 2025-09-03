import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/athlete_model.dart';
import '../models/chrono_model.dart';
import '../models/team_model.dart';
import 'add_edit_chrono_screen.dart';
import 'edit_athlete_screen.dart';
import 'stopwatch_screen.dart'; // Import the new stopwatch screen

/// Displays the details for a single athlete, including their personal information
/// and a filterable list of all their recorded times (chronos).
class AthleteDetailsScreen extends StatefulWidget {
  final Team team;
  final Athlete athlete;

  const AthleteDetailsScreen({
    super.key,
    required this.team,
    required this.athlete,
  });

  @override
  State<AthleteDetailsScreen> createState() => _AthleteDetailsScreenState();
}

class _AthleteDetailsScreenState extends State<AthleteDetailsScreen> {
  // State variables to hold the current filter selections.
  int? _selectedDistance;
  String? _selectedStyle;
  String? _selectedType;

  /// Parses a time string (e.g., "01:23.45") into a Duration object for easy comparison.
  Duration _parseTime(String time) {
    try {
      final parts = time.split(RegExp(r'[:.]'));
      if (parts.length != 3) return const Duration(days: 999); // Invalid format, sort last
      final minutes = int.parse(parts[0]);
      final seconds = int.parse(parts[1]);
      final hundredths = int.parse(parts[2]);
      return Duration(minutes: minutes, seconds: seconds, milliseconds: hundredths * 10);
    } catch (e) {
      return const Duration(days: 999); // Handle parsing errors gracefully
    }
  }

  /// Calculates and displays the athlete's personal best times in a dialog.
  void _showPersonalBestsDialog(BuildContext context, List<Chrono> allChronos, AppLocalizations l10n) {
    // A map to hold the best time for each unique event (e.g., "50-Freestyle").
    final personalBests = <String, Chrono>{};

    final styleDisplayNames = {
      'Freestyle': l10n.freestyle,
      'Butterfly': l10n.butterfly,
      'Backstroke': l10n.backstroke,
      'Breaststroke': l10n.breaststroke,
      'IM': l10n.im,
    };

    // Iterate through all chronos to find the best time for each event.
    for (final chrono in allChronos) {
      final key = '${chrono.distance}-${chrono.style}';
      final existingBest = personalBests[key];

      if (existingBest == null || _parseTime(chrono.finalTime) < _parseTime(existingBest.finalTime)) {
        personalBests[key] = chrono;
      }
    }

    // Sort the best times first by distance, then by style.
    final sortedBests = personalBests.values.toList()
      ..sort((a, b) {
        int distanceCompare = a.distance.compareTo(b.distance);
        if (distanceCompare != 0) return distanceCompare;
        return a.style.compareTo(b.style);
      });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.personalBestsTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: personalBests.isEmpty
                ? Text(l10n.noBestsYet)
                : ListView(
                    shrinkWrap: true,
                    children: sortedBests.map((chrono) {
                      final translatedStyle = styleDisplayNames[chrono.style] ?? chrono.style;
                      return ListTile(
                        title: Text('${chrono.distance}m $translatedStyle'),
                        subtitle: Text(chrono.finalTime),
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }

  /// Displays the athlete's notes in a simple dialog.
  void _showAthleteNotesDialog(BuildContext context, Athlete athlete, AppLocalizations l10n) {
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


  /// Handles the multi-step process for deleting an athlete.
  Future<void> _showDeleteAthleteDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);

    // Show a dialog with options: Cancel, Deactivate, or Delete.
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAthlete),
        content: Text(l10n.deleteAthleteWarning),
        actions: [
          TextButton(
            onPressed: () => navigator.pop('cancel'),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => navigator.pop('deactivate'),
            child: Text(l10n.deactivate),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => navigator.pop('delete'),
            child: Text(l10n.deleteAnyway),
          ),
        ],
      ),
    );

    if (!mounted || result == 'cancel' || result == null) return;

    final athleteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('teams')
        .doc(widget.team.id)
        .collection('athletes')
        .doc(widget.athlete.id);

    if (result == 'deactivate') {
      await athleteRef.update({'isActive': false});
      navigator.pop(); // Go back to the athletes list
    } else if (result == 'delete') {
      // Delete all sub-collections (chronos) first.
      final chronos = await athleteRef.collection('chronos').get();
      for (final doc in chronos.docs) {
        await doc.reference.delete();
      }
      // Then delete the athlete document itself.
      await athleteRef.delete();
      navigator.pop(); // Go back to the athletes list
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    final int age = DateTime.now().year - widget.athlete.birthYear;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    // Reference to the 'chronos' sub-collection for this specific athlete.
    final chronoCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('teams')
        .doc(widget.team.id)
        .collection('athletes')
        .doc(widget.athlete.id)
        .collection('chronos');

    return Scaffold(
      appBar: AppBar(
        // UPDATED: The title is now a Column to include the team name.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.athlete.name),
            Text(
              widget.team.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Button to show the athlete's notes.
          IconButton(
            icon: const Icon(Icons.note_alt_outlined),
            tooltip: l10n.notes,
            onPressed: () => _showAthleteNotesDialog(context, widget.athlete, l10n),
          ),
          // Button to show the athlete's personal bests.
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: l10n.personalBestsTitle,
            onPressed: () {
               chronoCollection.get().then((snapshot) {
                  if (!mounted) return;
                  final allChronos = snapshot.docs.map((doc) => Chrono.fromFirestore(doc)).toList();
                 _showPersonalBestsDialog(context, allChronos, l10n);
               });
            },
          ),
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: l10n.stopwatch,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StopwatchScreen(
                    team: widget.team,
                    athlete: widget.athlete,
                    chronoCollection: chronoCollection,
                  ),
                ),
              );
            },
          ),
          // Button to edit the athlete.
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditAthleteScreen(
                    team: widget.team,
                    athlete: widget.athlete,
                  ),
                ),
              );
            },
          ),
          // Button to delete the athlete.
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _showDeleteAthleteDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header card with athlete's personal information.
          _buildAthleteHeader(context, widget.athlete, age, l10n),
          // The rest of the screen is a scrollable list of chronos.
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chronoCollection.orderBy('date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(l10n.noTimesRecorded),
                  );
                }

                final allChronos = snapshot.data!.docs
                    .map((doc) => Chrono.fromFirestore(doc))
                    .toList();

                // Apply the filters selected by the user.
                final filteredChronos = allChronos.where((chrono) {
                  final distanceMatch = _selectedDistance == null || chrono.distance == _selectedDistance;
                  final styleMatch = _selectedStyle == null || chrono.style == _selectedStyle;
                  final typeMatch = _selectedType == null || chrono.type == _selectedType;
                  return distanceMatch && styleMatch && typeMatch;
                }).toList();

                // The main content area, including the filter bar and the list.
                return Column(
                  children: [
                    _buildFilterBar(context, allChronos, l10n),
                    if (filteredChronos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(l10n.noResultsFound),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredChronos.length,
                          itemBuilder: (context, index) {
                            return _buildChronoCard(context, filteredChronos[index], chronoCollection, l10n);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  AddEditChronoScreen(chronoCollection: chronoCollection, team: widget.team)));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Builds the non-scrolling header card with athlete details.
  Widget _buildAthleteHeader(BuildContext context, Athlete athlete, int age, AppLocalizations l10n) {
    final Map<String, String> styleDisplayNames = {
      'Freestyle': l10n.freestyle,
      'Butterfly': l10n.butterfly,
      'Backstroke': l10n.backstroke,
      'Breaststroke': l10n.breaststroke,
      'IM': l10n.im,
    };

    final Map<String, String> genderDisplayNames = {
      'Male': l10n.male,
      'Female': l10n.female,
    };
    final translatedGender = genderDisplayNames[athlete.gender] ?? athlete.gender;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(athlete.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('${l10n.age}: $age • $translatedGender'),
            const SizedBox(height: 8),
            Text(l10n.favoriteStyles, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8.0,
              children: athlete.preferredStyles
                  .map((styleKey) => Chip(label: Text(styleDisplayNames[styleKey] ?? styleKey)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the filter bar with dropdowns for distance, style, and type.
  Widget _buildFilterBar(BuildContext context, List<Chrono> allChronos, AppLocalizations l10n) {
    final uniqueDistances = allChronos.map((c) => c.distance).toSet().toList()..sort();
    final uniqueStyles = allChronos.map((c) => c.style).toSet().toList()..sort();
    final uniqueTypes = allChronos.map((c) => c.type).toSet().toList()..sort();

    final Map<String, String> styleDisplayNames = {
      'Freestyle': l10n.freestyle,
      'Butterfly': l10n.butterfly,
      'Backstroke': l10n.backstroke,
      'Breaststroke': l10n.breaststroke,
      'IM': l10n.im,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedDistance,
                  hint: Text(l10n.allDistances),
                  onChanged: (value) => setState(() => _selectedDistance = value),
                  items: [
                    DropdownMenuItem<int>(value: null, child: Text(l10n.allDistances)),
                    ...uniqueDistances.map((d) => DropdownMenuItem(value: d, child: Text("$d m"))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedStyle,
                  hint: Text(l10n.allStyles),
                  onChanged: (value) => setState(() => _selectedStyle = value),
                  items: [
                    DropdownMenuItem<String>(value: null, child: Text(l10n.allStyles)),
                    ...uniqueStyles.map((s) => DropdownMenuItem(value: s, child: Text(styleDisplayNames[s] ?? s))),
                  ],
                ),
              ),
            ],
          ),
          DropdownButton<String>(
            isExpanded: true,
            value: _selectedType,
            hint: Text(l10n.allTypes),
            onChanged: (value) => setState(() => _selectedType = value),
            items: [
              DropdownMenuItem<String>(value: null, child: Text(l10n.allTypes)),
              ...uniqueTypes.map((t) => DropdownMenuItem(value: t, child: Text(t == 'Race' ? l10n.race : l10n.training))),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a single card for a chrono entry in the list.
  Widget _buildChronoCard(BuildContext context, Chrono chrono, CollectionReference chronoCollection, AppLocalizations l10n) {
    final Map<String, String> typeDisplayNames = {
      'Training': l10n.training,
      'Race': l10n.race,
    };
    
    final Map<String, String> styleDisplayNames = {
      'Freestyle': l10n.freestyle,
      'Butterfly': l10n.butterfly,
      'Backstroke': l10n.backstroke,
      'Breaststroke': l10n.breaststroke,
      'IM': l10n.im,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(chrono.distance.toString()),
        ),
        title: Text('${styleDisplayNames[chrono.style] ?? chrono.style} - ${chrono.finalTime}'),
        subtitle: Text('${DateFormat.yMMMd().format(chrono.date)} • ${typeDisplayNames[chrono.type] ?? chrono.type}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: () {
                 Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddEditChronoScreen(
                        chronoCollection: chronoCollection,
                        existingChrono: chrono,
                        team: widget.team,
                    )));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.deleteChronoTitle),
                    content: Text(l10n.deleteConfirmation),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.delete)),
                    ],
                  ),
                );
                if (confirm == true) {
                  await chronoCollection.doc(chrono.id).delete();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
