class Patient {
  final String mobileNumber;
  final String name;
  final int age;
  final String address;
  final DateTime dateOfBirth;
  final String gender;
  final String emergencyContact;
  final DateTime registeredAt;

  Patient({
    required this.mobileNumber,
    required this.name,
    required this.age,
    required this.address,
    required this.dateOfBirth,
    required this.gender,
    required this.emergencyContact,
    required this.registeredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'mobileNumber': mobileNumber,
      'name': name,
      'age': age,
      'address': address,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'emergencyContact': emergencyContact,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      mobileNumber: json['mobileNumber'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      address: json['address'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      gender: json['gender'] as String,
      emergencyContact: json['emergencyContact'] as String,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
    );
  }

  Patient copyWith({
    String? mobileNumber,
    String? name,
    int? age,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
    String? emergencyContact,
    DateTime? registeredAt,
  }) {
    return Patient(
      mobileNumber: mobileNumber ?? this.mobileNumber,
      name: name ?? this.name,
      age: age ?? this.age,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }
}
