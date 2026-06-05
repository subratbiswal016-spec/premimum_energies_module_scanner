class ScanRecord {
  final int? id;
  final String date;
  final String moduleId;
  final String jobCard;
  final String station;
  final String operatorName;
  final String reason;
  final bool isSynced;
  final String? backendId;
  final String? savedBy;
  final String? time;

  ScanRecord({
    this.id,
    required this.date,
    required this.moduleId,
    required this.jobCard,
    required this.station,
    required this.operatorName,
    required this.reason,
    this.isSynced = false,
    this.backendId,
    this.savedBy,
    this.time,
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
      'is_synced': isSynced ? 1 : 0,
      'backend_id': backendId,
      'saved_by': savedBy,
      'time': time,
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
      reason: map['reason'] ?? '',
      isSynced: (map['is_synced'] ?? 0) == 1,
      backendId: map['backend_id'],
      savedBy: map['saved_by'],
      time: map['time'],
    );
  }

  ScanRecord copyWith({
    int? id,
    String? date,
    String? moduleId,
    String? jobCard,
    String? station,
    String? operatorName,
    String? reason,
    bool? isSynced,
    String? backendId,
    String? time,
    String? savedBy,
  }) {
    return ScanRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      moduleId: moduleId ?? this.moduleId,
      jobCard: jobCard ?? this.jobCard,
      station: station ?? this.station,
      operatorName: operatorName ?? this.operatorName,
      reason: reason ?? this.reason,
      isSynced: isSynced ?? this.isSynced,
      backendId: backendId ?? this.backendId,
      time: time ?? this.time,
      savedBy: savedBy ?? this.savedBy,
    );
  }
}
