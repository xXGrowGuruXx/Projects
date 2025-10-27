class Eintrag {
  final String id;
  final String volkId;
  final DateTime datum;
  final String? audioPath;
  final String text;
  final List<String> bildPaths;
  final List<String> videoPaths;
  final DateTime erstelltAm;
  final DateTime? bearbeitetAm;

  Eintrag({
    required this.id,
    required this.volkId,
    required this.datum,
    this.audioPath,
    required this.text,
    this.bildPaths = const [],
    this.videoPaths = const [],
    required this.erstelltAm,
    this.bearbeitetAm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'volk_id': volkId,
      'datum': datum.toIso8601String(),
      'audio_path': audioPath,
      'text': text,
      'bild_paths': bildPaths.join(','),
      'video_paths': videoPaths.join(','),
      'erstellt_am': erstelltAm.toIso8601String(),
      'bearbeitet_am': bearbeitetAm?.toIso8601String(),
    };
  }

  factory Eintrag.fromMap(Map<String, dynamic> map) {
    return Eintrag(
      id: map['id'],
      volkId: map['volk_id'],
      datum: DateTime.parse(map['datum']),
      audioPath: map['audio_path'],
      text: map['text'],
      bildPaths: map['bild_paths'] != null && (map['bild_paths'] as String).isNotEmpty
          ? (map['bild_paths'] as String).split(',')
          : [],
      videoPaths: map['video_paths'] != null && (map['video_paths'] as String).isNotEmpty
          ? (map['video_paths'] as String).split(',')
          : [],
      erstelltAm: DateTime.parse(map['erstellt_am']),
      bearbeitetAm: map['bearbeitet_am'] != null 
          ? DateTime.parse(map['bearbeitet_am']) 
          : null,
    );
  }

  Eintrag copyWith({
    String? text,
    List<String>? bildPaths,
    List<String>? videoPaths,
    DateTime? bearbeitetAm,
  }) {
    return Eintrag(
      id: id,
      volkId: volkId,
      datum: datum,
      audioPath: audioPath,
      text: text ?? this.text,
      bildPaths: bildPaths ?? this.bildPaths,
      videoPaths: videoPaths ?? this.videoPaths,
      erstelltAm: erstelltAm,
      bearbeitetAm: bearbeitetAm ?? this.bearbeitetAm,
    );
  }
}
