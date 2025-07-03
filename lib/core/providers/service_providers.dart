// ============================================================================
// 1. PROVIDERS DE SERVICIOS - lib/core/providers/service_providers.dart
// ============================================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/services/auth_service.dart';
import '../../core/services/group_service.dart';
import '../../core/services/contact_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final groupServiceProvider = Provider<GroupService>((ref) => GroupService());
final contactServiceProvider = Provider<ContactService>(
  (ref) => ContactService(),
);
