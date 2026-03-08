import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'features/bracket/domain/entities/bracket_entity.dart';
import 'features/bracket/domain/entities/match_entity.dart';
import 'features/bracket/domain/entities/bracket_layout.dart';
import 'features/bracket/data/services/single_elimination_bracket_generator_service_implementation.dart';
import 'features/bracket/data/services/double_elimination_bracket_generator_service_implementation.dart';
import 'features/bracket/data/services/round_robin_bracket_generator_service_implementation.dart';
import 'features/bracket/data/services/bracket_layout_engine_implementation.dart';
import 'features/bracket/presentation/widgets/bracket_viewer_widget.dart';
import 'features/participant/domain/entities/participant_entity.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const BracketGeneratorApp());
}

class BracketGeneratorApp extends StatelessWidget {
  const BracketGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TKD Bracket Generator (YOLO Edition)',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
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
  bool _dojangSeparation = true;
  bool _includeThirdPlaceMatch = false;
  String _format = 'Single Elimination';

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
      // focus node back to first name? (skipping for simplicity)
    });
  }



  void _importCsv(String csvData) {
    if (csvData.trim().isEmpty) return;
    final lines = csvData.trim().split('\n');
    setState(() {
      for (var l in lines) {
        final parts = l.split(',');
        if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
          _participants.add(
            ParticipantEntity(
              id: _uuid.v4(),
              divisionId: 'manual_division',
              firstName: parts[0].trim(),
              lastName: parts.length > 1 ? parts[1].trim() : '',
              schoolOrDojangName: parts.length > 2 && parts[2].trim().isNotEmpty ? parts[2].trim() : null,
              seedNumber: _participants.length + 1,
            ),
          );
        }
      }
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
        title: const Text('New Bracket Setup'),
        actions: [
          if (_participants.length >= 2)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bolt, color: Colors.yellow),
                label: const Text('GENERATE', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BracketViewerScreen(
                        participants: _participants,
                        dojangSeparation: _dojangSeparation,
                        format: _format,
                        includeThirdPlaceMatch: _includeThirdPlaceMatch,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButton<String>(
                            value: _format,
                            isExpanded: true,
                            items: ['Single Elimination', 'Double Elimination', 'Round Robin']
                                .map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _format = val);
                            },
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Dojang / School Separation'),
                            subtitle: const Text('Auto-distribute teammates'),
                            value: _dojangSeparation,
                            onChanged: (val) => setState(() => _dojangSeparation = val),
                          ),
                          if (_format == 'Single Elimination') SwitchListTile(
                            title: const Text('3rd Place Match'),
                            subtitle: const Text('Bronze medal match for semi losers'),
                            value: _includeThirdPlaceMatch,
                            onChanged: (val) => setState(() => _includeThirdPlaceMatch = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Quick Add Player', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(labelText: 'First Name'),
                            onSubmitted: (_) => _addParticipant(),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(labelText: 'Last Name'),
                            onSubmitted: (_) => _addParticipant(),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _dojangController,
                            decoration: const InputDecoration(labelText: 'Dojang / Club (Optional)'),
                            onSubmitted: (_) => _addParticipant(),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Participant'),
                              onPressed: _addParticipant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.paste),
                              label: const Text('Paste CSV (First,Last,Dojang)'),
                              onPressed: () async {
                                final text = await showDialog<String>(context: context, builder: (c) {
                                  final controller = TextEditingController();
                                  return AlertDialog(
                                    title: const Text("Paste CSV"),
                                    content: TextField(controller: controller, maxLines: 5),
                                    actions: [
                                      TextButton(onPressed: ()=>Navigator.pop(c, ""), child: const Text("Cancel")),
                                      ElevatedButton(onPressed: ()=>Navigator.pop(c, controller.text), child: const Text("Import")),
                                    ]
                                  );
                                });
                                if (text != null) _importCsv(text);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Participant Roster (\${_participants.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        label: const Text('Clear All', style: TextStyle(color: Colors.red)),
                        onPressed: () => setState(() => _participants.clear()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _participants.isEmpty
                        ? const Center(child: Text('Add players to start building your bracket.', style: TextStyle(color: Colors.grey)))
                        : ReorderableListView.builder(
                            itemCount: _participants.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (oldIndex < newIndex) newIndex -= 1;
                                final item = _participants.removeAt(oldIndex);
                                _participants.insert(newIndex, item);
                                // Update seed numbers
                                for (int i = 0; i < _participants.length; i++) {
                                  _participants[i] = _participants[i].copyWith(seedNumber: i + 1);
                                }
                              });
                            },
                            itemBuilder: (context, index) {
                              final p = _participants[index];
                              return Card(
                                key: ValueKey(p.id),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(backgroundColor: Colors.blueAccent, child: Text('\${index + 1}')),
                                  title: Text('\${p.firstName} \${p.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: p.schoolOrDojangName != null ? Text('Dojang: \${p.schoolOrDojangName}') : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.drag_handle, color: Colors.grey),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.redAccent),
                                        onPressed: () => _removeParticipant(index),
                                      ),
                                    ]
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BracketViewerScreen extends StatefulWidget {
  final List<ParticipantEntity> participants;
  final bool dojangSeparation;
  final String format;
  final bool includeThirdPlaceMatch;

  const BracketViewerScreen({
    super.key,
    required this.participants,
    required this.dojangSeparation,
    required this.format,
    required this.includeThirdPlaceMatch,
  });

  @override
  State<BracketViewerScreen> createState() => _BracketViewerScreenState();
}

class _BracketViewerScreenState extends State<BracketViewerScreen> {
  BracketEntity? _bracket;
  List<MatchEntity>? _matches;
  dynamic _layout;
  String? _selectedMatchId;

  final _singleGenerator = SingleEliminationBracketGeneratorServiceImplementation(const Uuid());
  final _doubleGenerator = DoubleEliminationBracketGeneratorServiceImplementation(const Uuid());
  final _roundRobinGenerator = RoundRobinBracketGeneratorServiceImplementation(const Uuid());
  final _layoutEngine = BracketLayoutEngineImplementation();
  final Uuid _uuid = const Uuid();

  final GlobalKey _printKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _generateBracket();
  }

  /// Extremely simple Dojang Separation:
  /// Group by dojang, then distribute them dynamically so they are far apart.
  List<String> _seedParticipants() {
    if (!widget.dojangSeparation) return widget.participants.map((e) => e.id).toList();

    final dojangMap = <String, List<ParticipantEntity>>{};
    final noDojang = <ParticipantEntity>[];

    for (var p in widget.participants) {
      if (p.schoolOrDojangName == null || p.schoolOrDojangName!.isEmpty) {
        noDojang.add(p);
      } else {
        dojangMap.putIfAbsent(p.schoolOrDojangName!, () => []).add(p);
      }
    }

    // Sort dojangs by size descending
    var groups = dojangMap.values.toList()..sort((a, b) => b.length.compareTo(a.length));
    
    // Flatten by popping one from each group sequentially
    List<ParticipantEntity> balanced = [];
    bool extracted = true;
    while (extracted) {
      extracted = false;
      for (var group in groups) {
        if (group.isNotEmpty) {
          balanced.add(group.removeAt(0));
          extracted = true;
        }
      }
    }
    
    balanced.addAll(noDojang);

    // To spread them, we split into top/bottom halves alternating
    List<ParticipantEntity> finalSeeded = List.filled(balanced.length, balanced.first);
    int topIndex = 0;
    int bottomIndex = balanced.length - 1;
    for (int i = 0; i < balanced.length; i++) {
        if (i % 2 == 0) {
            finalSeeded[topIndex++] = balanced[i];
        } else {
            finalSeeded[bottomIndex--] = balanced[i];
        }
    }

    return finalSeeded.map((e) => e.id).toList();
  }

  void _generateBracket() async {
    final divisionId = _uuid.v4();
    final bracketId = _uuid.v4();

    final participantIds = _seedParticipants();

    BracketEntity generatedBracket;
    List<MatchEntity> generatedMatches;

    if (widget.format.contains('Double')) {
      final res = _doubleGenerator.generate(
        divisionId: divisionId,
        participantIds: participantIds,
        winnersBracketId: bracketId,
        losersBracketId: _uuid.v4(),
        includeResetMatch: true,
      );
      generatedBracket = res.winnersBracket; // We pass the primary bracket for layout logic
      generatedMatches = res.allMatches;
    } else if (widget.format.contains('Round')) {
      final res = _roundRobinGenerator.generate(
        divisionId: divisionId,
        participantIds: participantIds,
        bracketId: bracketId,
      );
      generatedBracket = res.bracket;
      generatedMatches = res.matches;
    } else {
      final res = _singleGenerator.generate(
        divisionId: divisionId,
        participantIds: participantIds,
        bracketId: bracketId,
        // Hacky way to pass 3rd place toggle into the screen,
        // Since we are YOLO, we can just say if true statically or add it to constructor!
        // We will assume includeThirdPlaceMatch is passed or hardcode here:
        includeThirdPlaceMatch: widget.includeThirdPlaceMatch, 
      );
      generatedBracket = res.bracket;
      generatedMatches = res.matches;
    }

    final layout = _layoutEngine.calculateLayout(
      bracket: generatedBracket,
      matches: generatedMatches,
      options: const BracketLayoutOptions(),
    );

    setState(() {
      _bracket = generatedBracket;
      _matches = generatedMatches;
      _layout = layout;
      _selectedMatchId = null;
    });
  }

  ParticipantEntity? _getParticipant(String? id) {
    if (id == null) return null;
    try {
      return widget.participants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _scoreMatch(MatchEntity match) {
    if (match.status != MatchStatus.completed && match.participantRedId != null && match.participantBlueId != null) {
      showDialog(
        context: context,
        builder: (context) {
          final red = _getParticipant(match.participantRedId);
          final blue = _getParticipant(match.participantBlueId);
          MatchResultType selectedResult = MatchResultType.points;

          return StatefulBuilder(
            builder: (context, setState) {
               return AlertDialog(
                title: const Text('Score Match / Result', style: TextStyle(fontSize: 16)),
                contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<MatchResultType>(
                        value: selectedResult,
                        isExpanded: true,
                        items: MatchResultType.values.where((r) => r != MatchResultType.bye).map((r) {
                          return DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedResult = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8)),
                              onPressed: () => _declareWinner(match, match.participantRedId, selectedResult),
                              child: Text('${red?.lastName ?? "Red"}\nWINS', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('VS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8)),
                              onPressed: () => _declareWinner(match, match.participantBlueId, selectedResult),
                              child: Text('${blue?.lastName ?? "Blue"}\nWINS', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.warning, color: Colors.orange, size: 18),
                        label: const Text('No-Show', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                           Navigator.pop(context);
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select the winning player via Withdrawal for No-Show')));
                        },
                      )
                    ],
                  ),
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
              );
            }
          );
        }
      );
    } else if (match.status == MatchStatus.completed) {
      // Don't show reset for BYE matches
      if (match.resultType == MatchResultType.bye) return;
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Match Completed'),
            content: const Text('Do you want to reset this match?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () {
                    _resetMatch(match);
                    Navigator.pop(context);
                  },
                  child: const Text('Reset Score')),
            ],
          )
      );
    }
  }

  void _declareWinner(MatchEntity match, String? winnerId, MatchResultType resultType) {
    Navigator.pop(context); // Close dialog

    setState(() {
      // Update this match
      final matchIndex = _matches!.indexWhere((m) => m.id == match.id);
      if (matchIndex != -1) {
        _matches![matchIndex] = _matches![matchIndex].copyWith(
          winnerId: winnerId,
          status: MatchStatus.completed,
          resultType: resultType,
        );
      }

      // Propagate winner to next match
      if (match.winnerAdvancesToMatchId != null) {
        final nextMatchIndex = _matches!.indexWhere((m) => m.id == match.winnerAdvancesToMatchId);
        if (nextMatchIndex != -1) {
          final nextMatch = _matches![nextMatchIndex];
          // Determine correct slot: odd match numbers feed into Red, even into Blue
          // But simpler/safer: if Red is empty or already holds someone from this match, use Red; else Blue
          if (nextMatch.participantRedId == null) {
            _matches![nextMatchIndex] = nextMatch.copyWith(participantRedId: winnerId);
          } else if (nextMatch.participantBlueId == null) {
            _matches![nextMatchIndex] = nextMatch.copyWith(participantBlueId: winnerId);
          } else {
            // Both slots occupied (re-score scenario): replace the one that came from this match
            if (nextMatch.participantRedId == match.participantRedId || nextMatch.participantRedId == match.participantBlueId) {
              _matches![nextMatchIndex] = nextMatch.copyWith(participantRedId: winnerId);
            } else {
              _matches![nextMatchIndex] = nextMatch.copyWith(participantBlueId: winnerId);
            }
          }
        }
      }
      
      // Handle loser advancing (for Double Elimination / 3rd Place Match)
      if (match.loserAdvancesToMatchId != null) {
         final loserId = (winnerId == match.participantRedId) ? match.participantBlueId : match.participantRedId;
         final nextMatchIndex = _matches!.indexWhere((m) => m.id == match.loserAdvancesToMatchId);
         if (nextMatchIndex != -1) {
             final nextMatch = _matches![nextMatchIndex];
             if (nextMatch.participantRedId == null) {
                _matches![nextMatchIndex] = nextMatch.copyWith(participantRedId: loserId);
             } else if (nextMatch.participantBlueId == null) {
                _matches![nextMatchIndex] = nextMatch.copyWith(participantBlueId: loserId);
             }
         }
      }

      // Recalculate Layout
      _layout = _layoutEngine.calculateLayout(
        bracket: _bracket!,
        matches: _matches!,
        options: const BracketLayoutOptions(),
      );
    });
  }

  void _resetMatch(MatchEntity match) {
    // Don't allow resetting BYE matches
    if (match.resultType == MatchResultType.bye) return;

    setState(() {
      final matchIndex = _matches!.indexWhere((m) => m.id == match.id);
      if (matchIndex != -1) {
        _matches![matchIndex] = _matches![matchIndex].copyWith(
          winnerId: null,
          status: MatchStatus.pending,
          resultType: null,
        );
      }
      
      // Cascading undo on winner path
      _cascadeRemove(match.winnerAdvancesToMatchId, match.winnerId);

      // Cascading undo on loser path (Double Elim / 3rd place)
      if (match.loserAdvancesToMatchId != null && match.winnerId != null) {
        final loserId = (match.winnerId == match.participantRedId) ? match.participantBlueId : match.participantRedId;
        _cascadeRemove(match.loserAdvancesToMatchId, loserId);
      }

      _layout = _layoutEngine.calculateLayout(
        bracket: _bracket!,
        matches: _matches!,
        options: const BracketLayoutOptions(),
      );
    });
  }

  void _cascadeRemove(String? nextMatchId, String? idToRemove) {
    while (nextMatchId != null && idToRemove != null) {
      final nextIdx = _matches!.indexWhere((m) => m.id == nextMatchId);
      if (nextIdx == -1) break;
      
      final nextM = _matches![nextIdx];
      if (nextM.participantRedId == idToRemove) {
          _matches![nextIdx] = nextM.copyWith(participantRedId: null, winnerId: null, status: MatchStatus.pending);
      } else if (nextM.participantBlueId == idToRemove) {
          _matches![nextIdx] = nextM.copyWith(participantBlueId: null, winnerId: null, status: MatchStatus.pending);
      } else {
        break; // This player isn't here, stop cascading
      }
      idToRemove = nextM.winnerId;
      nextMatchId = nextM.winnerAdvancesToMatchId;
    }
  }

  String _pName(String? id) {
    if (id == null) return 'BYE';
    try {
      final p = widget.participants.firstWhere((p) => p.id == id);
      return '${p.firstName} ${p.lastName}'.trim();
    } catch (_) {
      return 'TBD';
    }
  }

  Future<void> _exportPdf() async {
    showDialog(context: context, builder: (ctx) => const Center(child: CircularProgressIndicator()));
    
    try {
      final doc = pw.Document();
      final isRR = widget.format.contains('Round');

      if (isRR) {
        _buildRoundRobinPdf(doc);
      } else {
        _buildBracketPdf(doc);
      }

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save());
      if (mounted) Navigator.pop(context);
    } catch(e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _buildBracketPdf(pw.Document doc) {
    if (_matches == null || _matches!.isEmpty) return;

    // Group matches by round
    final matchesByRound = <int, List<MatchEntity>>{};
    int maxRound = 0;
    for (final m in _matches!) {
      matchesByRound.putIfAbsent(m.roundNumber, () => []).add(m);
      if (m.roundNumber > maxRound) maxRound = m.roundNumber;
    }
    for (final roundMatches in matchesByRound.values) {
      roundMatches.sort((a, b) => a.matchNumberInRound.compareTo(b.matchNumberInRound));
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TKD Tie Sheet — ${widget.format}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('${widget.participants.length} Players', style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (context) {
          final rows = <pw.Widget>[];

          for (var r = 1; r <= maxRound; r++) {
            final roundMatches = matchesByRound[r] ?? [];
            final roundLabel = _getRoundLabel(r, maxRound);

            rows.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8, top: 12),
                child: pw.Text(roundLabel, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              ),
            );

            for (final match in roundMatches) {
              final redName = _pName(match.participantRedId);
              final blueName = _pName(match.participantBlueId);
              final winnerName = match.winnerId != null ? _pName(match.winnerId) : '';
              final isBye = match.resultType == MatchResultType.bye;
              final isCompleted = match.status == MatchStatus.completed;

              rows.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: isCompleted ? PdfColors.green : PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 40,
                        child: pw.Text('M${match.matchNumberInRound}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Expanded(
                        child: pw.Row(
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: match.winnerId == match.participantRedId && isCompleted ? PdfColors.amber50 : null,
                                border: pw.Border.all(color: PdfColors.red300),
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.SizedBox(
                                width: 140,
                                child: pw.Text(redName, style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: match.winnerId == match.participantRedId ? pw.FontWeight.bold : pw.FontWeight.normal,
                                )),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                              child: pw.Text(isBye ? 'BYE' : 'vs', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: match.winnerId == match.participantBlueId && isCompleted ? PdfColors.amber50 : null,
                                border: pw.Border.all(color: PdfColors.blue300),
                                borderRadius: pw.BorderRadius.circular(3),
                              ),
                              child: pw.SizedBox(
                                width: 140,
                                child: pw.Text(blueName, style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: match.winnerId == match.participantBlueId ? pw.FontWeight.bold : pw.FontWeight.normal,
                                )),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(
                        width: 100,
                        child: pw.Text(
                          isCompleted ? 'Winner: $winnerName' : (isBye ? 'BYE' : 'Pending'),
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: isCompleted ? PdfColors.green800 : PdfColors.grey),
                        ),
                      ),
                      if (isCompleted && match.resultType != null)
                        pw.SizedBox(
                          width: 60,
                          child: pw.Text('(${match.resultType!.name})', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        ),
                    ],
                  ),
                ),
              );
            }
          }

          // Participants roster at the end
          rows.add(pw.SizedBox(height: 16));
          rows.add(pw.Divider());
          rows.add(pw.Text('Participant Roster', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)));
          rows.add(pw.SizedBox(height: 8));
          rows.add(
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('#', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Name', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Dojang', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...widget.participants.asMap().entries.map((e) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${e.key + 1}', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${e.value.firstName} ${e.value.lastName}', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.value.schoolOrDojangName ?? '-', style: const pw.TextStyle(fontSize: 9))),
                  ],
                )),
              ],
            ),
          );

          return rows;
        },
      ),
    );
  }

  void _buildRoundRobinPdf(pw.Document doc) {
    if (_matches == null || _matches!.isEmpty) return;

    final matchesByRound = <int, List<MatchEntity>>{};
    int maxRound = 0;
    for (final m in _matches!) {
      matchesByRound.putIfAbsent(m.roundNumber, () => []).add(m);
      if (m.roundNumber > maxRound) maxRound = m.roundNumber;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          children: [
            pw.Text('TKD Tie Sheet — Round Robin', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (context) {
          final rows = <pw.Widget>[];
          for (var r = 1; r <= maxRound; r++) {
            final roundMatches = matchesByRound[r] ?? [];
            rows.add(pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 4, top: 12),
              child: pw.Text('Round $r', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            ));
            rows.add(
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('RED', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('', style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('BLUE', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Result', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...roundMatches.map((match) {
                    final redName = _pName(match.participantRedId);
                    final blueName = _pName(match.participantBlueId);
                    final winnerName = match.winnerId != null ? _pName(match.winnerId) : 'TBD';
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(redName, style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('vs', style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(blueName, style: const pw.TextStyle(fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(winnerName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      ],
                    );
                  }),
                ],
              ),
            );
          }
          return rows;
        },
      ),
    );
  }

  String _getRoundLabel(int roundNumber, int totalRounds) {
    final roundsFromEnd = totalRounds - roundNumber;
    return switch (roundsFromEnd) {
      0 => 'Finals',
      1 => 'Semifinals',
      2 => 'Quarterfinals',
      _ => 'Round $roundNumber',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Tournament (\${widget.participants.length} Players)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
             icon: const Icon(Icons.refresh),
             tooltip: 'Regenerate Bracket',
             onPressed: () {
               showDialog(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   title: const Text('Regenerate Bracket?'),
                   content: const Text('This will reset ALL match results and create a new bracket. Are you sure?'),
                   actions: [
                     TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                     ElevatedButton(
                       style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                       onPressed: () {
                         Navigator.pop(ctx);
                         _generateBracket();
                       },
                       child: const Text('Regenerate'),
                     ),
                   ],
                 ),
               );
             },
          )
        ],
      ),
      body: _layout == null || _matches == null
          ? const Center(child: CircularProgressIndicator())
          : widget.format.contains('Round') ? _buildRoundRobin() : InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.2,
              maxScale: 2.0, // ...
              child: RepaintBoundary(
                key: _printKey,
                child: Container(
                  color: const Color(0xFF1E1E2C), // Force background for export
                  padding: const EdgeInsets.all(32),
                  child: BracketViewerWidget(
                    layout: _layout!,
                    matches: _matches!,
                    participants: widget.participants,
                    selectedMatchId: _selectedMatchId,
                    onMatchTap: (matchId) {
                      setState(() {
                         _selectedMatchId = matchId;
                      });
                      final match = _matches!.firstWhere((m) => m.id == matchId);
                      _scoreMatch(match);
                    },
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildRoundRobin() {
    if (_matches == null || _matches!.isEmpty) return const Center(child: Text("No matches"));
    
    // Group matches by round
    final matchesByRound = <int, List<MatchEntity>>{};
    int maxRound = 0;
    for (final m in _matches!) {
       matchesByRound.putIfAbsent(m.roundNumber, () => []).add(m);
       if (m.roundNumber > maxRound) maxRound = m.roundNumber;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(maxRound, (index) {
            final roundNum = index + 1;
            final roundMatches = matchesByRound[roundNum] ?? [];
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              color: const Color(0xFF1E1E2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Round $roundNum', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const SizedBox(height: 12),
                    Table(
                      border: TableBorder.all(color: Colors.white24),
                      columnWidths: const {
                         0: FlexColumnWidth(3),
                         1: FlexColumnWidth(1),
                         2: FlexColumnWidth(3),
                         3: FlexColumnWidth(2),
                      },
                      children: [
                        const TableRow(
                           decoration: BoxDecoration(color: Colors.white12),
                           children: [
                              Padding(padding: EdgeInsets.all(8.0), child: Text('RED (Home)', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(8.0), child: Center(child: Text('VS', style: TextStyle(fontWeight: FontWeight.bold)))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('BLUE (Away)', style: TextStyle(fontWeight: FontWeight.bold))),
                              Padding(padding: EdgeInsets.all(8.0), child: Text('Winner / Score', style: TextStyle(fontWeight: FontWeight.bold))),
                           ]
                        ),
                        ...roundMatches.map((match) {
                           final red = _getParticipant(match.participantRedId);
                           final blue = _getParticipant(match.participantBlueId);
                           final winner = _getParticipant(match.winnerId);
                           
                           final redName = red != null ? '\${red.firstName} \${red.lastName}' : 'BYE';
                           final blueName = blue != null ? '\${blue.firstName} \${blue.lastName}' : 'BYE';
                           final wName = winner != null ? '\${winner.firstName} \${winner.lastName}' : (match.resultType == MatchResultType.bye ? 'BYE' : 'TBD');

                           return TableRow(
                             children: [
                               InkWell(
                                 onTap: () => _scoreMatch(match),
                                 child: Padding(padding: const EdgeInsets.all(12.0), child: Text(redName, style: const TextStyle(color: Colors.redAccent))),
                               ),
                               const Padding(padding: EdgeInsets.all(12.0), child: Center(child: Text('vs'))),
                               InkWell(
                                 onTap: () => _scoreMatch(match),
                                 child: Padding(padding: const EdgeInsets.all(12.0), child: Text(blueName, style: const TextStyle(color: Colors.blueAccent))),
                               ),
                               Padding(padding: const EdgeInsets.all(12.0), child: Text(wName, style: const TextStyle(fontWeight: FontWeight.bold))),
                             ]
                           );
                        })
                      ]
                    )
                  ]
                )
              )
            );
          })
        )
      )
    );
  }
}
