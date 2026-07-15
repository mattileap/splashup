import '../l10n/app_localizations.dart';

/// Rappresenta un singolo intertempo (split) all'interno di un record cronometrico.
class ChronoSplit {
  final int distance;
  // I tempi possono essere null per rappresentare parziali vuoti.
  final int? time;
  final int? splitTime;

  ChronoSplit({
    required this.distance,
    this.time,
    this.splitTime,
  });

  /// Converte l'oggetto ChronoSplit in una mappa per l'archiviazione su Firestore.
  Map<String, dynamic> toMap() {
    return {
      'distance': distance,
      'time': time,
      'splitTime': splitTime,
    };
  }

  /// Crea un'istanza di ChronoSplit da una mappa.
  factory ChronoSplit.fromMap(Map<String, dynamic> map) {
    return ChronoSplit(
      distance: map['distance'] as int,
      time: map['time'] as int?,
      splitTime: map['splitTime'] as int?,
    );
  }

  /// Formatta il tempo totale fino a questo split in una stringa MM:SS.cc.
  // AGGIORNATO: Gestisce i valori null.
  String get formattedTime => time != null ? Chrono.formatMillisecondsToTime(time!) : '-';
  String get formattedSplitTime => splitTime != null ? Chrono.formatMillisecondsToTime(splitTime!) : '-';
}

class Chrono {
  final String id;
  final DateTime date;
  final int poolLength;
  final int distance;
  final String style;
  final String finalTime;
  final int? finalTimeMs;
  final List<ChronoSplit> splits;
  final String notes;
  final String type;

  Chrono({
    required this.id,
    required this.date,
    required this.poolLength,
    required this.distance,
    required this.style,
    required this.finalTime,
    this.finalTimeMs,
    this.splits = const [],
    required this.notes,
    required this.type,
  });

  // NEW: From Map (Sembast)
  factory Chrono.fromMap(Map<String, dynamic> map, String docId) {
    // Gestione data: Sembast salva come int (millisecondi)
    DateTime parsedDate;
    if (map['date'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(map['date'] as int);
    } else {
      parsedDate = DateTime.now(); // Fallback
    }

    List<ChronoSplit> splitsList = [];
    if (map['splits'] != null) {
      final splitsData = map['splits'] as List;
      splitsList = splitsData.map((splitMap) {
        if (splitMap is Map<String, dynamic> && splitMap['time'] != null) {
          return ChronoSplit.fromMap(splitMap);
        }
        return null;
      }).whereType<ChronoSplit>().toList();
    }

    return Chrono(
      id: docId,
      date: parsedDate,
      poolLength: map['poolLength'] as int? ?? 50,
      distance: map['distance'] as int? ?? 100,
      style: map['style'] as String? ?? 'Freestyle',
      finalTime: map['finalTime'] as String? ?? '00:00.00',
      finalTimeMs: map['finalTimeMs'] as int?,
      splits: splitsList,
      notes: map['notes'] as String? ?? '',
      // Default to 'Training' if not specified
      type: map['type'] as String? ?? 'Training',
    );
  }

  // Converte un Chrono in una Mappa (per Sembast)
  Map<String, dynamic> toMap() {
    return {
      // Salviamo la data come millisecondi per compatibilità universale offline
      'date': date.millisecondsSinceEpoch, 
      'poolLength': poolLength,
      'distance': distance,
      'style': style,
      'finalTime': finalTime,
      'finalTimeMs': finalTimeMs,
      // Saves only splits that were actually filled
      'splits':
          splits.where((s) => s.time != null).map((split) => split.toMap()).toList(),
      'notes': notes,
      'type': type,
    };
  }

  /// Tempo da mostrare in UI, sempre normalizzato: un valore inserito come
  /// "00:65.00" (65 secondi) viene mostrato come "01:05.00". Usa i
  /// millisecondi canonici quando disponibili, altrimenti prova a
  /// normalizzare la stringa; se non è interpretabile la restituisce com'è.
  String get displayTime {
    final ms = finalTimeMs ?? parseTimeToMilliseconds(finalTime);
    return ms != null ? formatMillisecondsToTime(ms) : finalTime;
  }

  static int? parseTimeToMilliseconds(String timeString) {
    if (timeString.isEmpty) return null;
    try {
      // Try to parse the full format MM:SS.cc
      final parts = timeString.split(RegExp(r'[:.]'));
      if (parts.length == 3) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        final centiseconds = int.parse(parts[2]);
        return (minutes * 60 * 1000) + (seconds * 1000) + (centiseconds * 10);
      }
      // Try to parse the format SS.cc
      if (parts.length == 2) {
        final seconds = int.parse(parts[0]);
        final centiseconds = int.parse(parts[1]);
        return (seconds * 1000) + (centiseconds * 10);
      }
      // Try to parse only seconds
      final seconds = double.tryParse(timeString);
      if (seconds != null) {
        return (seconds * 1000).round();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// It converts millisencods in a time String MM:SS.cc.
  static String formatMillisecondsToTime(int milliseconds) {
    if (milliseconds < 0) return '00:00.00';
    final duration = Duration(milliseconds: milliseconds);
    // Niente remainder(60): oltre i 60' i minuti continuano a crescere
    // (es. 65:00.00) invece di andare in wrap perdendo le ore.
    // parseTimeToMilliseconds gestisce già minuti > 59 in round-trip.
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final centiseconds = (duration.inMilliseconds.remainder(1000) / 10).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';
  }

  /// It validates the consistency of a list of splits.
  static String? validateSplits({
    required List<ChronoSplit> splits,
    required int totalDistance,
    required int poolLength,
    required AppLocalizations l10n,
  }) {
    if (splits.isEmpty) return null;
    for (int i = 0; i < splits.length; i++) {
      final split = splits[i];
      if (split.time != null && split.time! <= 0) {
        return l10n.splitTimeInvalidError(i + 1);
      }
      if (split.distance % poolLength != 0) {
        return l10n.splitDistanceMultiple(i + 1, poolLength);
      }
      if (split.distance > totalDistance) {
        return l10n.splitDistanceExceeds(i + 1, split.distance, totalDistance);
      }
      if (i > 0 && split.distance <= splits[i - 1].distance) {
        return l10n.splitDistanceOrder(i + 1);
      }
      if (i > 0 && splits[i - 1].time != null && split.time != null && split.time! <= splits[i - 1].time!) {
        return l10n.splitTimeOrder(i + 1);
      }
    }
    return null;
  }
}