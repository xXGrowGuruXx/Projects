class Volk {
  final String id;
  final String name;
  final String? beschreibung;
  final DateTime erstelltAm;

  Volk({
    required this.id,
    required this.name,
    this.beschreibung,
    required this.erstelltAm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'beschreibung': beschreibung,
      'erstellt_am': erstelltAm.toIso8601String(),
    };
  }

  factory Volk.fromMap(Map<String, dynamic> map) {
    return Volk(
      id: map['id'],
      name: map['name'],
      beschreibung: map['beschreibung'],
      erstelltAm: DateTime.parse(map['erstellt_am']),
    );
  }
}
