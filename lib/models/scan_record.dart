class ScanRecord {
  final int? id;
  final String date;
  final String moduleId;
  final String jobCard;
  final String station;
  final String operatorName;
  final String reason;

  ScanRecord({
    this.id,
    required this.date,
    required this.moduleId,
    required this.jobCard,
    required this.station,
    required this.operatorName,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'module_id': moduleId,
      'job_card': jobCard,
      'station': station,
      'operator': operatorName,
      'reason': reason,
    };
  }

  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'],
      date: map['date'],
      moduleId: map['module_id'],
      jobCard: map['job_card'],
      station: map['station'],
      operatorName: map['operator'],
      reason: map['reason'],
    );
  }
}
