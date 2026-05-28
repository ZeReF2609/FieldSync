import 'package:hive_flutter/hive_flutter.dart';
import '../models/inspection.dart';

abstract class InspectionRepository {
  Future<void> init();
  Future<List<Inspection>> getAll();
  Future<Inspection?> getById(String id);
  Future<void> save(Inspection inspection);
  Future<void> delete(String id);
  Future<List<Inspection>> getPending();
}

class HiveInspectionRepository implements InspectionRepository {
  static const String _boxName = 'inspections';
  late Box<dynamic> _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  @override
  Future<List<Inspection>> getAll() async {
    return _box.values
        .map((v) => Inspection.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Inspection?> getById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return Inspection.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<void> save(Inspection inspection) async {
    await _box.put(inspection.id, inspection.toMap());
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<List<Inspection>> getPending() async {
    final all = await getAll();
    return all
        .where((i) =>
            i.syncStatus == SyncStatus.pending ||
            i.syncStatus == SyncStatus.failed)
        .toList();
  }
}
