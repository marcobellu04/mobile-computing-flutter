class User {
  final String email;
  final String name;
  final String surname;
  final DateTime birthDate;
  final String gender; // esempio: "male", "female", "other"

  User({
    required this.email,
    required this.name,
    required this.surname,
    required this.birthDate,
    required this.gender,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

   factory User.publicProfile({
    required String name,
    required String surname,
    required String email,
  }) {
    // Data fittizia, tanto non verrà mostrata
    final fakeDate = DateTime(2000, 1, 1);
    return User(
      name: name,
      surname: surname,
      email: email,
      birthDate: fakeDate,
      gender: 'other',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'surname': surname,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'],
      name: map['name'],
      surname: map['surname'],
      birthDate: DateTime.parse(map['birthDate']),
      gender: map['gender'],
    );
  }
}
