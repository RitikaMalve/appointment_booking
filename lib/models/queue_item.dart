enum QueueStatus {
  waiting,
  serving,
  done,
  skipped,
}

class QueueItem {
  final String id;
  final String patientMobile;
  final int queueNumber;
  final DateTime entryTime;
  final QueueStatus status;
  final bool isFeesPaid;

  QueueItem({
    required this.id,
    required this.patientMobile,
    required this.queueNumber,
    required this.entryTime,
    required this.status,
    required this.isFeesPaid,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientMobile': patientMobile,
      'queueNumber': queueNumber,
      'entryTime': entryTime.toIso8601String(),
      'status': status.name,
      'isFeesPaid': isFeesPaid,
    };
  }

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      id: json['id'] as String,
      patientMobile: json['patientMobile'] as String,
      queueNumber: json['queueNumber'] as int,
      entryTime: DateTime.parse(json['entryTime'] as String),
      status: QueueStatus.values.byName(json['status'] as String),
      isFeesPaid: json['isFeesPaid'] as bool,
    );
  }

  QueueItem copyWith({
    String? id,
    String? patientMobile,
    int? queueNumber,
    DateTime? entryTime,
    QueueStatus? status,
    bool? isFeesPaid,
  }) {
    return QueueItem(
      id: id ?? this.id,
      patientMobile: patientMobile ?? this.patientMobile,
      queueNumber: queueNumber ?? this.queueNumber,
      entryTime: entryTime ?? this.entryTime,
      status: status ?? this.status,
      isFeesPaid: isFeesPaid ?? this.isFeesPaid,
    );
  }
}
