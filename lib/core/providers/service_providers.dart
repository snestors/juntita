// 1. PROVIDERS - lib/core/providers/service_providers.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:junta/core/services/contact_service.dart';
import 'package:junta/core/services/group_service.dart';
import '../services/firebase_service.dart';

// Provider para GroupService
final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService();
});

// Provider para ContactService
final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});

// Provider para usuario actual
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseService.authStateChanges;
});
