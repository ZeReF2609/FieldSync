import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/inspection.dart';
import '../../../data/repositories/inspection_repository.dart';
import '../../../data/services/connectivity_service.dart';
import '../../../data/services/sync_service.dart';
import 'inspections_state.dart';

class InspectionsCubit extends Cubit<InspectionsState> {
  final InspectionRepository _repo;
  final SyncService _syncService;
  final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _connectivitySub;

  InspectionsCubit({
    required InspectionRepository repo,
    required SyncService syncService,
    required ConnectivityService connectivityService,
  })  : _repo = repo,
        _syncService = syncService,
        _connectivityService = connectivityService,
        super(const InspectionsInitial()) {
    _connectivitySub =
        _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) _retryPending();
    });
  }

  Future<void> loadInspections() async {
    emit(const InspectionsLoading());
    try {
      final inspections = await _repo.getAll();
      emit(InspectionsLoaded(inspections: inspections));
    } catch (e) {
      emit(InspectionsError(e.toString()));
    }
  }

  Future<void> createInspection({
    required String placeName,
    required String category,
    required String photoPath,
    String? observation,
  }) async {
    final inspection = Inspection(
      id: const Uuid().v4(),
      placeName: placeName,
      category: category,
      photoPath: photoPath,
      observation: (observation?.trim().isEmpty ?? true) ? null : observation,
      syncStatus: SyncStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repo.save(inspection);

    final isConnected = await _connectivityService.isConnected();
    if (isConnected) {
      await _syncService.syncInspection(inspection);
    }

    await loadInspections();
  }

  Future<void> updateObservation(
      Inspection inspection, String observation) async {
    final updated = inspection.copyWith(
      observation: observation.trim().isEmpty ? null : observation.trim(),
      syncStatus: SyncStatus.pending,
      updatedAt: DateTime.now(),
    );
    await _repo.save(updated);

    final isConnected = await _connectivityService.isConnected();
    if (isConnected) {
      await _syncService.syncInspection(updated);
    }

    await loadInspections();
  }

  Future<void> retrySync() async {
    if (state is InspectionsLoaded) {
      emit((state as InspectionsLoaded).copyWith(isSyncing: true));
    }
    await _retryPending();
  }

  Future<void> _retryPending() async {
    await _syncService.retryPending();
    await loadInspections();
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
}
