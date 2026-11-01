class XpSourceType {
  static const String habitCheckin = 'HABIT_CHECKIN';
  static const String focusSession = 'FOCUS_SESSION';
  static const String achievement = 'ACHIEVEMENT';
  static const String cleanSheet = 'CLEAN_SHEET';
}

class XpStatus {
  static const String active = 'ACTIVE';
  static const String revoked = 'REVOKED';
}

class XpEntry {
  final int? id;
  final String sourceType;
  final int? sourceId;
  final String eventDate;
  final int xpAmount;
  final String status;
  final DateTime createdAt;

  const XpEntry({
    this.id,
    required this.sourceType,
    this.sourceId,
    required this.eventDate,
    required this.xpAmount,
    this.status = XpStatus.active,
    required this.createdAt,
  });

  bool get isActive => status == XpStatus.active;
  bool get isRevoked => status == XpStatus.revoked;

  XpEntry copyWith({
    int? id,
    String? sourceType,
    int? sourceId,
    String? eventDate,
    int? xpAmount,
    String? status,
    DateTime? createdAt,
  }) {
    return XpEntry(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      eventDate: eventDate ?? this.eventDate,
      xpAmount: xpAmount ?? this.xpAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'source_type': sourceType,
      'source_id': sourceId,
      'event_date': eventDate,
      'xp_amount': xpAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory XpEntry.fromMap(Map<String, dynamic> map) {
    return XpEntry(
      id: map['id'] as int?,
      sourceType: map['source_type'] as String,
      sourceId: map['source_id'] as int?,
      eventDate: map['event_date'] as String,
      xpAmount: map['xp_amount'] as int,
      status: (map['status'] as String?) ?? XpStatus.active,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is XpEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourceType == other.sourceType &&
          sourceId == other.sourceId &&
          eventDate == other.eventDate &&
          xpAmount == other.xpAmount &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      sourceType.hashCode ^
      sourceId.hashCode ^
      eventDate.hashCode ^
      xpAmount.hashCode ^
      status.hashCode;
}
