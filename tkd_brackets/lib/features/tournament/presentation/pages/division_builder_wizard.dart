import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/features/division/domain/usecases/smart_division_builder_params.dart';
import 'package:tkd_brackets/features/division/presentation/bloc/division_builder_bloc.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';

class DivisionBuilderWizard extends StatelessWidget {
  const DivisionBuilderWizard({required this.tournamentId, super.key});

  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DivisionBuilderBloc>(),
      child: _DivisionBuilderWizardView(tournamentId: tournamentId),
    );
  }
}

class _DivisionBuilderWizardView extends StatefulWidget {
  const _DivisionBuilderWizardView({required this.tournamentId});

  final String tournamentId;

  @override
  State<_DivisionBuilderWizardView> createState() =>
      _DivisionBuilderWizardViewState();
}

class _DivisionBuilderWizardViewState extends State<_DivisionBuilderWizardView> {
  int _currentStep = 0;
  FederationType _selectedFederation = FederationType.wt;
  final Set<String> _selectedAgeGroups = {};
  final Set<String> _selectedBeltGroups = {};
  bool _isCreating = false;

  static const _ageGroups = [
    '6-8',
    '9-10',
    '11-12',
    '13-14',
    '15-17',
    '18-32',
    '33+',
  ];

  static const _beltGroups = ['white-yellow', 'green-blue', 'red-black'];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DivisionBuilderBloc, DivisionBuilderState>(
      listener: (context, state) {
        state.whenOrNull(
          inProgress: () {
            setState(() {
              _isCreating = true;
            });
          },
          success: () {
            setState(() {
              _isCreating = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Divisions created successfully!')),
            );
            
            context.go('/tournaments/${widget.tournamentId}');
          },
          failure: (message) {
            setState(() {
              _isCreating = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $message'), backgroundColor: Colors.red),
            );
          },
        );
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Division Builder')),
          body: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    const SizedBox(width: 8),
                    if (_currentStep < 4)
                      FilledButton(
                        onPressed: details.onStepContinue,
                        child: const Text('Continue'),
                      )
                    else
                      FilledButton(
                        onPressed: _isCreating ? null : _createDivisions,
                        child: _isCreating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Divisions'),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Select Federation'),
                subtitle: Text(_selectedFederation.value.toUpperCase()),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: _buildFederationSelection(),
              ),
              Step(
                title: const Text('Configure Age Groups'),
                subtitle: Text('${_selectedAgeGroups.length} selected'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: _buildAgeGroupSelection(),
              ),
              Step(
                title: const Text('Configure Belt Groups'),
                subtitle: Text('${_selectedBeltGroups.length} selected'),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                content: _buildBeltGroupSelection(),
              ),
              Step(
                title: const Text('Configure Weight Classes'),
                isActive: _currentStep >= 3,
                state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                content: _buildWeightClassInfo(),
              ),
              Step(
                title: const Text('Review & Create'),
                isActive: _currentStep >= 4,
                state: _currentStep > 4 ? StepState.complete : StepState.indexed,
                content: _buildReview(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFederationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select the federation type for your tournament:'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FederationType.values.map((type) {
            final isSelected = _selectedFederation == type;
            return ChoiceChip(
              label: Text(_getFederationLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFederation = type;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAgeGroupSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select the age groups to include:'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ageGroups.map((age) {
            final isSelected = _selectedAgeGroups.contains(age);
            return FilterChip(
              label: Text(age),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAgeGroups.add(age);
                  } else {
                    _selectedAgeGroups.remove(age);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedAgeGroups.addAll(_ageGroups);
                });
              },
              child: const Text('Select All'),
            ),
            TextButton(
              onPressed: () {
                setState(_selectedAgeGroups.clear);
              },
              child: const Text('Clear All'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBeltGroupSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select the belt rank groups to include:'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _beltGroups.map((belt) {
            final isSelected = _selectedBeltGroups.contains(belt);
            return FilterChip(
              label: Text(_formatBeltGroup(belt)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedBeltGroups.add(belt);
                  } else {
                    _selectedBeltGroups.remove(belt);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedBeltGroups.addAll(_beltGroups);
                });
              },
              child: const Text('Select All'),
            ),
            TextButton(
              onPressed: () {
                setState(_selectedBeltGroups.clear);
              },
              child: const Text('Clear All'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightClassInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_getWeightClassInfo()),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Weight classes will be automatically generated based on the selected federation and age groups.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReview() {
    final divisionsCount = _selectedAgeGroups.length *
        _selectedBeltGroups.length *
        _selectedGenderCount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review your division configuration:'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildReviewRow(
                  'Federation',
                  _getFederationLabel(_selectedFederation),
                ),
                const Divider(),
                _buildReviewRow(
                  'Age Groups',
                  _selectedAgeGroups.isEmpty
                      ? 'None selected'
                      : _selectedAgeGroups.join(', '),
                ),
                const Divider(),
                _buildReviewRow(
                  'Belt Groups',
                  _selectedBeltGroups.isEmpty
                      ? 'None selected'
                      : _selectedBeltGroups.map(_formatBeltGroup).join(', '),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This will create approximately $divisionsCount divisions (male and female for each age/belt combination).',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 1 && _selectedAgeGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one age group')),
      );
      return;
    }
    if (_currentStep == 2 && _selectedBeltGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one belt group')),
      );
      return;
    }
    setState(() {
      _currentStep += 1;
    });
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  void _createDivisions() {
    final ageGroupsConfig = AgeGroupConfig.storyAgeGroups
        .where((a) => _selectedAgeGroups.contains(a.name))
        .toList();

    final beltGroupsConfig = BeltGroupConfig.storyBeltGroups
        .where((b) => _selectedBeltGroups.contains(b.name))
        .toList();

    context.read<DivisionBuilderBloc>().add(
          DivisionBuilderEvent.createRequested(
            tournamentId: widget.tournamentId,
            federationType: _selectedFederation,
            ageGroups: ageGroupsConfig,
            beltGroups: beltGroupsConfig,
            weightClasses: WeightClassConfig.forFederation(_selectedFederation),
          ),
        );
  }

  int _selectedGenderCount() {
    return 2;
  }

  String _getFederationLabel(FederationType type) {
    switch (type) {
      case FederationType.wt:
        return 'World Taekwondo (WT)';
      case FederationType.itf:
        return 'International TKD (ITF)';
      case FederationType.ata:
        return 'American TKD (ATA)';
      case FederationType.custom:
        return 'Custom';
    }
  }

  String _formatBeltGroup(String belt) {
    switch (belt) {
      case 'white-yellow':
        return 'White - Yellow';
      case 'green-blue':
        return 'Green - Blue';
      case 'red-black':
        return 'Red - Black';
      default:
        return belt;
    }
  }

  String _getWeightClassInfo() {
    switch (_selectedFederation) {
      case FederationType.wt:
        return 'WT uses Olympic-style weight classes. Standard classes will be applied based on age and gender.';
      case FederationType.itf:
        return 'ITF uses pattern and sparring divisions with different weight considerations.';
      case FederationType.ata:
        return 'ATA uses forms and combat sparring divisions with traditional ranking.';
      case FederationType.custom:
        return 'Custom divisions will use the belt groups selected without specific weight limits.';
    }
  }
}
