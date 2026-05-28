import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants.dart';
import '../cubit/inspections_cubit.dart';
import 'camera_screen.dart';

class CreateInspectionScreen extends StatefulWidget {
  const CreateInspectionScreen({super.key});

  @override
  State<CreateInspectionScreen> createState() => _CreateInspectionScreenState();
}

class _CreateInspectionScreenState extends State<CreateInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placeNameController = TextEditingController();
  final _observationController = TextEditingController();

  String? _selectedCategory;
  String? _photoPath;
  bool _isSaving = false;

  @override
  void dispose() {
    _placeNameController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se necesita permiso de cámara para continuar.'),
          ),
        );
      }
      return;
    }

    final cameras = await availableCameras();
    if (!mounted) return;

    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(cameras: cameras),
        fullscreenDialog: true,
      ),
    );

    if (path != null) {
      setState(() => _photoPath = path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes tomar una foto.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<InspectionsCubit>().createInspection(
            placeName: _placeNameController.text.trim(),
            category: _selectedCategory!,
            photoPath: _photoPath!,
            observation: _observationController.text,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva inspección'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Place name
            TextFormField(
              controller: _placeNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del lugar *',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Categoría *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: kCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Selecciona una categoría' : null,
            ),
            const SizedBox(height: 24),

            // Photo section
            Text('Foto *', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (_photoPath != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_photoPath!),
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FilledButton.icon(
                      onPressed: _openCamera,
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text('Retomar'),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Colors.black.withValues(alpha: 0.6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _openCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Tomar foto'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  side: BorderSide(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Observation (optional)
            TextFormField(
              controller: _observationController,
              decoration: const InputDecoration(
                labelText: 'Observación (opcional)',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Guardando...' : 'Guardar inspección'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
