// lib/features/groups/services/group_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:junta/shared/models/junta_group_model.dart';
import 'package:junta/shared/models/junta_round_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear grupo
  Future<String> createGroup(JuntaGroup group) async {
    try {
      final docRef = await _firestore.collection('groups').add(group.toMap());

      // Crear documento de rondas
      await _createInitialRounds(docRef.id, group);

      return docRef.id;
    } catch (e) {
      throw Exception('Error creando grupo: $e');
    }
  }

  // Obtener grupos del usuario
  Stream<List<JuntaGroup>> getUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JuntaGroup.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  // Generar rondas iniciales
  Future<void> _createInitialRounds(String groupId, JuntaGroup group) async {
    final List<String> shuffledParticipants = List.from(group.participantIds)
      ..shuffle();

    final batch = _firestore.batch();

    for (int i = 0; i < shuffledParticipants.length; i++) {
      final dueDate = group.startDate.add(
        Duration(days: group.daysInterval * i),
      );

      final round = JuntaRound(
        id: '', // Se asignará automáticamente
        groupId: groupId,
        roundNumber: i + 1,
        winnerId: shuffledParticipants[i],
        dueDate: dueDate,
      );

      final roundRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('rounds')
          .doc();

      batch.set(roundRef, round.toMap()..['id'] = roundRef.id);
    }

    await batch.commit();
  }
}
