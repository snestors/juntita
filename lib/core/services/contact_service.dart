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

    // Extraer números de teléfono
    final phoneNumbers = <String>[];
    final contactMap = <String, Contact>{};

    for (final contact in contacts) {
      if (contact.phones.isNotEmpty) {
        for (final phone in contact.phones) {
          final normalizedPhone = _normalizePhoneNumber(phone.number);
          phoneNumbers.add(normalizedPhone);
          contactMap[normalizedPhone] = contact;
        }
      }
    }

    // Buscar cuáles están registrados en la app
    final registeredUsers = <AppUser>[];

    // Hacer consultas en lotes de 10 (límite de Firestore para 'in')
    for (int i = 0; i < phoneNumbers.length; i += 10) {
      final batch = phoneNumbers.skip(i).take(10).toList();

      if (batch.isEmpty) continue;

      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', whereIn: batch)
          .get();

      for (final doc in querySnapshot.docs) {
        final userData = doc.data();
        final user = AppUser.fromMap({...userData, 'id': doc.id});

        // Agregar nombre del contacto si está disponible
        final contact = contactMap[user.phone];
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
      return contact.displayName.toLowerCase().contains(query.toLowerCase()) ||
          contact.phones.any(
            (phone) =>
                phone.number.contains(query.replaceAll(RegExp(r'[^\d]'), '')),
          );
    }).toList();
  }

  String _normalizePhoneNumber(String phone) {
    // Remover espacios, guiones, paréntesis, mantener solo dígitos y +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Si no empieza con +, agregar código de país (ejemplo para Perú)
    if (!cleaned.startsWith('+')) {
      // Detectar si es número local peruano (9 dígitos)
      if (cleaned.length == 9 && cleaned.startsWith('9')) {
        cleaned = '+51$cleaned';
      }
      // Agregar más lógica para otros países según necesites
    }

    return cleaned;
  }

  // Método helper para invitar contactos que no tienen la app
  Future<void> inviteContact(Contact contact) async {
    // Implementar lógica de invitación (SMS, WhatsApp, etc.)
    // Por ahora solo un placeholder
    print('Invitando a ${contact.displayName}');
  }
}
