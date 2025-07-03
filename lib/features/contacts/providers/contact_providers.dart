// ============================================================================
// 5. CONTACT PROVIDERS - lib/features/contacts/providers/contact_providers.dart
// ============================================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/providers/service_providers.dart';

final registeredContactsProvider = FutureProvider<List<AppUser>>((ref) async {
  final contactService = ref.read(contactServiceProvider);
  return await contactService.getRegisteredContacts();
});

final contactSearchProvider = StateProvider<String>((ref) => '');

final filteredContactsProvider = Provider<List<AppUser>>((ref) {
  final contactsAsync = ref.watch(registeredContactsProvider);
  final searchQuery = ref.watch(contactSearchProvider);
  final selectedContacts = ref.watch(selectedContactsProvider);

  return contactsAsync.when(
    data: (contacts) {
      var filtered = contacts.where((contact) {
        return !selectedContacts.any((selected) => selected.id == contact.id);
      }).toList();

      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((contact) {
          return contact.displayName.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              contact.phone.contains(searchQuery);
        }).toList();
      }

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
