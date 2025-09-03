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
              actions: [
                // Show a save button only when the timer is stopped but not at zero.
                if (!stopwatchService.isRunning && stopwatchService.elapsed > Duration.zero)
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () {
                      final finalTime = StopwatchService.formatDuration(stopwatchService.elapsed);
                      String notes = '';
                      for(int i = 0; i < stopwatchService.laps.length; i++) {
                        notes += 'Lap ${i+1}: ${StopwatchService.formatDuration(stopwatchService.laps[i])}\n';
                      }

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => AddEditChronoScreen(
                            chronoCollection: chronoCollection,
                            team: team,
                            // Pass a pre-filled Chrono object
                            // Pass the stopwatch data to pre-fill the form
                            initialTime: finalTime,
                            initialNotes: notes,
                          ),
                        ),
                      );
                    },
                  )
              ],
            ),
            body: Column(
              children: [
                _buildTimerDisplay(context, stopwatchService),
                _buildControls(context, stopwatchService, l10n),
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

  Widget _buildControls(BuildContext context, StopwatchService stopwatch, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: stopwatch.isRunning ? null : stopwatch.reset,
          child: Text(l10n.reset),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: stopwatch.isRunning ? stopwatch.stop : stopwatch.start,
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
          final lap = stopwatch.laps[index];
          return ListTile(
            leading: Text('${l10n.lap} ${index + 1}'),
            trailing: Text(StopwatchService.formatDuration(lap)),
          );
        },
      ),
    );
  }
}
