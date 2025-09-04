import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/stopwatch_service.dart';
import 'add_edit_chrono_screen.dart';
import '../models/team_model.dart';
import '../models/athlete_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StopwatchScreen extends StatelessWidget {
  final Team team;
  final Athlete athlete;
  final CollectionReference chronoCollection;

  const StopwatchScreen({
    super.key,
    required this.team,
    required this.athlete,
    required this.chronoCollection,
  });

  @override
  Widget build(BuildContext context) {
    // Provide the StopwatchService to this screen and its children.
    return ChangeNotifierProvider(
      create: (_) => StopwatchService(),
      child: Consumer<StopwatchService>(
        builder: (context, stopwatchService, child) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.stopwatch),
              // REMOVED: The save button in the AppBar is no longer needed.
            ),
            body: Column(
              children: [
                _buildTimerDisplay(context, stopwatchService),
                // UPDATED: Pass the necessary data down to the controls widget.
                _buildControls(context, stopwatchService, l10n, chronoCollection, team),
                _buildLapList(context, stopwatchService, l10n),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerDisplay(BuildContext context, StopwatchService stopwatch) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Text(
        StopwatchService.formatDuration(stopwatch.elapsed),
        style: const TextStyle(fontSize: 72, fontFamily: 'monospace'),
      ),
    );
  }

  // UPDATED: The controls widget now handles the navigation.
  Widget _buildControls(BuildContext context, StopwatchService stopwatch, AppLocalizations l10n, CollectionReference chronoCollection, Team team) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: stopwatch.isRunning ? null : stopwatch.reset,
          child: Text(l10n.reset),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          // UPDATED: The onPressed logic is now more complex.
          onPressed: () {
            if (stopwatch.isRunning) {
              // If the timer is running, stop it first.
              stopwatch.stop();

              // Then, immediately prepare the data and navigate.
              final finalTime = StopwatchService.formatDuration(stopwatch.elapsed);
              String notes = '';
              for (int i = 0; i < stopwatch.laps.length; i++) {
                notes += '${l10n.lap} ${i + 1}: ${StopwatchService.formatDuration(stopwatch.laps[i])}\n';
              }

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => AddEditChronoScreen(
                    chronoCollection: chronoCollection,
                    team: team,
                    initialTime: finalTime,
                    initialNotes: notes,
                  ),
                ),
              );
            } else {
              // If the timer is stopped, start it.
              stopwatch.start();
            }
          },
          child: Text(stopwatch.isRunning ? l10n.stop : l10n.start),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: stopwatch.isRunning ? stopwatch.lap : null,
          child: Text(l10n.lap),
        ),
      ],
    );
  }

  Widget _buildLapList(BuildContext context, StopwatchService stopwatch, AppLocalizations l10n) {
    return Expanded(
      child: ListView.builder(
        itemCount: stopwatch.laps.length,
        itemBuilder: (context, index) {          
          // Use reversed to show the latest lap at the top.
          final reversedIndex = stopwatch.laps.length - 1 - index;
          return ListTile(
            leading: Text('${l10n.lap} ${reversedIndex + 1}'),
            trailing: Text(StopwatchService.formatDuration(stopwatch.laps[reversedIndex])),
          );
        },
      ),
    );
  }
}
