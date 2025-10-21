import 'package:cloud_firestore/cloud_firestore.dart';
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

// ... La classe Chrono rimane quasi invariata, ma il costruttore e fromFirestore
// gestiranno la nuova lista di ChronoSplit. Le funzioni di validazione sono ancora valide.
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

  /// Crea un'istanza di Chrono da un documento Firestore.
  factory Chrono.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    // Parse splits if presents
    List<ChronoSplit> splitsList = [];
    if (data['splits'] != null) {
      final splitsData = data['splits'] as List;
      splitsList = splitsData.map((splitMap) {
        // Filtra solo gli split con un tempo valido per evitare errori
        if (splitMap['time'] != null) {
          return ChronoSplit.fromMap(splitMap as Map<String, dynamic>);
        }
        return null;
      }).whereType<ChronoSplit>().toList();
    }

    return Chrono(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      poolLength: data['poolLength'] ?? 50,
      distance: data['distance'] ?? 100,
      style: data['style'] ?? 'Freestyle',
      finalTime: data['finalTime'] ?? '00:00.00',
      finalTimeMs: data['finalTimeMs'] as int?,
      splits: splitsList,
      notes: data['notes'] ?? '',
      // Default to 'Training' if not specified
      type: data['type'] ?? 'Training',
    );
  }

  /// Converte l'oggetto Chrono in una mappa per l'archiviazione su Firestore.
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'poolLength': poolLength,
      'distance': distance,
      'style': style,
      'finalTime': finalTime,
      'finalTimeMs': finalTimeMs,
      // Salva solo i parziali che sono stati effettivamente riempiti
      'splits': splits.where((s) => s.time != null).map((split) => split.toMap()).toList(),
      'notes': notes,
      'type': type,
    };
  }

  /// Converte una stringa di tempo MM:SS.cc in millisecondi.
  static int? parseTimeToMilliseconds(String timeString) {
    if (timeString.isEmpty) return null;
    try {
      // Prova a parsare il formato completo MM:SS.cc
      final parts = timeString.split(RegExp(r'[:.]'));
      if (parts.length == 3) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        final centiseconds = int.parse(parts[2]);
        return (minutes * 60 * 1000) + (seconds * 1000) + (centiseconds * 10);
      }
      // Prova a parsare il formato SS.cc
      if (parts.length == 2) {
        final seconds = int.parse(parts[0]);
        final centiseconds = int.parse(parts[1]);
        return (seconds * 1000) + (centiseconds * 10);
      }
      // Prova a parsare solo i secondi
      final seconds = double.tryParse(timeString);
      if (seconds != null) {
        return (seconds * 1000).round();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Converte i millisecondi in una stringa di tempo MM:SS.cc.
  static String formatMillisecondsToTime(int milliseconds) {
    if (milliseconds < 0) return '00:00.00';
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final centiseconds = (duration.inMilliseconds.remainder(1000) / 10).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';
  }

  /// Valida la consistenza di una lista di intertempi.
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
      
      if (i > 0 && splits[i-1].time != null && split.time != null && split.time! <= splits[i-1].time!) {
        return l10n.splitTimeOrder(i + 1);
      }
    }
    
    return null;
  }
}