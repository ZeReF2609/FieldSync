import '../../../data/models/inspection.dart';

abstract class InspectionsState {
  const InspectionsState();
}

class InspectionsInitial extends InspectionsState {
  const InspectionsInitial();
}

class InspectionsLoading extends InspectionsState {
  const InspectionsLoading();
}

class InspectionsLoaded extends InspectionsState {
  final List<Inspection> inspections;
  final bool isSyncing;

  const InspectionsLoaded({
    required this.inspections,
    this.isSyncing = false,
  });

  InspectionsLoaded copyWith({
    List<Inspection>? inspections,
    bool? isSyncing,
  }) {
    return InspectionsLoaded(
      inspections: inspections ?? this.inspections,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  int get pendingCount =>
      inspections.where((i) => i.syncStatus == SyncStatus.pending).length;

  int get failedCount =>
      inspections.where((i) => i.syncStatus == SyncStatus.failed).length;
}

class InspectionsError extends InspectionsState {
  final String message;
  const InspectionsError(this.message);
}
