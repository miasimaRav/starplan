class User {
  final int id;
  final String name;
  final DateTime registrationDate;
  final DateTime? birthDate;
  final String? email;
  final int level;
  final int stars;

  User({
    required this.id,
    required this.name,
    required this.registrationDate,
    this.birthDate,
    this.email,
    this.level = 1,
    this.stars = 0,
  });

  factory User.fromMap(Map<String, dynamic> map) => User(
    id: map['id'] as int,
    name: map['name'] as String,
    registrationDate: DateTime.parse(map['registration_date'] as String),
    birthDate: map['birth_date'] != null
        ? DateTime.tryParse(map['birth_date'] as String)
        : null,
    email: map['email'] as String?,
    level: map['level'] as int? ?? 1,
    stars: map['stars'] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'registration_date': registrationDate,
    'birth_date': birthDate,
    'email': email,
    'level': level,
    'stars': stars,
  };

  User copyWith({
    String? name,
    DateTime? birthDate,
    String? email,
    int? level,
    int? stars,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      registrationDate: registrationDate,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      level: level ?? this.level,
      stars: stars ?? this.stars,
    );
  }
}
