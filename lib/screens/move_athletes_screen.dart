import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../models/team_model.dart';
import '../models/athlete_model.dart';

enum MoveType { single, byYear, all }

class MoveAthletesScreen extends StatefulWidget {
  final Team? initialSourceTeam;
  // ADDED: New parameter to control deletion after moving.
  final bool deleteSourceTeamOnSuccess;

  const MoveAthletesScreen({
    super.key,
    this.initialSourceTeam,
    this.deleteSourceTeamOnSuccess = false, // Defaults to false
  });

  @override
  State<MoveAthletesScreen> createState() => _MoveAthletesScreenState();
}

class _MoveAthletesScreenState extends State<MoveAthletesScreen> {
  MoveType _moveType = MoveType.single;
  Team? _sourceTeam;
  Team? _destinationTeam;
  Athlete? _selectedAthlete;
  int? _selectedBirthYear;

  @override
  void initState() {
    super.initState();
    if (widget.initialSourceTeam != null) {
      _sourceTeam = widget.initialSourceTeam;
      _moveType = MoveType.all;
    }
  }

  Future<void> _performMove() async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (_sourceTeam == null || _destinationTeam == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.selectTeamsFirst)));
      return;
    }
    if (_sourceTeam!.id == _destinationTeam!.id) {
      messenger.showSnackBar(const SnackBar(content: Text("Source and destination teams cannot be the same.")));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.moveAthletes),
        content: Text(l10n.moveConfirmation),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.move)),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final sourceTeamRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('teams').doc(_sourceTeam!.id);
    final destTeamRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('teams').doc(_destinationTeam!.id);

    QuerySnapshot athletesToMoveSnapshot;

    switch (_moveType) {
      case MoveType.single:
        if (_selectedAthlete == null) return;
        athletesToMoveSnapshot = await sourceTeamRef.collection('athletes').where(FieldPath.documentId, isEqualTo: _selectedAthlete!.id).get();
        break;
      case MoveType.byYear:
        if (_selectedBirthYear == null) return;
        athletesToMoveSnapshot = await sourceTeamRef.collection('athletes').where('birthYear', isEqualTo: _selectedBirthYear).get();
        break;
      case MoveType.all:
        athletesToMoveSnapshot = await sourceTeamRef.collection('athletes').get();
        break;
    }

    if (athletesToMoveSnapshot.docs.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text("No athletes found to move.")));
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    for (final athleteDoc in athletesToMoveSnapshot.docs) {
      final newAthleteRef = destTeamRef.collection('athletes').doc(athleteDoc.id);
      batch.set(newAthleteRef, athleteDoc.data());

      final chronosSnapshot = await athleteDoc.reference.collection('chronos').get();
      for (final chronoDoc in chronosSnapshot.docs) {
        batch.set(newAthleteRef.collection('chronos').doc(chronoDoc.id), chronoDoc.data());
        batch.delete(chronoDoc.reference);
      }
      batch.delete(athleteDoc.reference);
    }

    await batch.commit();

    // UPDATED: Conditionally delete the source team after the move.
    if (widget.deleteSourceTeamOnSuccess) {
      await sourceTeamRef.delete();
      messenger.showSnackBar(SnackBar(content: Text('"${_sourceTeam!.name}" was also deleted.')));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.moveSuccess)));
    }
    
    navigator.pop();
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final teamsCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('teams');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moveAthletes),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: teamsCollection.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final teams = snapshot.data!.docs.map((doc) => Team.fromFirestore(doc)).toList();
          
          final destinationTeams = _sourceTeam == null
              ? teams
              : teams.where((t) => t.id != _sourceTeam!.id).toList();

          final currentSourceTeam = _sourceTeam != null && teams.any((t) => t.id == _sourceTeam!.id)
              ? teams.firstWhere((t) => t.id == _sourceTeam!.id)
              : null;
          final currentDestTeam = _destinationTeam != null && destinationTeams.any((t) => t.id == _destinationTeam!.id)
              ? destinationTeams.firstWhere((t) => t.id == _destinationTeam!.id)
              : null;


          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              DropdownButtonFormField<MoveType>(
                initialValue: _moveType,
                decoration: const InputDecoration(labelText: 'Move Type'),
                items: [
                  DropdownMenuItem(value: MoveType.single, child: Text(l10n.moveSingleAthlete)),
                  DropdownMenuItem(value: MoveType.byYear, child: Text(l10n.moveAthletesByYear)),
                  DropdownMenuItem(value: MoveType.all, child: Text(l10n.moveAllAthletes)),
                ],
                onChanged: (value) => setState(() {
                  _moveType = value!;
                  _selectedAthlete = null;
                  _selectedBirthYear = null;
                }),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<Team>(
                initialValue: currentSourceTeam,
                decoration: InputDecoration(labelText: l10n.sourceTeam),
                items: teams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                onChanged: (value) => setState(() {
                  _sourceTeam = value;
                  if (_destinationTeam != null && _destinationTeam!.id == value!.id) {
                    _destinationTeam = null;
                  }
                  _selectedAthlete = null;
                  _selectedBirthYear = null;
                }),
              ),
              DropdownButtonFormField<Team>(
                initialValue: currentDestTeam,
                decoration: InputDecoration(labelText: l10n.destinationTeam),
                items: destinationTeams.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                onChanged: (value) => setState(() => _destinationTeam = value),
              ),
              const SizedBox(height: 16),

              if (_moveType == MoveType.single)
                _buildSingleAthleteSelector(context, l10n),
              
              if (_moveType == MoveType.byYear)
                _buildYearSelector(context, l10n),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.sync_alt),
                label: Text(l10n.move),
                onPressed: _performMove,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSingleAthleteSelector(BuildContext context, AppLocalizations l10n) {
    if (_sourceTeam == null) {
      return ListTile(
        title: Text(l10n.selectAthlete),
        subtitle: Text(l10n.selectSourceTeamFirst),
        enabled: false,
      );
    }

    final athletesCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('teams')
        .doc(_sourceTeam!.id)
        .collection('athletes');

    return StreamBuilder<QuerySnapshot>(
      stream: athletesCollection.orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return ListTile(
            title: Text(l10n.selectAthlete),
            subtitle: Text(l10n.noAthletesInTeam),
            enabled: false,
          );
        }
        final athletes = snapshot.data!.docs.map((doc) => Athlete.fromFirestore(doc)).toList();
        
        final currentSelectedAthlete = _selectedAthlete != null && athletes.any((a) => a.id == _selectedAthlete!.id)
            ? athletes.firstWhere((a) => a.id == _selectedAthlete!.id)
            : null;

        return DropdownButtonFormField<Athlete>(
          initialValue: currentSelectedAthlete,
          decoration: InputDecoration(labelText: l10n.selectAthlete),
          items: athletes.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
          onChanged: (value) => setState(() => _selectedAthlete = value),
        );
      },
    );
  }

  Widget _buildYearSelector(BuildContext context, AppLocalizations l10n) {
    if (_sourceTeam == null) {
      return ListTile(
        title: Text(l10n.selectBirthYear),
        //subtitle: const Text("Select a source team first"),
        subtitle: Text(l10n.selectSourceTeamFirst),
        enabled: false,
      );
    }

    final athletesCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('teams')
        .doc(_sourceTeam!.id)
        .collection('athletes');

    return StreamBuilder<QuerySnapshot>(
      stream: athletesCollection.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final uniqueYears = snapshot.data!.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['birthYear'] as int?)
            .where((year) => year != null)
            .toSet()
            .toList()
            ..sort();

        if (uniqueYears.isEmpty) {
          return ListTile(
            title: Text(l10n.selectBirthYear),
            subtitle: Text(l10n.noYearsInTeam),
            enabled: false,
          );
        }

        final currentSelectedYear = _selectedBirthYear != null && uniqueYears.contains(_selectedBirthYear)
            ? _selectedBirthYear
            : null;

        return DropdownButtonFormField<int>(
          initialValue: currentSelectedYear,
          decoration: InputDecoration(labelText: l10n.selectBirthYear),
          items: uniqueYears.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
          onChanged: (value) => setState(() => _selectedBirthYear = value),
        );
      },
    );
  }
}
