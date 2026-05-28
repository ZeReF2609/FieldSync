import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/inspection.dart';
import '../cubit/inspections_cubit.dart';
import '../widgets/sync_status_badge.dart';

class InspectionDetailScreen extends StatefulWidget {
  final Inspection inspection;

  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  State<InspectionDetailScreen> createState() =>
      _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  late final TextEditingController _observationController;
  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _observationController = TextEditingController(
      text: widget.inspection.observation ?? '',
    );
    _observationController.addListener(() {
      final changed =
          _observationController.text != (widget.inspection.observation ?? '');
      if (changed != _isDirty) setState(() => _isDirty = changed);
    });
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _saveObservation() async {
    setState(() => _isSaving = true);
    try {
      await context.read<InspectionsCubit>().updateObservation(
            widget.inspection,
            _observationController.text,
          );
      if (mounted) {
        setState(() => _isDirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Observación actualizada.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insp = widget.inspection;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          insp.placeName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SyncStatusBadge(status: insp.syncStatus),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Photo hero
          _PhotoHeader(path: insp.photoPath),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Lugar',
                          value: insp.placeName,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.category_outlined,
                          label: 'Categoría',
                          value: insp.category,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Fecha',
                          value: _formatDateTime(insp.createdAt),
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.sync_outlined,
                          label: 'Estado',
                          valueWidget: SyncStatusBadge(status: insp.syncStatus),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Observation (editable)
                Text(
                  'Observación',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _observationController,
                  decoration: const InputDecoration(
                    hintText: 'Agrega notas u observaciones...',
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                if (_isDirty)
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveObservation,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar cambios'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _PhotoHeader extends StatelessWidget {
  final String path;

  const _PhotoHeader({required this.path});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        height: 240,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 48),
        ),
      );
    }
    return SizedBox(
      height: 260,
      width: double.infinity,
      child: Image.file(file, fit: BoxFit.cover),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        valueWidget ??
            Text(
              value ?? '',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
      ],
    );
  }
}
