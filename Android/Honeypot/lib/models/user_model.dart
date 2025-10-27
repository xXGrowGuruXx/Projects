class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String role; // 'standard', 'premium', 'admin'
  final bool cloudBackupEnabled;
  final DateTime createdAt;
  final DateTime lastLogin;
  
  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = 'standard',
    this.cloudBackupEnabled = false,
    required this.createdAt,
    required this.lastLogin,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'cloudBackupEnabled': cloudBackupEnabled,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
    };
  }
  
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String?,
      role: map['role'] as String? ?? 'standard',
      cloudBackupEnabled: map['cloudBackupEnabled'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastLogin: DateTime.parse(map['lastLogin'] as String),
    );
  }
  
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? role,
    bool? cloudBackupEnabled,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      cloudBackupEnabled: cloudBackupEnabled ?? this.cloudBackupEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
