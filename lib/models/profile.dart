class Profile {
  final String id;
  final String name;
  final DateTime createdAt;

  const Profile({required this.id, required this.name, required this.createdAt});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}
