import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/stopwatch_service.dart';
import '../models/chrono_model.dart';
import 'add_edit_chrono_screen.dart';
import '../models/team_model.dart';
import '../models/athlete_model.dart';

class StopwatchScreen extends StatelessWidget {
  final Team team;
  final Athlete athlete;
  // Rimosso: final CollectionReference chronoCollection;

  const StopwatchScreen({
    super.key,
    required this.team,
    required this.athlete,
    // Rimosso: required this.chronoCollection,
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
            ),
            body: Column(
              children: [
                _buildTimerDisplay(context, stopwatchService),
                // Pass the necessary data down to the controls widget.
                _buildControls(context, stopwatchService, l10n, team, athlete),
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

  // The controls widget now handles the navigation.
  Widget _buildControls(BuildContext context, StopwatchService stopwatch, AppLocalizations l10n, Team team, Athlete athlete) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: stopwatch.isRunning ? null : stopwatch.reset,
          child: Text(l10n.reset),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () async {
            if (stopwatch.isRunning) {
              // If the timer is running, stop it first.
              stopwatch.stop();

              // Convert laps to ChronoSplit format
              // FIXED: Pass total elapsed time to calculate the final split
              final List<ChronoSplit> splits = _convertLapsToSplits(
                stopwatch.laps,
                stopwatch.elapsed, // Pass total time
              );

              // Calculate final time in milliseconds
              final finalTimeMs = stopwatch.elapsed.inMilliseconds;
              final finalTime = Chrono.formatMillisecondsToTime(finalTimeMs);

              // FIX UX: push (non pushReplacement) e attendiamo l'esito.
              // Con pushReplacement, annullando il salvataggio tempo e
              // vasche registrati andavano persi per sempre.
              final navigator = Navigator.of(context);
              final saved = await navigator.push<bool>(
                MaterialPageRoute(
                  builder: (context) => AddEditChronoScreen(
                    teamId: team.id,
                    athleteId: athlete.id,
                    team: team, // Manteniamo il team per la poolLength
                    initialTime: finalTime,
                    initialTimeMs: finalTimeMs,
                    initialSplits: splits,
                    initialNotes: '', // Passa una stringa vuota
                  ),
                ),
              );

              if (saved == true) {
                // Salvato: azzeriamo il cronometro e torniamo ai dettagli
                // atleta (stessa destinazione del vecchio flusso).
                stopwatch.reset();
                navigator.pop();
              }
              // Annullato: si resta sul cronometro con tempo e vasche
              // intatti, pronti per un nuovo tentativo di salvataggio.
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

  /// Converts lap durations to ChronoSplit format
  /// IMPORTANT: Stopwatch laps are cumulative times, not segment times!
  List<ChronoSplit> _convertLapsToSplits(List<Duration> laps, Duration totalTime) {
    if (laps.isEmpty) {
      return [
        ChronoSplit(
          distance: 0, // Will be set in add/edit screen
          time: totalTime.inMilliseconds,
          splitTime: totalTime.inMilliseconds,
        ),
      ];
    }

    final List<ChronoSplit> splits = [];

    // FIXED: Laps are cumulative times, we need to calculate segments
    for (int i = 0; i < laps.length; i++) {
      final cumulativeTimeMs = laps[i].inMilliseconds;
      // Calculate segment time by subtracting previous cumulative time
      final previousTimeMs = i > 0 ? laps[i - 1].inMilliseconds : 0;
      final segmentMs = cumulativeTimeMs - previousTimeMs;
      splits.add(ChronoSplit(
        distance: 0, // Distance will be set in the add/edit screen based on pool length
        time: cumulativeTimeMs,
        splitTime: segmentMs,
      ));
    }

    // Add the final split (from last lap to stop button)
    // This is the remaining time after the last lap
    final lastLapTimeMs = laps.isNotEmpty ? laps.last.inMilliseconds : 0;
    final finalSegmentMs = totalTime.inMilliseconds - lastLapTimeMs;
    if (finalSegmentMs > 10) { // Small threshold to avoid tiny final splits
      splits.add(ChronoSplit(
        distance: 0,
        time: totalTime.inMilliseconds,
        splitTime: finalSegmentMs,
      ));
    }
    return splits;
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