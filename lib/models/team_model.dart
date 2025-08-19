import 'package:cloud_firestore/cloud_firestore.dart';

// A data model for our Team object. This helps structure our data.
class Team {
  final String id;
  final String name;

  Team({required this.id, required this.name});

  // A factory constructor to create a Team from a Firestore document.
  factory Team.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      name: data['name'] ?? '',
    );
  }
}
