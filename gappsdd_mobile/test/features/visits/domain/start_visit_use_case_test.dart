import 'package:flutter_test/flutter_test.dart';
import 'package:gappsdd/core/errors/app_error.dart';
import 'package:gappsdd/features/visits/data/visits_repository.dart';
import 'package:gappsdd/features/visits/domain/client_visits_data.dart';
import 'package:gappsdd/features/visits/domain/start_visit_use_case.dart';

void main() {
  late FakeVisitsRepository repository;
  late StartVisitUseCase useCase;

  setUp(() {
    repository = FakeVisitsRepository();
    useCase = StartVisitUseCase(repository);
  });

  group('StartVisitUseCase', () {
    test('checkActiveVisit returns null when no active visit', () async {
      final result = await useCase.checkActiveVisit();
      expect(result, isNull);
    });

    test('checkActiveVisit returns snapshot when active visit exists',
        () async {
      await repository.startManualVisit(
        gardenId: 'garden-villa-hortensia',
        isVerified: true,
      );

      final result = await useCase.checkActiveVisit();
      expect(result, isNotNull);
      expect(result!.garden.id, 'garden-villa-hortensia');
      expect(result.isActive, isTrue);
    });

    test('startFromQr creates a verified visit for valid garden', () async {
      final snapshot = await useCase.startFromQr('garden-can-roca');

      expect(snapshot.garden.id, 'garden-can-roca');
      expect(snapshot.isVerified, isTrue);
      expect(snapshot.initiationMethod, VisitInitiationMethod.qrScan);
      expect(snapshot.isActive, isTrue);
    });

    test('startFromQr throws GardenNotAssignedError for invalid garden', () async {
      expect(
        () => useCase.startFromQr('garden-nonexistent'),
        throwsA(isA<GardenNotAssignedError>()),
      );
    });

    test('startFromQr throws ActiveVisitExistsError when there is already an active visit', () async {
      await useCase.startFromQr('garden-villa-hortensia');

      expect(
        () => useCase.startFromQr('garden-can-roca'),
        throwsA(isA<ActiveVisitExistsError>()),
      );
    });

    test('startManual creates a visit with correct verification status',
        () async {
      final snapshot = await useCase.startManual(
        gardenId: 'garden-mas-de-mar',
        isVerified: false,
      );

      expect(snapshot.garden.id, 'garden-mas-de-mar');
      expect(snapshot.isVerified, isFalse);
      expect(snapshot.initiationMethod, VisitInitiationMethod.manual);
      expect(snapshot.isActive, isTrue);
    });

    test('loadAssignedGardens returns non-empty list', () async {
      final gardens = await useCase.loadAssignedGardens();

      expect(gardens, isNotEmpty);
      expect(gardens.first, isA<AssignedGardenVisitStatus>());
    });

    test('loadNearbyCandidates returns candidates', () async {
      final candidates = await useCase.loadNearbyCandidates();

      expect(candidates, isNotEmpty);
      expect(candidates.first, isA<ManualStartCandidate>());
      expect(candidates.first.distanceMeters, isPositive);
    });
  });
}
