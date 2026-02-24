import 'package:flutter/material.dart';
import 'package:tkd_brackets/core/di/injection.dart';
import 'package:tkd_brackets/core/sync/sync_service.dart';
import 'package:tkd_brackets/core/sync/sync_status.dart';

/// Displays the current sync status with an icon and optional label.
///
/// Listens to [SyncService.statusStream] and updates automatically when
/// the sync status changes. Uses theme colors for consistent styling.
class SyncStatusIndicatorWidget extends StatelessWidget {
  /// Creates a sync status indicator widget.
  ///
  /// Set [showLabel] to true to display a text label alongside the icon.
  const SyncStatusIndicatorWidget({super.key, this.showLabel = false});

  /// Whether to show a text label next to the icon.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final syncService = getIt<SyncService>();
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<SyncStatus>(
      stream: syncService.statusStream,
      initialData: syncService.currentStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.synced;
        return Semantics(
          label: _getSemanticLabel(status),
          child: Tooltip(
            message: _getTooltipMessage(status, syncService.currentError),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(status, colorScheme),
                if (showLabel) ...[
                  const SizedBox(width: 4),
                  Text(_getLabel(status)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(SyncStatus status, ColorScheme colorScheme) {
    // Icons use null color to inherit from IconTheme (respects AppBar foreground)
    // Only error state gets explicit color for visibility
    return switch (status) {
      SyncStatus.synced => const Icon(Icons.cloud_done),
      SyncStatus.syncing => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      SyncStatus.pendingChanges => const Icon(Icons.cloud_upload),
      SyncStatus.error => Icon(Icons.cloud_off, color: colorScheme.error),
    };
  }

  String _getLabel(SyncStatus status) => switch (status) {
    SyncStatus.synced => 'Synced',
    SyncStatus.syncing => 'Syncing...',
    SyncStatus.pendingChanges => 'Pending',
    SyncStatus.error => 'Error',
  };

  String _getSemanticLabel(SyncStatus status) =>
      'Sync status: ${_getLabel(status)}';

  String _getTooltipMessage(SyncStatus status, SyncError? error) =>
      switch (status) {
        SyncStatus.synced => 'All changes synced',
        SyncStatus.syncing => 'Syncing changes...',
        SyncStatus.pendingChanges => 'Changes waiting to sync',
        SyncStatus.error => error?.message ?? 'Sync error',
      };
}
