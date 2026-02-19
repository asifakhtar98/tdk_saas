import 'package:flutter/material.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

class TournamentFormDialog extends StatefulWidget {
  const TournamentFormDialog({super.key, this.initialTournament, this.onSave});

  final TournamentEntity? initialTournament;
  final void Function(
    String name,
    String? description,
    DateTime? scheduledDate,
  )?
  onSave;

  @override
  State<TournamentFormDialog> createState() => _TournamentFormDialogState();
}

class _TournamentFormDialogState extends State<TournamentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDate;
  FederationType _selectedFederation = FederationType.wt;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialTournament?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialTournament?.description ?? '',
    );
    _selectedDate = widget.initialTournament?.scheduledDate;
    _selectedFederation =
        widget.initialTournament?.federationType ?? FederationType.wt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.initialTournament != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Tournament' : 'Create Tournament'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tournament Name *',
                    hintText: 'Enter tournament name',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Tournament name is required';
                    }
                    if (value.length > 100) {
                      return 'Name must be 100 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter tournament description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 500,
                  validator: (value) {
                    if (value != null && value.length > 500) {
                      return 'Description must be 500 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tournament Date *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedDate != null
                          ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                          : 'Select a date',
                      style: TextStyle(
                        color: _selectedDate != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<FederationType>(
                  value: _selectedFederation,
                  decoration: const InputDecoration(
                    labelText: 'Federation Type',
                    border: OutlineInputBorder(),
                  ),
                  items: FederationType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getFederationLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedFederation = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveForm,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a tournament date')),
        );
        return;
      }
      widget.onSave?.call(
        _nameController.text.trim(),
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        _selectedDate,
      );
      Navigator.of(context).pop();
    }
  }

  String _getFederationLabel(FederationType type) {
    switch (type) {
      case FederationType.wt:
        return 'World Taekwondo (WT)';
      case FederationType.itf:
        return 'International Taekwondo Federation (ITF)';
      case FederationType.ata:
        return 'American Taekwondo Association (ATA)';
      case FederationType.custom:
        return 'Custom';
    }
  }
}
