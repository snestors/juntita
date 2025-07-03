class JuntaRound {
  final String id;
  final String groupId;
  final int roundNumber;
  final String winnerId;
  final DateTime dueDate;
  final RoundStatus status;
  final DateTime? completedAt;
  final List<String> confirmedParticipants;

  JuntaRound({
    required this.id,
    required this.groupId,
    required this.roundNumber,
    required this.winnerId,
    required this.dueDate,
    this.status = RoundStatus.pending,
    this.completedAt,
    this.confirmedParticipants = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'roundNumber': roundNumber,
      'winnerId': winnerId,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'status': status.name,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'confirmedParticipants': confirmedParticipants,
    };
  }

  factory JuntaRound.fromMap(Map<String, dynamic> map) {
    return JuntaRound(
      id: map['id'],
      groupId: map['groupId'],
      roundNumber: map['roundNumber'],
      winnerId: map['winnerId'],
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate']),
      status: RoundStatus.values.byName(map['status']),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      confirmedParticipants: List<String>.from(
        map['confirmedParticipants'] ?? [],
      ),
    );
  }
}

enum RoundStatus { pending, active, completed, overdue }
