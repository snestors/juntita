// lib/features/contacts/services/contact_service.dart

import 'package:fast_contacts/fast_contacts.dart';
import 'package:junta/shared/models/user_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  Future<List<AppUser>> getRegisteredContacts() async {
    if (!await requestContactsPermission()) {
      throw Exception('Permisos de contactos denegados');
    }

    // Obtener contactos del teléfono con fast_contacts
    final contacts = await FastContacts.getAllContacts();

    // Extraer correos electrónicos
    final emails = <String>[];
    final contactMap = <String, Contact>{};

    for (final contact in contacts) {
      if (contact.emails.isNotEmpty) {
        for (final email in contact.emails) {
          final normalized = email.address.toLowerCase();
          emails.add(normalized);
          contactMap[normalized] = contact;
        }
      }
    }

    // Buscar cuáles están registrados en la app
    final registeredUsers = <AppUser>[];

    // Hacer consultas en lotes de 10 (límite de Firestore para 'in')
    for (int i = 0; i < emails.length; i += 10) {
      final batch = emails.skip(i).take(10).toList();

      if (batch.isEmpty) continue;

      final querySnapshot = await _firestore
          .collection('users')
          .where('email', whereIn: batch)
          .get();

      for (final doc in querySnapshot.docs) {
        final userData = doc.data();
        final user = AppUser.fromMap({...userData, 'id': doc.id});

        // Agregar nombre del contacto si está disponible
        final contact = contactMap[user.email.toLowerCase()];
        if (contact != null && contact.displayName.isNotEmpty) {
          // Opcional: usar nombre del contacto local si está disponible
          registeredUsers.add(user.copyWith(contactName: contact.displayName));
        } else {
          registeredUsers.add(user);
        }
      }
    }

    return registeredUsers;
  }

  // Buscar contactos por nombre (útil para búsqueda)
  Future<List<Contact>> searchContacts(String query) async {
    if (!await requestContactsPermission()) {
      throw Exception('Permisos de contactos denegados');
    }

    final contacts = await FastContacts.getAllContacts();

    if (query.isEmpty) return contacts;

    return contacts.where((contact) {
      final lower = query.toLowerCase();
      return contact.displayName.toLowerCase().contains(lower) ||
          contact.emails.any(
            (email) => email.address.toLowerCase().contains(lower),
          );
    }).toList();
  }

  // Método helper para invitar contactos que no tienen la app
  Future<void> inviteContact(Contact contact) async {
    // Implementar lógica de invitación (SMS, WhatsApp, etc.)
    // Por ahora solo un placeholder
    print('Invitando a ${contact.displayName}');
  }
}
