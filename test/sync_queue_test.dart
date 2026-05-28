import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:field_sync/data/models/inspection.dart';
import 'package:field_sync/data/repositories/inspection_repository.dart';
import 'package:field_sync/data/services/sync_service.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockInspectionRepository extends Mock implements InspectionRepository {}

Inspection _makeInspection({SyncStatus status = SyncStatus.pending}) {
  return Inspection(
    id: 'test-id-1',
    placeName: 'Planta Norte',
    category: 'Infraestructura',
    photoPath: '/tmp/test.jpg',
    syncStatus: status,
    createdAt: DateTime(2024, 1, 1, 10),
    updatedAt: DateTime(2024, 1, 1, 10),
  );
}

void main() {
  late MockHttpClient mockClient;
  late MockInspectionRepository mockRepo;
  late SyncService syncService;

  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(_makeInspection());
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockRepo = MockInspectionRepository();
    syncService = SyncService(repo: mockRepo, client: mockClient);

    // Default: save always succeeds
    when(() => mockRepo.save(any())).thenAnswer((_) async {});
    when(() => mockRepo.getPending()).thenAnswer((_) async => []);
  });

  group('SyncService.syncInspection', () {
    test('returns true and marks synced when server responds 200', () async {
      final inspection = _makeInspection();

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
            encoding: any(named: 'encoding'),
          )).thenAnswer((_) async => http.Response('{"json":{}}', 200));

      final result = await syncService.syncInspection(inspection);

      expect(result, isTrue);

      final captured =
          verify(() => mockRepo.save(captureAny())).captured.last as Inspection;
      expect(captured.syncStatus, SyncStatus.synced);
    });

    test('returns false and marks failed when server responds 500', () async {
      final inspection = _makeInspection();

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
            encoding: any(named: 'encoding'),
          )).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      final result = await syncService.syncInspection(inspection);

      expect(result, isFalse);

      final captured =
          verify(() => mockRepo.save(captureAny())).captured.last as Inspection;
      expect(captured.syncStatus, SyncStatus.failed);
    });

    test('returns false and marks failed when network throws an exception',
        () async {
      final inspection = _makeInspection();

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
            encoding: any(named: 'encoding'),
          )).thenThrow(Exception('No internet'));

      final result = await syncService.syncInspection(inspection);

      expect(result, isFalse);

      final captured =
          verify(() => mockRepo.save(captureAny())).captured.last as Inspection;
      expect(captured.syncStatus, SyncStatus.failed);
    });
  });

  group('SyncService.retryPending', () {
    test('syncs all pending and failed inspections', () async {
      final pending = _makeInspection(status: SyncStatus.pending);
      final failed = _makeInspection(status: SyncStatus.failed);

      when(() => mockRepo.getPending())
          .thenAnswer((_) async => [pending, failed]);

      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
            encoding: any(named: 'encoding'),
          )).thenAnswer((_) async => http.Response('{}', 200));

      await syncService.retryPending();

      // save called twice: once for pending, once for failed
      verify(() => mockRepo.save(any())).called(2);
    });

    test('does nothing when there are no pending inspections', () async {
      when(() => mockRepo.getPending()).thenAnswer((_) async => []);

      await syncService.retryPending();

      verifyNever(() => mockClient.post(any()));
      verifyNever(() => mockRepo.save(any()));
    });
  });
}
