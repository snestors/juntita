class JuntaGroup {
  final String id;
  final String name;
  final String adminId;
  final double amount;
  final String currency;
  final int daysInterval; // cada cuántos días
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime startDate;
  final GroupStatus status;
  final int currentRound;

  JuntaGroup({
    required this.id,
    required this.name,
    required this.adminId,
    required this.amount,
    required this.currency,
    required this.daysInterval,
    required this.participantIds,
    required this.createdAt,
    required this.startDate,
    this.status = GroupStatus.waiting,
    this.currentRound = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'adminId': adminId,
      'amount': amount,
      'currency': currency,
      'daysInterval': daysInterval,
      'participantIds': participantIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startDate': startDate.millisecondsSinceEpoch,
      'status': status.name,
      'currentRound': currentRound,
    };
  }

  factory JuntaGroup.fromMap(Map<String, dynamic> map) {
    return JuntaGroup(
      id: map['id'],
      name: map['name'],
      adminId: map['adminId'],
      amount: map['amount'].toDouble(),
      currency: map['currency'],
      daysInterval: map['daysInterval'],
      participantIds: List<String>.from(map['participantIds']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      status: GroupStatus.values.byName(map['status']),
      currentRound: map['currentRound'],
    );
  }
}

enum GroupStatus { waiting, active, completed, cancelled }
