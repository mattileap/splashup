import 'package:cloud_firestore/cloud_firestore.dart';

class Chrono {
  final String id;
  final DateTime date;
  final int poolLength;
  final int distance;
  final String style;
  final String finalTime;
  final String notes;
  final String type; // ADDED: New field for chrono type

  Chrono({
    required this.id,
    required this.date,
    required this.poolLength,
    required this.distance,
    required this.style,
    required this.finalTime,
    required this.notes,
    required this.type, // ADDED
  });

  factory Chrono.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Chrono(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      poolLength: data['poolLength'] ?? 50,
      distance: data['distance'] ?? 100,
      style: data['style'] ?? 'Freestyle',
      finalTime: data['finalTime'] ?? '00:00.00',
      notes: data['notes'] ?? '',
      // ADDED: Default to 'Training' if not specified
      type: data['type'] ?? 'Training',
    );
  }
}
