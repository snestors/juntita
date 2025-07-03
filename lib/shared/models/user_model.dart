// 5. MODELO APP_USER ACTUALIZADO - lib/shared/models/app_user.dart
class AppUser {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isOnline;
  final String? contactName;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    required this.createdAt,
    this.isOnline = false,
    this.contactName,
  });

  String get displayName =>
      contactName?.isNotEmpty == true ? contactName! : name;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isOnline': isOnline,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isOnline: map['isOnline'] ?? false,
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? photoUrl,
    DateTime? createdAt,
    bool? isOnline,
    String? contactName,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isOnline: isOnline ?? this.isOnline,
      contactName: contactName ?? this.contactName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
