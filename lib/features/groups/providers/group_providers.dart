// ============================================================================
// 4. GROUP PROVIDERS - lib/features/groups/providers/group_providers.dart
// ============================================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:junta/features/auth/providers/auth_provider.dart';
import '../../../shared/models/junta_group_model.dart';
import '../../../shared/models/user_model.dart';

import '../../../core/providers/service_providers.dart';

final userGroupsProvider = StreamProvider<List<JuntaGroup>>((ref) {
  final firebaseUser = ref.watch(firebaseUserProvider).value;
  if (firebaseUser == null) return Stream.value([]);

  final groupService = ref.read(groupServiceProvider);
  return groupService.getUserGroups(firebaseUser.uid);
});

final selectedContactsProvider = StateProvider<List<AppUser>>((ref) => []);

final groupCreationProvider = Provider<GroupCreationController>((ref) {
  return GroupCreationController(ref);
});

class GroupCreationController {
  final Ref _ref;
  GroupCreationController(this._ref);

  Future<bool> createGroup({
    required String name,
    required double amount,
    required String currency,
    required int daysInterval,
    required DateTime startDate,
  }) async {
    final selectedContacts = _ref.read(selectedContactsProvider);
    final currentUser = _ref.read(firebaseUserProvider).value;

    if (currentUser == null) throw Exception('Usuario no autenticado');
    if (selectedContacts.length < 2) throw Exception('Mínimo 2 participantes');

    final group = JuntaGroup(
      id: '',
      name: name,
      adminId: currentUser.uid,
      amount: amount,
      currency: currency,
      daysInterval: daysInterval,
      participantIds: [currentUser.uid, ...selectedContacts.map((u) => u.id)],
      createdAt: DateTime.now(),
      startDate: startDate,
    );

    final groupService = _ref.read(groupServiceProvider);
    await groupService.createGroup(group);

    // Limpiar selección
    _ref.read(selectedContactsProvider.notifier).state = [];
    return true;
  }

  void addContact(AppUser contact) {
    final current = _ref.read(selectedContactsProvider);
    if (!current.any((c) => c.id == contact.id)) {
      _ref.read(selectedContactsProvider.notifier).state = [
        ...current,
        contact,
      ];
    }
  }

  void removeContact(AppUser contact) {
    final current = _ref.read(selectedContactsProvider);
    _ref.read(selectedContactsProvider.notifier).state = current
        .where((c) => c.id != contact.id)
        .toList();
  }

  void clearContacts() {
    _ref.read(selectedContactsProvider.notifier).state = [];
  }
}
