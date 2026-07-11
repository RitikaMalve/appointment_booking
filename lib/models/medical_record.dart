class MedicineItem {
  final String name;
  final String dosage; // e.g. "1-0-1" or "1-0-0"
  final String duration; // e.g. "5 days"
  final String instructions; // e.g. "After food"

  MedicineItem({
    required this.name,
    required this.dosage,
    required this.duration,
    required this.instructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'duration': duration,
      'instructions': instructions,
    };
  }

  factory MedicineItem.fromJson(Map<String, dynamic> json) {
    return MedicineItem(
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      duration: json['duration'] as String,
      instructions: json['instructions'] as String,
    );
  }
}

class MedicalRecord {
  final String id;
  final String patientId;
  final DateTime date;
  final String diagnosis;
  final String notes;
  final List<MedicineItem> medicines;
  final List<String> tests;

  MedicalRecord({
    required this.id,
    required this.patientId,
    required this.date,
    required this.diagnosis,
    required this.notes,
    required this.medicines,
    required this.tests,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'date': date.toIso8601String(),
      'diagnosis': diagnosis,
      'notes': notes,
      'medicines': medicines.map((m) => m.toJson()).toList(),
      'tests': tests,
    };
  }

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'] as String,
      patientId: json['patientId'] as String? ?? (json['patientMobile'] as String? ?? ''),
      date: DateTime.parse(json['date'] as String),
      diagnosis: json['diagnosis'] as String,
      notes: json['notes'] as String,
      medicines: (json['medicines'] as List<dynamic>)
          .map((m) => MedicineItem.fromJson(m as Map<String, dynamic>))
          .toList(),
      tests: (json['tests'] as List<dynamic>?)?.map((t) => t as String).toList() ?? [],
    );
  }
}
