// 2. PANTALLA DE SELECCIÓN DE CONTACTOS - lib/features/contacts/screens/contact_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:junta/shared/models/user_model.dart';
import '../../../core/providers/service_providers.dart';

class ContactSelectionScreen extends ConsumerStatefulWidget {
  final List<AppUser> excludeUsers;

  const ContactSelectionScreen({Key? key, this.excludeUsers = const []})
    : super(key: key);

  @override
  ConsumerState<ContactSelectionScreen> createState() =>
      _ContactSelectionScreenState();
}

class _ContactSelectionScreenState
    extends ConsumerState<ContactSelectionScreen> {
  List<AppUser> _availableContacts = [];
  List<AppUser> _selectedContacts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contactService = ref.read(contactServiceProvider);
      final contacts = await contactService.getRegisteredContacts();

      // Filtrar usuarios excluidos
      final excludeIds = widget.excludeUsers.map((u) => u.id).toSet();
      final availableContacts = contacts
          .where((contact) => !excludeIds.contains(contact.id))
          .toList();

      setState(() {
        _availableContacts = availableContacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando contactos: $e')));
      }
    }
  }

  List<AppUser> get _filteredContacts {
    if (_searchQuery.isEmpty) return _availableContacts;

    return _availableContacts.where((contact) {
      return contact.displayName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          contact.phone.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar Contactos'),
        actions: [
          if (_selectedContacts.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, _selectedContacts),
              child: Text('LISTO (${_selectedContacts.length})'),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Lista de contactos
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contacts, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No hay contactos disponibles'
                              : 'No se encontraron contactos',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final isSelected = _selectedContacts.contains(contact);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: contact.photoUrl != null
                              ? NetworkImage(contact.photoUrl!)
                              : null,
                          child: contact.photoUrl == null
                              ? Text(contact.displayName[0].toUpperCase())
                              : null,
                        ),
                        title: Text(contact.displayName),
                        subtitle: Text(contact.phone),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedContacts.add(contact);
                              } else {
                                _selectedContacts.remove(contact);
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedContacts.remove(contact);
                            } else {
                              _selectedContacts.add(contact);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
