// lib/features/contacts/screens/contact_selection_screen_optimized.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:junta/core/providers/app_provider.dart';

import '../../../shared/models/user_model.dart';

class ContactSelectionScreenOptimized extends ConsumerStatefulWidget {
  const ContactSelectionScreenOptimized({super.key});

  @override
  ConsumerState<ContactSelectionScreenOptimized> createState() =>
      _ContactSelectionScreenOptimizedState();
}

class _ContactSelectionScreenOptimizedState
    extends ConsumerState<ContactSelectionScreenOptimized> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Limpiar búsqueda al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contactSearchProvider.notifier).state = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = ref.watch(filteredContactsProvider);
    final selectedContacts = ref.watch(selectedContactsProvider);
    final contactsAsync = ref.watch(registeredContactsProvider);
    final groupController = ref.read(groupCreationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar Contactos'),
        actions: [
          if (selectedContacts.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('LISTO (${selectedContacts.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar contactos...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(contactSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                ref.read(contactSearchProvider.notifier).state = value;
              },
            ),
          ),

          // Contactos seleccionados (chips)
          if (selectedContacts.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: selectedContacts.map((contact) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundImage: contact.photoUrl != null
                          ? NetworkImage(contact.photoUrl!)
                          : null,
                      child: contact.photoUrl == null
                          ? Text(contact.displayName[0].toUpperCase())
                          : null,
                    ),
                    label: Text(contact.displayName),
                    onDeleted: () => groupController.removeContact(contact),
                    deleteIcon: Icon(Icons.close, size: 18),
                  );
                }).toList(),
              ),
            ),

          if (selectedContacts.isNotEmpty) Divider(),

          // Lista de contactos
          Expanded(
            child: contactsAsync.when(
              data: (allContacts) {
                if (allContacts.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.contacts,
                    title: 'Sin contactos registrados',
                    subtitle: 'Invita a tus amigos a usar Juntas App',
                  );
                }

                if (filteredContacts.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.search_off,
                    title: 'No se encontraron contactos',
                    subtitle: 'Intenta con otros términos de búsqueda',
                  );
                }

                return ListView.builder(
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    final isSelected = selectedContacts.any(
                      (selected) => selected.id == contact.id,
                    );

                    return _buildContactTile(
                      contact: contact,
                      isSelected: isSelected,
                      onTap: () {
                        if (isSelected) {
                          groupController.removeContact(contact);
                        } else {
                          groupController.addContact(contact);
                        }
                      },
                    );
                  },
                );
              },
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando contactos...'),
                  ],
                ),
              ),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
      floatingActionButton: selectedContacts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.check),
              label: Text('Continuar (${selectedContacts.length})'),
            )
          : null,
    );
  }

  Widget _buildContactTile({
    required AppUser contact,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : null,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: contact.photoUrl != null
                  ? NetworkImage(contact.photoUrl!)
                  : null,
              child: contact.photoUrl == null
                  ? Text(contact.displayName[0].toUpperCase())
                  : null,
            ),
            if (contact.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          contact.displayName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(contact.email),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
            : Icon(Icons.add_circle_outline),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error cargando contactos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(registeredContactsProvider);
              },
              child: Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
