import 'package:cloud_firestore/cloud_firestore.dart';

class Athlete {
  final String id;
  final String name;
  final int birthYear;
  final String gender;
  final List<String> preferredStyles;
  final bool isActive;
  final String notes;

  Athlete({
    required this.id,
    required this.name,
    required this.birthYear,
    required this.gender,
    required this.preferredStyles,
    required this.isActive,
    required this.notes,
  });

  factory Athlete.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Athlete(
      id: doc.id,
      name: data['name'] ?? '',
      birthYear: data['birthYear'] ?? 2000,
      gender: data['gender'] ?? 'Male',
      // Ensure preferredStyles is always a List<String>
      preferredStyles: List<String>.from(data['preferredStyles'] ?? []),
      isActive: data['isActive'] ?? true,
      notes: data['notes'] ?? '',
    );
  }
}
