enum AppointmentStatus {
  pending,
  approved,
  rejected,
}

class Appointment {
  final String id;
  final String patientMobile;
  final String patientName;
  final String doctorName;
  final DateTime dateTime;
  final String time;
  final AppointmentStatus status;

  Appointment({
    required this.id,
    required this.patientMobile,
    required this.patientName,
    required this.doctorName,
    required this.dateTime,
    required this.time,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientMobile': patientMobile,
      'patientName': patientName,
      'doctorName': doctorName,
      'dateTime': dateTime.toIso8601String(),
      'time': time,
      'status': status.name,
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      patientMobile: json['patientMobile'] as String,
      patientName: json['patientName'] as String,
      doctorName: json['doctorName'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      time: json['time'] as String,
      status: AppointmentStatus.values.byName(json['status'] as String),
    );
  }

  Appointment copyWith({
    String? id,
    String? patientMobile,
    String? patientName,
    String? doctorName,
    DateTime? dateTime,
    String? time,
    AppointmentStatus? status,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientMobile: patientMobile ?? this.patientMobile,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
      dateTime: dateTime ?? this.dateTime,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}
