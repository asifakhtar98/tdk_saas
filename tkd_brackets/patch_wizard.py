import re

file_path = "lib/features/tournament/presentation/pages/division_builder_wizard.dart"
with open(file_path, "r") as f:
    content = f.read()

# 1. Add imports
imports = """import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/features/division/domain/usecases/smart_division_builder_params.dart';
import 'package:tkd_brackets/features/division/presentation/bloc/division_builder_bloc.dart';
import 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_detail_bloc.dart';
import 'package:tkd_brackets/features/tournament/presentation/bloc/tournament_detail_event.dart';"""

content = re.sub(r"import 'package:flutter/material\.dart';\nimport 'package:tkd_brackets/features/tournament/domain/entities/tournament_entity\.dart';", imports, content)

# 2. Refactor DivisionBuilderWizard widget to provide Bloc
wizard_class_old = """class DivisionBuilderWizard extends StatefulWidget {
  const DivisionBuilderWizard({required this.tournamentId, super.key});

  final String tournamentId;

  @override
  State<DivisionBuilderWizard> createState() => _DivisionBuilderWizardState();
}

class _DivisionBuilderWizardState extends State<DivisionBuilderWizard> {"""

wizard_class_new = """class DivisionBuilderWizard extends StatelessWidget {
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

class _DivisionBuilderWizardViewState extends State<_DivisionBuilderWizardView> {"""

content = content.replace(wizard_class_old, wizard_class_new)

# 3. Wrapping Stepper with BlocConsumer
build_method_old = """  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Division Builder')),
      body: Stepper("""

build_method_new = """  @override
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
            
            context.read<TournamentDetailBloc>().add(
                  TournamentDetailEvent.loadRequested(widget.tournamentId),
                );
                
            Navigator.of(context).pop();
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
          body: Stepper("""

content = content.replace(build_method_old, build_method_new)

# 4. Closing the BlocConsumer
build_end_old = """        ],
      ),
    );
  }"""
build_end_new = """        ],
      ),
    );
      },
    );
  }"""

content = content.replace(build_end_old, build_end_new)

# 5. Fix _createDivisions
create_div_old = """  Future<void> _createDivisions() async {
    setState(() {
      _isCreating = true;
    });

    await Future<void>.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Divisions created successfully!')),
      );
      Navigator.of(context).pop();
    }
  }"""

create_div_new = """  void _createDivisions() {
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
  }"""

content = content.replace(create_div_old, create_div_new)

with open(file_path, "w") as f:
    f.write(content)
print("done")
