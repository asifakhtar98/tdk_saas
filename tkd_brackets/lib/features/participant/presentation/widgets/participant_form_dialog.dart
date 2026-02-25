import 'package:flutter/material.dart';
import 'package:tkd_brackets/features/participant/domain/entities/participant_entity.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/create_participant_params.dart';
import 'package:tkd_brackets/features/participant/domain/usecases/update_participant_params.dart';

/// Dialog for creating or editing a participant.
///
/// In CREATE mode, [participant] is null and the dialog shows empty fields.
/// In EDIT mode, [participant] is pre-filled with existing data.
class ParticipantFormDialog extends StatefulWidget {
  const ParticipantFormDialog({
    required this.divisionId,
    required this.onSave,
    super.key,
    this.participant,
  });

  final String divisionId;
  final ParticipantEntity? participant;

  /// Called with either [CreateParticipantParams]
  /// or [UpdateParticipantParams].
  final void Function(Object params) onSave;

  @override
  State<ParticipantFormDialog> createState() =>
      _ParticipantFormDialogState();
}

class _ParticipantFormDialogState
    extends State<ParticipantFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _schoolController;
  late TextEditingController _beltController;
  late TextEditingController _weightController;
  late TextEditingController _regNumberController;
  late TextEditingController _notesController;
  DateTime? _dateOfBirth;
  Gender? _gender;

  @override
  void initState() {
    super.initState();
    final p = widget.participant;
    _firstNameController = TextEditingController(
      text: p?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: p?.lastName ?? '',
    );
    _schoolController = TextEditingController(
      text: p?.schoolOrDojangName ?? '',
    );
    _beltController = TextEditingController(
      text: p?.beltRank ?? '',
    );
    _weightController = TextEditingController(
      text: p?.weightKg?.toString() ?? '',
    );
    _regNumberController = TextEditingController(
      text: p?.registrationNumber ?? '',
    );
    _notesController = TextEditingController(
      text: p?.notes ?? '',
    );
    _dateOfBirth = p?.dateOfBirth;
    _gender = p?.gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _schoolController.dispose();
    _beltController.dispose();
    _weightController.dispose();
    _regNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (widget.participant == null) {
        final params = CreateParticipantParams(
          divisionId: widget.divisionId,
          firstName:
              _firstNameController.text.trim(),
          lastName:
              _lastNameController.text.trim(),
          schoolOrDojangName:
              _schoolController.text.trim(),
          beltRank: _beltController.text.trim(),
          dateOfBirth: _dateOfBirth,
          gender: _gender,
          weightKg: double.tryParse(
            _weightController.text,
          ),
          registrationNumber:
              _regNumberController.text.trim(),
          notes: _notesController.text.trim(),
        );
        widget.onSave(params);
      } else {
        final params = UpdateParticipantParams(
          participantId: widget.participant!.id,
          firstName:
              _firstNameController.text.trim(),
          lastName:
              _lastNameController.text.trim(),
          schoolOrDojangName:
              _schoolController.text.trim(),
          beltRank: _beltController.text.trim(),
          dateOfBirth: _dateOfBirth,
          gender: _gender,
          weightKg: double.tryParse(
            _weightController.text,
          ),
          registrationNumber:
              _regNumberController.text.trim(),
          notes: _notesController.text.trim(),
        );
        widget.onSave(params);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.participant != null;
    return AlertDialog(
      title: Text(
        isEdit
            ? 'Edit Participant'
            : 'Add Participant',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name *',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Required'
                        : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Required'
                        : null,
              ),
              TextFormField(
                controller: _schoolController,
                decoration: const InputDecoration(
                  labelText: 'School / Dojang *',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Required'
                        : null,
              ),
              TextFormField(
                controller: _beltController,
                decoration: const InputDecoration(
                  labelText: 'Belt Rank *',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Required'
                        : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<
                      Gender
                    >(
                      initialValue: _gender,
                      decoration:
                          const InputDecoration(
                        labelText: 'Gender',
                      ),
                      items: Gender.values.map((g) {
                        return DropdownMenuItem(
                          value: g,
                          child: Text(
                            g.value.toUpperCase(),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setState(() => _gender = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration:
                          const InputDecoration(
                        labelText: 'Weight (kg)',
                        suffixText: 'kg',
                      ),
                      keyboardType:
                          TextInputType.number,
                      validator: (v) {
                        if (v != null &&
                            v.isNotEmpty) {
                          final w =
                              double.tryParse(v);
                          if (w == null ||
                              w < 0 ||
                              w > 150) {
                            return '0-150 kg';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _dateOfBirth == null
                      ? 'Select Date of Birth'
                      : 'DOB: ${_dateOfBirth!.year}-'
                          '${_dateOfBirth!.month}-'
                          '${_dateOfBirth!.day}',
                ),
                trailing:
                    const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked =
                      await showDatePicker(
                    context: context,
                    initialDate:
                        _dateOfBirth ?? DateTime(2010),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(
                      () => _dateOfBirth = picked,
                    );
                  }
                },
              ),
              TextFormField(
                controller: _regNumberController,
                decoration: const InputDecoration(
                  labelText: 'Registration #',
                ),
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
