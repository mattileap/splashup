/// A data model for a Team object.
class Team {
  final String id;
  final String name;
  // Property to store the team's default pool length.
  final int poolLength;

  Team({
    required this.id,
    required this.name,
    required this.poolLength,
  });

  // NEW: Creates a Team from a simple Map (for Sembast)
  factory Team.fromMap(Map<String, dynamic> map, String docId) {
    return Team(
      id: docId, // ID is passed separately (DB key)
      name: map['name'] as String? ?? '',
      poolLength: map['poolLength'] as int? ?? 25,
    );
  }

  // NEW: Converts Team object in a Map for saving
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'poolLength': poolLength,
    };
  }
}