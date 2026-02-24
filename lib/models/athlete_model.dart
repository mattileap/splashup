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

  // NEW: From Map (Sembast)
  factory Athlete.fromMap(Map<String, dynamic> map, String docId) {
    return Athlete(
      id: docId,
      name: map['name'] as String? ?? '',
      birthYear: map['birthYear'] as int? ?? 2000,
      gender: map['gender'] as String? ?? 'Male',
      // Gestione sicura della lista di stringhe
      preferredStyles: List<String>.from(map['preferredStyles'] ?? []),
      isActive: map['isActive'] as bool? ?? true,
      notes: map['notes'] as String? ?? '',
    );
  }

  // NEW: To Map (Saving)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'birthYear': birthYear,
      'gender': gender,
      'preferredStyles': preferredStyles,
      'isActive': isActive,
      'notes': notes,
    };
  }
}