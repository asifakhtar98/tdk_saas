import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'features/bracket/domain/entities/bracket_entity.dart';
import 'features/bracket/domain/entities/match_entity.dart';
import 'features/bracket/data/services/single_elimination_bracket_generator_service_implementation.dart';
import 'features/bracket/data/services/bracket_layout_engine_implementation.dart';
import 'features/bracket/presentation/widgets/bracket_viewer_widget.dart';
import 'features/participant/domain/entities/participant_entity.dart';
import 'features/division/domain/entities/division_entity.dart';

void main() {
  runApp(const BracketGeneratorApp());
}

class BracketGeneratorApp extends StatelessWidget {
  const BracketGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TKD Bracket Generator',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.tealAccent,
        ),
      ),
      home: const ParticipantEntryScreen(),
    );
  }
}

class ParticipantEntryScreen extends StatefulWidget {
  const ParticipantEntryScreen({super.key});

  @override
  State<ParticipantEntryScreen> createState() => _ParticipantEntryScreenState();
}

class _ParticipantEntryScreenState extends State<ParticipantEntryScreen> {
  final List<ParticipantEntity> _participants = [];
  final Uuid _uuid = const Uuid();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dojangController = TextEditingController();

  void _addParticipant() {
    if (_firstNameController.text.trim().isEmpty) return;

    setState(() {
      _participants.add(
        ParticipantEntity(
          id: _uuid.v4(),
          divisionId: 'manual_division',
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          schoolOrDojangName: _dojangController.text.trim().isNotEmpty ? _dojangController.text.trim() : null,
          seedNumber: _participants.length + 1,
        ),
      );
      _firstNameController.clear();
      _lastNameController.clear();
      _dojangController.clear();
    });
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Participants'),
        actions: [
          if (_participants.length >= 2)
            TextButton.icon(
              icon: const Icon(Icons.account_tree, color: Colors.white),
              label: const Text('Generate', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BracketViewerScreen(participants: _participants),
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'First Name'),
                        onSubmitted: (_) => _addParticipant(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Last Name'),
                        onSubmitted: (_) => _addParticipant(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _dojangController,
                        decoration: const InputDecoration(labelText: 'Dojang (Optional)'),
                        onSubmitted: (_) => _addParticipant(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 32, color: Colors.blueAccent),
                      onPressed: _addParticipant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _participants.isEmpty
                  ? const Center(child: Text('No participants added yet.'))
                  : ListView.builder(
                      itemCount: _participants.length,
                      itemBuilder: (context, index) {
                        final p = _participants[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('\${index + 1}')),
                          title: Text('\${p.firstName} \${p.lastName}'),
                          subtitle: p.schoolOrDojangName != null ? Text(p.schoolOrDojangName!) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _removeParticipant(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class BracketViewerScreen extends StatefulWidget {
  final List<ParticipantEntity> participants;

  const BracketViewerScreen({super.key, required this.participants});

  @override
  State<BracketViewerScreen> createState() => _BracketViewerScreenState();
}

class _BracketViewerScreenState extends State<BracketViewerScreen> {
  BracketEntity? _bracket;
  List<MatchEntity>? _matches;
  dynamic _layout;
  String? _selectedMatchId;

  final _generator = SingleEliminationBracketGeneratorServiceImplementation(const Uuid());
  final _layoutEngine = BracketLayoutEngineImplementation();
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _generateBracket();
  }

  void _generateBracket() async {
    final divisionId = _uuid.v4();
    final bracketId = _uuid.v4();

    final participantIds = widget.participants.map((p) => p.id).toList();

    final result = _generator.generate(
      divisionId: divisionId,
      participantIds: participantIds,
      bracketId: bracketId,
    );

    final layout = _layoutEngine.calculateLayout(
      bracket: result.bracket,
      matches: result.matches,
      options: const BracketLayoutOptions(),
    );

    setState(() {
      _bracket = result.bracket;
      _matches = result.matches;
      _layout = layout;
      _selectedMatchId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bracket (\${widget.participants.length} Players)'),
      ),
      body: _layout == null || _matches == null
          ? const Center(child: CircularProgressIndicator())
          : BracketViewerWidget(
              layout: _layout!,
              matches: _matches!,
              selectedMatchId: _selectedMatchId,
              onMatchTap: (matchId) {
                setState(() {
                  _selectedMatchId = matchId;
                });
              },
            ),
    );
  }
}
