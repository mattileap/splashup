import 'package:cloud_firestore/cloud_firestore.dart';

/// A data model for a Team object.
class Team {
  final String id;
  final String name;
  // ADDED: New property to store the team's default pool length.
  final int poolLength;

  Team({
    required this.id, 
    required this.name,
    required this.poolLength, // ADDED
  });

  /// A factory constructor to create a Team from a Firestore document.
  factory Team.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      name: data['name'] ?? '',
      // ADDED: Read the pool length, defaulting to 25 if not set.
      poolLength: data['poolLength'] ?? 25,
    );
  }
}
