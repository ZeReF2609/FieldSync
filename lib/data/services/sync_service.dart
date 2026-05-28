import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/inspection.dart';
import '../repositories/inspection_repository.dart';
import '../../core/constants.dart';

class SyncService {
  final InspectionRepository _repo;
  final http.Client _client;

  SyncService({
    required InspectionRepository repo,
    http.Client? client,
  })  : _repo = repo,
        _client = client ?? http.Client();

  Future<bool> syncInspection(Inspection inspection) async {
    try {
      // Bonus: 50% random failure simulation (enable via kEnableRandomFailure)
      if (kEnableRandomFailure && Random().nextBool()) {
        throw Exception('Simulated server rejection (50% failure mode)');
      }

      final response = await _client
          .post(
            Uri.parse(kBackendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(inspection.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      final success =
          response.statusCode >= 200 && response.statusCode < 300;

      final updated = inspection.copyWith(
        syncStatus: success ? SyncStatus.synced : SyncStatus.failed,
        updatedAt: DateTime.now(),
      );
      await _repo.save(updated);
      return success;
    } catch (_) {
      final updated = inspection.copyWith(
        syncStatus: SyncStatus.failed,
        updatedAt: DateTime.now(),
      );
      await _repo.save(updated);
      return false;
    }
  }

  Future<void> retryPending() async {
    final pending = await _repo.getPending();
    for (final inspection in pending) {
      await syncInspection(inspection);
    }
  }
}
