import 'dart:async';
import 'package:flutter/material.dart';

/// Debounced search bar for participant list filtering.
class ParticipantSearchBar extends StatefulWidget {
  const ParticipantSearchBar({
    required this.onSearch,
    super.key,
    this.initialQuery = '',
  });

  final ValueChanged<String> onSearch;
  final String initialQuery;

  @override
  State<ParticipantSearchBar> createState() =>
      _ParticipantSearchBarState();
}

class _ParticipantSearchBarState
    extends State<ParticipantSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialQuery,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => widget.onSearch(query),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: SearchBar(
        controller: _controller,
        hintText: 'Search participants...',
        leading: const Icon(Icons.search),
        onChanged: _onChanged,
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
        ),
        trailing: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                _onChanged('');
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}
