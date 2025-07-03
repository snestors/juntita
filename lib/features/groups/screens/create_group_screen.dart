// lib/features/groups/screens/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:junta/core/providers/app_provider.dart';
import 'package:junta/features/contacts/screens/contact_selection_screen.dart';

import '../../../shared/models/user_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final selectedParticipants = ref.watch(selectedContactsProvider);
    final isCreating = ref.watch(isCreatingGroupProvider);
    final groupController = ref.read(groupCreationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva Junta'),
        actions: [
          TextButton(
            onPressed: isCreating ? null : _createGroup,
            child: isCreating
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('CREAR'),
          ),
        ],
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

            // Monto y moneda
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
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intervalo de pagos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
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
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Fecha de inicio
            Card(
              child: ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Fecha de inicio'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                trailing: Icon(Icons.chevron_right),
                onTap: _selectStartDate,
              ),
            ),

            SizedBox(height: 24),

            // Sección de participantes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Participantes (${selectedParticipants.length})',
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
            if (selectedParticipants.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.group_add, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Agrega participantes a tu junta',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Column(
                  children: selectedParticipants
                      .map(
                        (user) => _buildParticipantTile(user, groupController),
                      )
                      .toList(),
                ),
              ),

            SizedBox(height: 16),

            // Información adicional
            if (selectedParticipants.isNotEmpty)
              Card(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de la junta',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• ${selectedParticipants.length + 1} participantes total',
                      ),
                      Text('• Cada $_daysInterval días'),
                      Text(
                        '• Total de rondas: ${selectedParticipants.length + 1}',
                      ),
                      Text(
                        '• Duración: ${(selectedParticipants.length + 1) * _daysInterval} días',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantTile(
    AppUser user,
    GroupCreationController controller,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.photoUrl != null
            ? NetworkImage(user.photoUrl!)
            : null,
        child: user.photoUrl == null
            ? Text(user.displayName[0].toUpperCase())
            : null,
      ),
      title: Text(user.displayName),
      subtitle: Text(user.email),
      trailing: IconButton(
        icon: Icon(Icons.remove_circle_outline, color: Colors.red),
        onPressed: () => controller.removeContact(user),
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactSelectionScreenOptimized(),
      ),
    );
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedParticipants = ref.read(selectedContactsProvider);
    if (selectedParticipants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Necesitas al menos 2 participantes')),
      );
      return;
    }

    try {
      final groupController = ref.read(groupCreationControllerProvider);

      final success = await groupController.createGroup(
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        currency: _currency,
        daysInterval: _daysInterval,
        startDate: _startDate,
      );

      if (success && mounted) {
        context.pop(); // Usar go_router
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Junta creada exitosamente')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
