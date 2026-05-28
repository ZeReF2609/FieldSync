import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../data/models/inspection.dart';

class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;

  const SyncStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      SyncStatus.pending => ('Pendiente', AppTheme.pending, Icons.cloud_upload_outlined),
      SyncStatus.synced => ('Sincronizado', AppTheme.synced, Icons.cloud_done_outlined),
      SyncStatus.failed => ('Error sync', AppTheme.failed, Icons.cloud_off_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
