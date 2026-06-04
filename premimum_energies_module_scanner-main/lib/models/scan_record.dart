class ScanRecord {
  final int? id;
  final String? mongoId;
  final String date;
  final String moduleId;
  final String jobCard;
  final String station;
  final String operatorName;
  final String reason;
  final String savedBy;

  ScanRecord({
    this.id,
    this.mongoId,
    required this.date,
    required this.moduleId,
    required this.jobCard,
    required this.station,
    required this.operatorName,
    required this.reason,
    this.savedBy = '',
  });

  // For local SQLite (legacy — can be removed later)
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

  // For API communication (MongoDB)
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'moduleId': moduleId,
      'jobCard': jobCard,
      'station': station,
      'operatorName': operatorName,
      'reason': reason,
    };
  }

  factory ScanRecord.fromJson(Map<String, dynamic> json) {
    return ScanRecord(
      mongoId: json['_id'],
      date: json['date'] ?? '',
      moduleId: json['moduleId'] ?? '',
      jobCard: json['jobCard'] ?? '',
      station: json['station'] ?? '',
      operatorName: json['operatorName'] ?? '',
      reason: json['reason'] ?? '',
      savedBy: json['savedBy'] ?? '',
    );
  }
}
