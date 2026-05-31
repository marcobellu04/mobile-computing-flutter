import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String email;
  final String name;
  final String surname;
  final DateTime birthDate;
  final String gender;

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

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  factory User.publicProfile({
    required String name,
    required String surname,
    required String email,
  }) {
    return User(
      name: name,
      surname: surname,
      email: email,
      birthDate: DateTime(2000, 1, 1),
      gender: 'other',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'surname': surname,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    DateTime parsedBirthDate;

    if (map['birthDate'] is Timestamp) {
      parsedBirthDate = (map['birthDate'] as Timestamp).toDate();
    } else if (map['birthDate'] is String) {
      parsedBirthDate = DateTime.tryParse(map['birthDate']) ?? DateTime(2000, 1, 1);
    } else {
      parsedBirthDate = DateTime(2000, 1, 1);
    }

    return User(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      surname: map['surname'] ?? '',
      birthDate: parsedBirthDate,
      gender: map['gender'] ?? 'other',
    );
  }
}