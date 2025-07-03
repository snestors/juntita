// lib/features/groups/screens/create_group_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:junta/core/providers/service_providers.dart';
import 'package:junta/features/contacts/screens/contact_selection_screen.dart';
import 'package:junta/shared/models/junta_group_model.dart';
import 'package:junta/shared/models/user_model.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  int _daysInterval = 15;
  String _currency = 'PEN';
  DateTime _startDate = DateTime.now().add(Duration(days: 7));
  final List<AppUser> _selectedParticipants = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva Junta'),
        actions: [TextButton(onPressed: _createGroup, child: Text('CREAR'))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Nombre del grupo
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la junta',
                hintText: 'Ej: Junta Los Amigos',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Ingresa un nombre';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Monto
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(labelText: 'Monto'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ingresa monto';
                      if (double.tryParse(value!) == null) {
                        return 'Monto inválido';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    items: ['PEN', 'USD', 'VES'].map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _currency = value!),
                    decoration: InputDecoration(labelText: 'Moneda'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Intervalo de días
            Row(
              children: [
                Text('Cada '),
                Expanded(
                  child: Slider(
                    value: _daysInterval.toDouble(),
                    min: 7,
                    max: 60,
                    divisions: 17,
                    label: '$_daysInterval días',
                    onChanged: (value) {
                      setState(() => _daysInterval = value.round());
                    },
                  ),
                ),
                Text(' días'),
              ],
            ),

            // Fecha de inicio
            ListTile(
              title: Text('Fecha de inicio'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
              trailing: Icon(Icons.calendar_today),
              onTap: _selectStartDate,
            ),

            SizedBox(height: 24),

            // Participantes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Participantes (${_selectedParticipants.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: _selectParticipants,
                  icon: Icon(Icons.add),
                  label: Text('Agregar'),
                ),
              ],
            ),

            // Lista de participantes seleccionados
            ..._selectedParticipants.map(
              (user) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(user.name[0].toUpperCase())
                      : null,
                ),
                title: Text(user.name),
                subtitle: Text(user.phone),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle),
                  onPressed: () {
                    setState(() {
                      _selectedParticipants.remove(user);
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectParticipants() async {
    // Navegar a pantalla de selección de contactos
    final result = await Navigator.push<List<AppUser>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ContactSelectionScreen(excludeUsers: _selectedParticipants),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedParticipants.addAll(result);
      });
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedParticipants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Necesitas al menos 2 participantes')),
      );
      return;
    }

    // Incluir al usuario actual como participante
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: Usuario no autenticado')));
      return;
    }
    final currentUserId = currentUser.uid;
    final participantIds = [
      currentUserId,
      ..._selectedParticipants.map((u) => u.id),
    ];

    final group = JuntaGroup(
      id: '',
      name: _nameController.text,
      adminId: currentUserId,
      amount: double.parse(_amountController.text),
      currency: _currency,
      daysInterval: _daysInterval,
      participantIds: participantIds,
      createdAt: DateTime.now(),
      startDate: _startDate,
    );

    try {
      final groupService = ref.read(groupServiceProvider);
      await groupService.createGroup(group);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Junta creada exitosamente')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
